from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, desc
from datetime import datetime, timedelta
from typing import List

from ..database import get_db
from ..models.company import Company
from ..models.customer import Customer
from ..models.machine import Machine
from ..models.report import Report
from ..schemas.dashboard import DashboardSummary, DailyGraphicData

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"]
)

@router.get("/summary", response_model=DashboardSummary)
async def get_dashboard_summary(customer_id: int = None, db: AsyncSession = Depends(get_db)):
    # Base queries
    companies_query = select(func.count(Company.CompanyID))
    customers_query = select(func.count(Customer.CustomerID))
    machines_query = select(func.count(Machine.TableID))
    reports_query = select(func.count(Report.TableID))

    # Apply filters if customer_id provided
    if customer_id:
        # For a specific customer, company count is 1 (their company) or 0
        # But simpler to just query assuming valid customer
        companies_query = select(func.count(Company.CompanyID)).join(Customer).filter(Customer.CustomerID == customer_id)
        customers_query = customers_query.filter(Customer.CustomerID == customer_id)
        machines_query = machines_query.filter(Machine.CustomerID == customer_id)
        reports_query = reports_query.filter(Report.CustomerID == customer_id)

    # Execute Counts
    companies_count = await db.execute(companies_query)
    customers_count = await db.execute(customers_query)
    machines_count = await db.execute(machines_query)
    reports_count = await db.execute(reports_query)

    # Recent Reports
    recent_query = select(Report).order_by(desc(Report.StartTime)).limit(5)
    if customer_id:
        recent_query = recent_query.filter(Report.CustomerID == customer_id)
    
    recent_reports_result = await db.execute(recent_query)
    recent_reports = []
    for r in recent_reports_result.scalars().all():
        recent_reports.append({
            "id": r.TableID,
            "machine_id": r.MachineID,
            "start_time": r.StartTime.isoformat() if r.StartTime else None,
            "energy": r.EnergyConsumption
        })

    # Aggregates
    # Optimally should use SQL aggregation, but sticking to existing logic with filter
    all_reports_query = select(Report)
    if customer_id:
        all_reports_query = all_reports_query.filter(Report.CustomerID == customer_id)
        
    all_reports_result = await db.execute(all_reports_query)
    all_reports = all_reports_result.scalars().all()
    
    total_energy = 0.0
    total_water = 0.0
    
    for r in all_reports:
        try:
            total_energy += float(r.EnergyConsumption.split()[0]) if r.EnergyConsumption else 0.0
        except: pass
        try:
            total_water += float(r.WaterUsage.split()[0]) if r.WaterUsage else 0.0
        except: pass

    # Daily Data (Last 7 days)
    daily_energy = []
    daily_water = []
    today = datetime.now().date()
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        day_str = day.strftime("%Y-%m-%d")
        
        # Calculate for this day
        d_energy = 0.0
        d_water = 0.0
        for r in all_reports:
            if r.StartTime and r.StartTime.date() == day:
                try:
                    d_energy += float(r.EnergyConsumption.split()[0]) if r.EnergyConsumption else 0.0
                except: pass
                try:
                    d_water += float(r.WaterUsage.split()[0]) if r.WaterUsage else 0.0
                except: pass
        
        daily_energy.append(DailyGraphicData(date=day_str, value=round(d_energy, 2)))
        daily_water.append(DailyGraphicData(date=day_str, value=round(d_water, 2)))

    return {
        "total_companies": companies_count.scalar() or 0,
        "total_customers": customers_count.scalar() or 0,
        "total_machines": machines_count.scalar() or 0,
        "total_reports": reports_count.scalar() or 0,
        "total_energy_generated": round(total_energy, 2),
        "total_water_usage": round(total_water, 2),
        "recent_reports": recent_reports,
        "daily_energy": daily_energy,
        "daily_water": daily_water
    }
