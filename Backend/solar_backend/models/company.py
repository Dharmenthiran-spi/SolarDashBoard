from sqlalchemy import Column, Integer, String, Text, LargeBinary
from sqlalchemy.dialects.mysql import LONGBLOB
from sqlalchemy.orm import relationship
from ..database import Base

class Company(Base):
    __tablename__ = "Company"

    CompanyID = Column(Integer, primary_key=True, autoincrement=True)
    CompanyName = Column(Text, nullable=False)
    Address = Column(Text)
    Location = Column(Text)
    image = Column(LONGBLOB)

    # Relationships
    employees = relationship("CompanyEmployee", back_populates="company")
    customers = relationship("Customer", back_populates="company")
    machines = relationship("Machine", back_populates="company")
    reports = relationship("Report", back_populates="company")
