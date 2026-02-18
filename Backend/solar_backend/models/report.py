from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from ..database import Base

class Report(Base):
    __tablename__ = "Report"

    TableID = Column(Integer, primary_key=True, autoincrement=True)
    CompanyID = Column(Integer, ForeignKey("Company.CompanyID"))
    CustomerID = Column(Integer, ForeignKey("Customer.CustomerID"))
    MachineID = Column(Integer, ForeignKey("Machine.TableID"))
    StartTime = Column(DateTime)
    EndTime = Column(DateTime)
    Duration = Column(Text)
    AreaCovered = Column(Text)
    EnergyConsumption = Column(Text) # Fixed typo 'Cunsumption'
    WaterUsage = Column(Text)

    # RelationshipsCompanyID = Column(Integer, ForeignKey("Company.CompanyID"))
    #     CustomerID = Column(Integer, ForeignKey("Customer.CustomerID"))
    #     MachineID = Column(Integer, ForeignKey("Machine.TableID"))
    #     StartTime = Column(DateTime)
    #     EndTime = Column(DateTime)
    #     Duration = Column(Text)
    #     AreaCovered = Column(Text)
    #     EnergyConsumption = Column(Text) # Fixed typo 'Cunsumption'
    #     WaterUsage = Column(Text)
    company = relationship("Company", back_populates="reports")
    customer = relationship("Customer", back_populates="reports")
    machine = relationship("Machine", back_populates="reports")
