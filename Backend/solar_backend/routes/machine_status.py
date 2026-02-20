from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
import json
import redis.asyncio as redis

from ..database import get_db
from ..models.machine_status import MachineStatus
from ..schemas.machine_status import MachineStatusCreate, MachineStatusUpdate, MachineStatusResponse
from ..config import settings

router = APIRouter(
    prefix="/machine-status",
    tags=["Machine Status"]
)

# Redis dependency
async def get_redis():
    client = redis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT, decode_responses=True)
    try:
        yield client
    finally:
        await client.close()

@router.get("/{machine_id}", response_model=MachineStatusResponse)
async def get_latest_status(
    machine_id: int, 
    db: AsyncSession = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    # 1. Fetch persistent status from DB
    result = await db.execute(
        select(MachineStatus)
        .filter(MachineStatus.MachineID == machine_id)
        .order_by(MachineStatus.Timestamp.desc())
    )
    status_entry = result.scalar_one_or_none()
    
    if not status_entry:
        # Create a default entry if none exists
        status_entry = MachineStatus(MachineID=machine_id)
        db.add(status_entry)
        await db.commit()
        await db.refresh(status_entry)

    # 2. Fetch latest telemetry from Redis
    redis_key = f"machine_state:{machine_id}"
    cached_data_raw = await redis_client.get(redis_key)
    cached_data = json.loads(cached_data_raw) if cached_data_raw else {}

    # 3. Merge: Convert DB model to Pydantic, then update with Redis data
    # (Pydantic model from_attributes=True handles the DB mapping)
    response_obj = MachineStatusResponse.model_validate(status_entry)
    
    # Update with fields from Redis if they exist and match the schema
    update_data = {}
    for field in MachineStatusResponse.model_fields:
        if field in cached_data:
            update_data[field] = cached_data[field]
        # Handle cases where Redis keys might be lowercase or diff names
        elif field.lower() in cached_data:
             update_data[field] = cached_data[field.lower()]
             
    return response_obj.model_copy(update=update_data)

@router.post("", response_model=MachineStatusResponse)
async def update_status(data: MachineStatusCreate, db: AsyncSession = Depends(get_db)):
    # Upsert logic: Update if exists for this machine, else create
    result = await db.execute(
        select(MachineStatus).filter(MachineStatus.MachineID == data.MachineID)
    )
    status_entry = result.scalar_one_or_none()
    
    if status_entry:
        for key, value in data.model_dump().items():
            setattr(status_entry, key, value)
    else:
        status_entry = MachineStatus(**data.model_dump())
        db.add(status_entry)
        
    await db.commit()
    await db.refresh(status_entry)
    return status_entry

@router.get("/all/live", response_model=List[MachineStatusResponse])
async def get_all_live_status(
    db: AsyncSession = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    # 1. Fetch all machine statuses from DB
    result = await db.execute(select(MachineStatus))
    status_entries = result.scalars().all()
    
    response_list = []
    
    # 2. For each machine, fetch/merge Redis data
    for entry in status_entries:
        redis_key = f"machine_state:{entry.MachineID}"
        cached_data_raw = await redis_client.get(redis_key)
        cached_data = json.loads(cached_data_raw) if cached_data_raw else {}
        
        response_obj = MachineStatusResponse.model_validate(entry)
        
        update_data = {}
        for field in MachineStatusResponse.model_fields:
             if field in cached_data:
                update_data[field] = cached_data[field]
             elif field.lower() in cached_data: # Fallback to lowercase keys
                update_data[field] = cached_data[field.lower()]
                
        response_list.append(response_obj.model_copy(update=update_data))
        
    return response_list
