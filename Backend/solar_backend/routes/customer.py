from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from ..database import get_db
from ..models.customer import Customer
from ..schemas.customer import CustomerCreate, CustomerUpdate, CustomerResponse, CustomerDelete
from ..security import get_current_user

router = APIRouter(
    prefix="/customers",
    tags=["Customers"],
    dependencies=[Depends(get_current_user)]
)

@router.post("", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(customer: CustomerCreate, db: AsyncSession = Depends(get_db)):
    new_customer = Customer(**customer.model_dump())
    db.add(new_customer)
    await db.commit()
    await db.refresh(new_customer)
    return new_customer

@router.get("", response_model=List[CustomerResponse])
async def get_customers(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Customer))
    return result.scalars().all()

# Bulk Update
@router.put("/update_list", response_model=dict)
async def bulk_update_customers(data: List[CustomerUpdate], db: AsyncSession = Depends(get_db)):
    updated_count: int = 0
    for item in data:
        result = await db.execute(select(Customer).filter(Customer.CustomerID == item.CustomerID))
        customer = result.scalar_one_or_none()
        if not customer:
            continue
        
        for key, value in item.model_dump(exclude_unset=True).items():
            if key != "CustomerID":
                setattr(customer, key, value)
        updated_count += 1
        
    await db.commit()
    return {"updated_count": updated_count}

@router.put("/{customer_id}", response_model=CustomerResponse)
async def update_customer(customer_id: int, customer_update: CustomerUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Customer).filter(Customer.CustomerID == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    for key, value in customer_update.model_dump(exclude_unset=True).items():
        setattr(customer, key, value)
    
    await db.commit()
    await db.refresh(customer)
    return customer

# Bulk Delete
@router.delete("/delete_list", response_model=dict)
async def bulk_delete_customers(payload: CustomerDelete, db: AsyncSession = Depends(get_db)):
    if not payload.ids:
        raise HTTPException(status_code=400, detail="No IDs provided")
        
    result = await db.execute(select(Customer).filter(Customer.CustomerID.in_(payload.ids)))
    customers = result.scalars().all()
    
    for customer in customers:
        await db.delete(customer)
        
    await db.commit()
    return {"deleted_count": len(customers)}

@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(customer_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Customer).filter(Customer.CustomerID == customer_id))
    customer = result.scalar_one_or_none()
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    await db.delete(customer)
    await db.commit()
