from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from ..database import Base

class Telemetry(Base):
    __tablename__ = "Telemetry"

    TelemetryID = Column(Integer, primary_key=True, autoincrement=True)
    MachineID = Column(Integer, ForeignKey("Machine.TableID"), nullable=False)
    BatteryLevel = Column(Float, nullable=True)
    SolarVoltage = Column(Float, nullable=True)
    SolarCurrent = Column(Float, nullable=True)
    WaterLevel = Column(Float, nullable=True)
    AdditionalData = Column(JSON, nullable=True)
    Timestamp = Column(DateTime, default=datetime.utcnow)

    # Relationship
    machine = relationship("Machine", backref="telemetry_records")
