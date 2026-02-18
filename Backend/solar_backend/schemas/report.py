from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class ReportBase(BaseModel):
    CompanyID: Optional[int] = None
    CustomerID: Optional[int] = None
    MachineID: Optional[int] = None
    StartTime: Optional[datetime] = None
    EndTime: Optional[datetime] = None
    Duration: Optional[str] = None
    AreaCovered: Optional[str] = None
    EnergyConsumption: Optional[str] = None
    WaterUsage: Optional[str] = None

class ReportCreate(ReportBase):
    pass

class ReportUpdate(BaseModel):
    TableID: Optional[int] = None
    CompanyID: Optional[int] = None
    CustomerID: Optional[int] = None
    MachineID: Optional[int] = None
    StartTime: Optional[datetime] = None
    EndTime: Optional[datetime] = None
    Duration: Optional[str] = None
    AreaCovered: Optional[str] = None
    EnergyConsumption: Optional[str] = None
    WaterUsage: Optional[str] = None

class ReportResponse(ReportBase):
    TableID: int
    MachineName: Optional[str] = None
    CustomerName: Optional[str] = None
    
    class Config:
        from_attributes = True

class ReportDelete(BaseModel):
    ids: List[int]
