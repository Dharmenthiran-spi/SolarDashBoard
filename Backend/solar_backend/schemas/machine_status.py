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
    
    # Extended Telemetry Fields (from Redis)
    Mode: Optional[str] = "Auto"
    Timer: Optional[int] = 0
    BatteryLevel: Optional[float] = 0.0
    BatteryVoltage: Optional[float] = 0.0
    IsCharging: Optional[bool] = False
    WaterLevel: Optional[float] = 0.0
    PumpStatus: Optional[bool] = False
    BrushRPM: Optional[int] = 0
    BrushTemp: Optional[float] = 0.0
    IsBrushJam: Optional[bool] = False
    Speed: Optional[float] = 0.0
    Direction: Optional[float] = 0.0
    EmergencyStop: Optional[bool] = False
    ObstacleDetected: Optional[bool] = False
    AreaToday: Optional[float] = 0.0
    CleaningTime: Optional[int] = 0
    TotalCycles: Optional[int] = 0
    
    model_config = ConfigDict(from_attributes=True)
