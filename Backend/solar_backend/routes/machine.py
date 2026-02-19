from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from ..database import get_db
from ..models.machine import Machine
from ..schemas.machine import MachineCreate, MachineUpdate, MachineResponse, MachineDelete
from ..security import get_current_user

router = APIRouter(
    prefix="/machines",
    tags=["Machines"],
    dependencies=[Depends(get_current_user)]
)

@router.post("", response_model=MachineResponse, status_code=status.HTTP_201_CREATED)
async def create_machine(machine: MachineCreate, db: AsyncSession = Depends(get_db)):
    try:
        # Check if SerialNo already exists
        stmt = select(Machine).filter(Machine.SerialNo == machine.SerialNo)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Machine with serial number '{machine.SerialNo}' already exists."
            )
            
        machine_data = machine.model_dump()
        if not machine_data.get("MqttUsername"):
            machine_data["MqttUsername"] = f"user_{machine.SerialNo}"
        if not machine_data.get("MqttPassword"):
            # Simple random password for demo, should be more secure in production
            import secrets
            machine_data["MqttPassword"] = secrets.token_urlsafe(12)
            
        new_machine = Machine(**machine_data)
        db.add(new_machine)
        await db.commit()
        await db.refresh(new_machine)
        return new_machine
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error creating machine: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal Server Error: {str(e)}"
        )

@router.get("", response_model=List[MachineResponse])
async def get_machines(customer_id: int = None, db: AsyncSession = Depends(get_db)):
    query = select(Machine)
    if customer_id:
        query = query.filter(Machine.CustomerID == customer_id)
    result = await db.execute(query)
    return result.scalars().all()

# Bulk Update
@router.put("/update_list", response_model=dict)
async def bulk_update_machines(data: List[MachineUpdate], db: AsyncSession = Depends(get_db)):
    updated_count: int = 0
    for item in data:
        result = await db.execute(select(Machine).filter(Machine.TableID == item.TableID))
        machine = result.scalar_one_or_none()
        if not machine:
            continue
        
        for key, value in item.model_dump(exclude_unset=True).items():
            if key != "TableID":
                setattr(machine, key, value)
        updated_count += 1
        
    await db.commit()
    return {"updated_count": updated_count}

@router.put("/{machine_id}", response_model=MachineResponse)
async def update_machine(machine_id: int, machine_update: MachineUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Machine).filter(Machine.TableID == machine_id))
    machine = result.scalar_one_or_none()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")
    
    # Check if SerialNo already exists for another machine
    if machine_update.SerialNo and machine_update.SerialNo != machine.SerialNo:
        stmt = select(Machine).filter(Machine.SerialNo == machine_update.SerialNo)
        existing_result = await db.execute(stmt)
        if existing_result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Machine with serial number '{machine_update.SerialNo}' already exists."
            )

    for key, value in machine_update.model_dump(exclude_unset=True).items():
        setattr(machine, key, value)
    
    await db.commit()
    await db.refresh(machine)
    return machine

# Bulk Delete
@router.delete("/delete_list", response_model=dict)
async def bulk_delete_machines(payload: MachineDelete, db: AsyncSession = Depends(get_db)):
    if not payload.ids:
        raise HTTPException(status_code=400, detail="No IDs provided")
        
    result = await db.execute(select(Machine).filter(Machine.TableID.in_(payload.ids)))
    machines = result.scalars().all()
    
    for machine in machines:
        await db.delete(machine)
        
    await db.commit()
    return {"deleted_count": len(machines)}

@router.delete("/{machine_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_machine(machine_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Machine).filter(Machine.TableID == machine_id))
    machine = result.scalar_one_or_none()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")
    
    await db.delete(machine)
    await db.commit()

@router.post("/{machine_id}/command", response_model=dict)
async def send_command(machine_id: int, command: dict, db: AsyncSession = Depends(get_db)):
    # Find machine
    result = await db.execute(select(Machine).filter(Machine.TableID == machine_id))
    machine = result.scalar_one_or_none()
    if not machine:
        raise HTTPException(status_code=404, detail="Machine not found")
    
    # Get MQTT handler from app state
    from ..main import app as fastapi_app
    mqtt_handler = fastapi_app.state.mqtt_handler
    
    if not mqtt_handler:
        raise HTTPException(status_code=500, detail="MQTT handler not initialized")
    
    await mqtt_handler.publish_command(
        company_id=machine.CompanyID,
        machine_serial=machine.SerialNo,
        command=command
    )
    
    return {"status": "Command sent", "topic": f"company/{machine.CompanyID}/machine/{machine.SerialNo}/command"}
