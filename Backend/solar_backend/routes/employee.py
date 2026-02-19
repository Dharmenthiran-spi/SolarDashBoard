from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
from ..database import get_db
from ..models.employee import CompanyEmployee, CustomerUsers
from ..models.company import Company
from ..models.customer import Customer
from ..security import hash_password, verify_password, get_current_user
from ..schemas.employee import (
    CompanyEmployeeCreate, CompanyEmployeeUpdate, CompanyEmployeeResponse,
    CustomerUsersCreate, CustomerUsersUpdate, CustomerUsersResponse,
    EmployeeDelete
)

router = APIRouter(
    prefix="/employees",
    tags=["Employees"],
    dependencies=[Depends(get_current_user)]
)

# Company Employee Routes
@router.post("/company", response_model=CompanyEmployeeResponse, status_code=status.HTTP_201_CREATED)
async def create_company_employee(employee: CompanyEmployeeCreate, db: AsyncSession = Depends(get_db)):
    try:
        hashed_password = hash_password(employee.Password)
        new_employee = CompanyEmployee(
            **employee.model_dump(exclude={"Password"}), 
            Password=hashed_password
        )
        db.add(new_employee)
        await db.commit()
        await db.refresh(new_employee)
        return new_employee
    except Exception as e:
        await db.rollback()
        error_msg = str(e)
        if "Duplicate entry" in error_msg:
            if "EmployeeID" in error_msg:
                detail = "Employee ID already exists."
            elif "Username" in error_msg:
                detail = "Username already exists."
            else:
                detail = "Duplicate entry error."
            raise HTTPException(status_code=400, detail=detail)
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {error_msg}")

@router.get("/company", response_model=List[CompanyEmployeeResponse])
async def get_company_employees(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CompanyEmployee))
    return result.scalars().all()

# Bulk Update Company Employees
@router.put("/company/update_list", response_model=dict)
async def bulk_update_company_employees(data: List[CompanyEmployeeUpdate], db: AsyncSession = Depends(get_db)):
    updated_count: int = 0
    for item in data:
        result = await db.execute(select(CompanyEmployee).filter(CompanyEmployee.TableID == item.TableID))
        employee = result.scalar_one_or_none()
        if not employee:
            continue
        
        # Handle password hashing if provided
        update_data = item.model_dump(exclude_unset=True)
        if "Password" in update_data and update_data["Password"]:
            # Check if password is unchanged (matches existing hash) - prevents re-hashing
            if update_data["Password"] != employee.Password:
                update_data["Password"] = hash_password(update_data["Password"])
            else:
                # Remove from update if it matches existing (no change needed)
                del update_data["Password"]
            
        for key, value in update_data.items():
            if key != "TableID":
                setattr(employee, key, value)
        updated_count += 1
        
    await db.commit()
    return {"updated_count": updated_count}

# Bulk Delete Company Employees
@router.delete("/company/delete_list", response_model=dict)
async def bulk_delete_company_employees(payload: EmployeeDelete, db: AsyncSession = Depends(get_db)):
    if not payload.ids:
        raise HTTPException(status_code=400, detail="No IDs provided")
        
    result = await db.execute(select(CompanyEmployee).filter(CompanyEmployee.TableID.in_(payload.ids)))
    employees = result.scalars().all()
    
    for emp in employees:
        await db.delete(emp)
        
    await db.commit()
    return {"deleted_count": len(employees)}


# Customer Users Routes
@router.post("/customer", response_model=CustomerUsersResponse, status_code=status.HTTP_201_CREATED)
async def create_customer_user(user: CustomerUsersCreate, db: AsyncSession = Depends(get_db)):
    try:
        hashed_password = hash_password(user.Password)
        new_user = CustomerUsers(
            **user.model_dump(exclude={"Password"}), 
            Password=hashed_password
        )
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        return new_user
    except Exception as e:
        await db.rollback()
        error_msg = str(e)
        if "Duplicate entry" in error_msg:
            if "Username" in error_msg:
                detail = "Username already exists."
            else:
                detail = "Duplicate entry error."
            raise HTTPException(status_code=400, detail=detail)
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {error_msg}")

@router.get("/customer", response_model=List[CustomerUsersResponse])
async def get_customer_users(
    customer_id: int = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(CustomerUsers, Customer.CustomerName, Company.CompanyName)\
        .join(Customer, CustomerUsers.CustomerID == Customer.CustomerID)\
        .outerjoin(Company, Customer.CompanyID == Company.CompanyID)

    if customer_id:
        query = query.filter(CustomerUsers.CustomerID == customer_id)
        
    result = await db.execute(query)
    rows = result.all()
    
    response = []
    for user, cust_name, comp_name in rows:
        user_dict = {
            "UserID": user.UserID,
            "CustomerID": user.CustomerID,
            "CustomerName": user.CustomerName,
            "Username": user.Username,
            "Password": user.Password,
            "Privilege": user.Privilege,
            "Status": user.Status,
            "OrganizationName": cust_name,
            "CompanyName": comp_name
        }
        response.append(user_dict)
        
    return response

# Bulk Update Customer Users
@router.put("/customer/update_list", response_model=dict)
async def bulk_update_customer_users(data: List[CustomerUsersUpdate], db: AsyncSession = Depends(get_db)):
    updated_count: int = 0
    for item in data:
        result = await db.execute(select(CustomerUsers).filter(CustomerUsers.UserID == item.UserID))
        user = result.scalar_one_or_none()
        if not user:
            continue
            
        update_data = item.model_dump(exclude_unset=True)
        # Handle password hashing if provided
        if "Password" in update_data and update_data["Password"]:
             # Check if password is unchanged (matches existing hash) - prevents re-hashing
            if update_data["Password"] != user.Password:
                update_data["Password"] = hash_password(update_data["Password"])
            else:
                # Remove from update if it matches existing
                del update_data["Password"]

        for key, value in update_data.items():
            if key != "UserID":
                setattr(user, key, value)
        updated_count += 1
        
    await db.commit()
    return {"updated_count": updated_count}

# Bulk Delete Customer Users
@router.delete("/customer/delete_list", response_model=dict)
async def bulk_delete_customer_users(payload: EmployeeDelete, db: AsyncSession = Depends(get_db)):
    if not payload.ids:
        raise HTTPException(status_code=400, detail="No IDs provided")
        
    result = await db.execute(select(CustomerUsers).filter(CustomerUsers.UserID.in_(payload.ids)))
    users = result.scalars().all()
    
    for user in users:
        await db.delete(user)
        
    await db.commit()
    return {"deleted_count": len(users)}
