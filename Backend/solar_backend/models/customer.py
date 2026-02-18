from sqlalchemy import Column, Integer, String, Text, ForeignKey, LargeBinary
from sqlalchemy.dialects.mysql import LONGBLOB
from sqlalchemy.orm import relationship
from ..database import Base

class Customer(Base):
    __tablename__ = "Customer"

    CustomerID = Column(Integer, primary_key=True, autoincrement=True)
    CustomerName = Column(Text, nullable=False)
    CustomerAddress = Column(Text)
    Location = Column(Text)
    CompanyID = Column(Integer, ForeignKey("Company.CompanyID"))
    image = Column(LONGBLOB)

    # Relationships
    company = relationship("Company", back_populates="customers")
    employees = relationship("CustomerUsers", back_populates="customer")
    machines = relationship("Machine", back_populates="customer")
    reports = relationship("Report", back_populates="customer")
