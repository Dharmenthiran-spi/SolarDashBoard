from sqlalchemy import Column, Integer, String, Text, ForeignKey, LargeBinary
from sqlalchemy.dialects.mysql import LONGBLOB
from sqlalchemy.orm import relationship
from ..database import Base

class Machine(Base):
    __tablename__ = "Machine"

    TableID = Column(Integer, primary_key=True, autoincrement=True)
    MachineName = Column(Text, nullable=False)
    SerialNo = Column(String(255), unique=True, nullable=False)
    Description = Column(Text)
    CompanyID = Column(Integer, ForeignKey("Company.CompanyID"))
    CustomerID = Column(Integer, ForeignKey("Customer.CustomerID"))
    image = Column(LONGBLOB)

    # Relationships
    company = relationship("Company", back_populates="machines")
    customer = relationship("Customer", back_populates="machines")
    reports = relationship("Report", back_populates="machine")
