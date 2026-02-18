from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from ..database import Base

class MachineStatus(Base):
    __tablename__ = "MachineStatus"

    StatusID = Column(Integer, primary_key=True, autoincrement=True)
    MachineID = Column(Integer, ForeignKey("Machine.TableID"), nullable=False)
    Status = Column(String(50), default="Online") # Online, Offline, Idle, Running
    EnergyValue = Column(Float, default=0.0)
    WaterValue = Column(Float, default=0.0)
    AreaValue = Column(Float, default=0.0)
    Timestamp = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationship
    machine = relationship("Machine", backref="live_status")
