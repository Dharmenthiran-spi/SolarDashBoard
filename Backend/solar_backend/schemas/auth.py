from pydantic import BaseModel
from typing import Optional

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    user_type: str  # "CompanyEmployee" or "CustomerUser"
    privilege: str  # "Admin" or "User"
    user_id: int
    username: str
    customer_id: Optional[int] = None
    company_id: Optional[int] = None
    customer_name: Optional[str] = None
    employee_name: Optional[str] = None
    access_token: Optional[str] = None
    token_type: Optional[str] = "bearer"
