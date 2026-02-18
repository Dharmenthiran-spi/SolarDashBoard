from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from ..database import Base

class CompanyEmployee(Base):
    __tablename__ = "CompanyEmployee"

    TableID = Column(Integer, primary_key=True, autoincrement=True)
    EmployeeID = Column(String(255), unique=True, nullable=False)
    EmployeeName = Column(Text)
    EmployeeEmail = Column(Text)
    CompanyID = Column(Integer, ForeignKey("Company.CompanyID"))
    Username = Column(String(255), unique=True, nullable=False)
    Password = Column(Text)  # Hashed
    Privilege = Column(Text)
    Status = Column(Text)

    # Relationships
    company = relationship("Company", back_populates="employees")


class CustomerUsers(Base):
    __tablename__ = "CustomerUsers"

    UserID = Column(Integer, primary_key=True, autoincrement=True)
    CustomerID = Column(Integer, ForeignKey("Customer.CustomerID"))
    CustomerName = Column(Text)
    Username = Column(String(255), unique=True, nullable=False)
    Password = Column(Text)  # Hashed
    Privilege = Column(Text)
    Status = Column(Text)

    # Relationships
    customer = relationship("Customer", back_populates="employees")
