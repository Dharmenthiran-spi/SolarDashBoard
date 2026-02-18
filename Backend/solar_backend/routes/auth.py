from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from ..database import get_db
from ..models.employee import CompanyEmployee, CustomerUsers
from ..models.customer import Customer
from ..security import verify_password, create_access_token
from ..schemas.auth import LoginRequest, LoginResponse

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

@router.post("/login", response_model=LoginResponse)
async def login(credentials: LoginRequest, db: AsyncSession = Depends(get_db)):

    username = credentials.username
    password = credentials.password

    # 🔹 DEFAULT SYSTEM ADMIN LOGIN (Fallback)
    if username == "spi" and password == "12345":
        # Check if any Admin exists in CompanyEmployee
        admin_check = await db.execute(
            select(CompanyEmployee).filter(CompanyEmployee.Privilege == "Admin")
        )
        admin_exists = admin_check.scalars().first()

        if admin_exists:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Admin already exists. Please login with your credentials."
            )

        # Return Super User session
        return LoginResponse(
            user_type="CompanyEmployee",
            privilege="Admin",
            user_id=0,
            username="spi",
            company_id=0,
            employee_name="System Administrator"
        )
    
    # Try to find user in CompanyEmployee table
    result = await db.execute(
        select(CompanyEmployee).filter(CompanyEmployee.Username == username)
    )
    company_employee = result.scalar_one_or_none()
    
    if company_employee:
        # Verify password
        if not verify_password(password, company_employee.Password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password"
            )
        
        if company_employee.Status != "Active":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User Account is Inactive. Please contact system administrator."
            )
        
        # 🔹 GENERATE JWT TOKEN
        token_data = {
            "sub": company_employee.Username,
            "user_type": "CompanyEmployee",
            "user_id": company_employee.TableID,
            "privilege": company_employee.Privilege
        }
        access_token = create_access_token(data=token_data)
        
        return LoginResponse(
            user_type="CompanyEmployee",
            privilege=company_employee.Privilege,
            user_id=company_employee.TableID,
            username=company_employee.Username,
            company_id=company_employee.CompanyID,
            employee_name=company_employee.EmployeeName,
            access_token=access_token,
            token_type="bearer"
        )
    
    # Try to find user in CustomerUsers table
    result = await db.execute(
        select(CustomerUsers).filter(CustomerUsers.Username == username)
    )
    customer_user = result.scalar_one_or_none()
    
    if customer_user:
        # Verify password
        if not verify_password(password, customer_user.Password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid username or password"
            )
        
        if customer_user.Status != "Active":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User Account is Inactive. Please contact system administrator."
            )
        
        # 🔹 GENERATE JWT TOKEN
        token_data = {
            "sub": customer_user.Username,
            "user_type": "CustomerUser",
            "user_id": customer_user.UserID,
            "privilege": customer_user.Privilege
        }
        access_token = create_access_token(data=token_data)
        
        # Fetch customer name
        customer_result = await db.execute(
            select(Customer).filter(Customer.CustomerID == customer_user.CustomerID)
        )
        customer = customer_result.scalar_one_or_none()
        
        return LoginResponse(
            user_type="CustomerUser",
            privilege=customer_user.Privilege,
            user_id=customer_user.UserID,
            username=customer_user.Username,
            customer_id=customer_user.CustomerID,
            customer_name=customer.CustomerName if customer else None,
            access_token=access_token,
            token_type="bearer"
        )
    
    # 🔹 LOGIC FOR FALLBACK ADMIN (spi)
    if username == "spi" and password == "12345":
         # Registering spi for token generation too if needed, but it's handled above
         pass

    # User not found in either table
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid username or password"
    )
