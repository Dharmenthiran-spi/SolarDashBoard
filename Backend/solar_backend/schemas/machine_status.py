from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class MachineStatusBase(BaseModel):
    MachineID: int
    Status: str
    EnergyValue: float
    WaterValue: float
    AreaValue: float

class MachineStatusCreate(MachineStatusBase):
    pass

class MachineStatusUpdate(BaseModel):
    Status: Optional[str] = None
    EnergyValue: Optional[float] = None
    WaterValue: Optional[float] = None
    AreaValue: Optional[float] = None

class MachineStatusResponse(MachineStatusBase):
    StatusID: int
    Timestamp: datetime
    
    model_config = ConfigDict(from_attributes=True)
