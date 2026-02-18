from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class DailyGraphicData(BaseModel):
    date: str
    value: float

class DashboardSummary(BaseModel):
    total_companies: int
    total_customers: int
    total_machines: int
    total_reports: int
    total_energy_generated: float
    total_water_usage: float
    recent_reports: List[dict] # Simplified for now
    daily_energy: List[DailyGraphicData]
    daily_water: List[DailyGraphicData]
