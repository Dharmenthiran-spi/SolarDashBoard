from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from ..database import get_db
from ..models.report import Report
from ..models.machine import Machine
from ..models.customer import Customer
from ..schemas.report import ReportCreate, ReportUpdate, ReportResponse, ReportDelete

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)

@router.post("", response_model=ReportResponse, status_code=status.HTTP_201_CREATED)
async def create_report(report: ReportCreate, db: AsyncSession = Depends(get_db)):
    new_report = Report(**report.model_dump())
    db.add(new_report)
    await db.commit()
    await db.refresh(new_report)
    return new_report

@router.get("", response_model=List[ReportResponse])
async def get_reports(
    machine_id: Optional[int] = None,
    customer_id: Optional[int] = None,
    from_time: Optional[datetime] = None,
    to_time: Optional[datetime] = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(
        Report,
        Machine.MachineName,
        Customer.CustomerName
    ).outerjoin(Machine, Report.MachineID == Machine.TableID)\
     .outerjoin(Customer, Report.CustomerID == Customer.CustomerID)

    if machine_id:
        query = query.filter(Report.MachineID == machine_id)
    if customer_id:
        query = query.filter(Report.CustomerID == customer_id)
    if from_time:
        query = query.filter(Report.EndTime >= from_time)
    if to_time:
        query = query.filter(Report.EndTime <= to_time)
        
    result = await db.execute(query)
    rows = result.all()
    
    reports_with_names = []
    for report_obj, m_name, c_name in rows:
        # Create a dict from the report object's attributes
        report_dict = {
            "TableID": report_obj.TableID,
            "CompanyID": report_obj.CompanyID,
            "CustomerID": report_obj.CustomerID,
            "MachineID": report_obj.MachineID,
            "StartTime": report_obj.StartTime,
            "EndTime": report_obj.EndTime,
            "Duration": report_obj.Duration,
            "AreaCovered": report_obj.AreaCovered,
            "EnergyConsumption": report_obj.EnergyConsumption,
            "WaterUsage": report_obj.WaterUsage,
            "MachineName": m_name,
            "CustomerName": c_name
        }
        reports_with_names.append(report_dict)
        
    return reports_with_names

# Bulk Update
@router.put("/update_list", response_model=dict)
async def bulk_update_reports(data: List[ReportUpdate], db: AsyncSession = Depends(get_db)):
    updated_count: int = 0
    for item in data:
        result = await db.execute(select(Report).filter(Report.TableID == item.TableID))
        report = result.scalar_one_or_none()
        if not report:
            continue
        
        for key, value in item.model_dump(exclude_unset=True).items():
            if key != "TableID":
                setattr(report, key, value)
        updated_count += 1
        
    await db.commit()
    return {"updated_count": updated_count}

@router.put("/{report_id}", response_model=ReportResponse)
async def update_report(report_id: int, report_update: ReportUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Report).filter(Report.TableID == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    for key, value in report_update.model_dump(exclude_unset=True).items():
        setattr(report, key, value)
    
    await db.commit()
    await db.refresh(report)
    return report

# Bulk Delete
@router.delete("/delete_list", response_model=dict)
async def bulk_delete_reports(payload: ReportDelete, db: AsyncSession = Depends(get_db)):
    if not payload.ids:
        raise HTTPException(status_code=400, detail="No IDs provided")
        
    result = await db.execute(select(Report).filter(Report.TableID.in_(payload.ids)))
    reports = result.scalars().all()
    
    for report in reports:
        await db.delete(report)
        
    await db.commit()
    return {"deleted_count": len(reports)}

@router.delete("/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(report_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Report).filter(Report.TableID == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    await db.delete(report)
    await db.commit()
