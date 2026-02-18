from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from ..database import get_db
from ..models.machine_status import MachineStatus
from ..schemas.machine_status import MachineStatusCreate, MachineStatusUpdate, MachineStatusResponse

router = APIRouter(
    prefix="/machine-status",
    tags=["Machine Status"]
)

@router.get("/{machine_id}", response_model=MachineStatusResponse)
async def get_latest_status(machine_id: int, db: AsyncSession = Depends(get_db)):
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
    return status_entry

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
async def get_all_live_status(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(MachineStatus))
    return result.scalars().all()
