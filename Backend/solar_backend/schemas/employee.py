from pydantic import BaseModel, EmailStr
from typing import Optional, List

# Company Employee
class CompanyEmployeeBase(BaseModel):
    EmployeeID: str
    EmployeeName: Optional[str] = None
    EmployeeEmail: Optional[EmailStr] = None
    CompanyID: Optional[int] = None
    Username: str
    Privilege: Optional[str] = None
    Status: Optional[str] = None

class CompanyEmployeeCreate(CompanyEmployeeBase):
    Password: str

class CompanyEmployeeUpdate(BaseModel):
    TableID: int
    EmployeeName: Optional[str] = None
    EmployeeEmail: Optional[EmailStr] = None
    Privilege: Optional[str] = None
    Status: Optional[str] = None
    Password: Optional[str] = None
    Username: Optional[str] = None
    CompanyID: Optional[int] = None

class CompanyEmployeeResponse(CompanyEmployeeBase):
    TableID: int
    Password: Optional[str] = None
    
    class Config:
        from_attributes = True

class EmployeeDelete(BaseModel):
    ids: List[int]

# Customer Users
class CustomerUsersBase(BaseModel):
    CustomerID: Optional[int] = None
    CustomerName: Optional[str] = None
    Username: str
    Privilege: Optional[str] = None
    Status: Optional[str] = None

class CustomerUsersCreate(CustomerUsersBase):
    Password: str

class CustomerUsersUpdate(BaseModel):
    UserID: int
    CustomerName: Optional[str] = None
    Privilege: Optional[str] = None
    Status: Optional[str] = None
    Password: Optional[str] = None
    Username: Optional[str] = None
    CustomerID: Optional[int] = None

class CustomerUsersResponse(CustomerUsersBase):
    UserID: int
    CompanyName: Optional[str] = None
    OrganizationName: Optional[str] = None
    Password: Optional[str] = None
    
    class Config:
        from_attributes = True
