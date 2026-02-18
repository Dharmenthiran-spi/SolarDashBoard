from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from ..database import get_db
from ..models.company import Company
from ..schemas.company import CompanyCreate, CompanyUpdate, CompanyResponse, DeleteCompanies
from ..security import get_current_user

router = APIRouter(
    prefix="/companies",
    tags=["Companies"],
    dependencies=[Depends(get_current_user)]
)

@router.post("", response_model=CompanyResponse, status_code=status.HTTP_201_CREATED)
async def create_company(company: CompanyCreate, db: AsyncSession = Depends(get_db)):
    new_company = Company(**company.model_dump())
    db.add(new_company)
    await db.commit()
    await db.refresh(new_company)
    return new_company

@router.get("", response_model=List[CompanyResponse])
async def get_companies(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Company))
    return result.scalars().all()

# Bulk Update
@router.put("/update_list", response_model=dict)
async def bulk_update_companies(data: List[CompanyUpdate], db: AsyncSession = Depends(get_db)):
    updated_count: int = 0
    for item in data:
        result = await db.execute(select(Company).filter(Company.CompanyID == item.CompanyID))
        company = result.scalar_one_or_none()
        if not company:
            continue
        
        for key, value in item.model_dump(exclude_unset=True).items():
             if key != "CompanyID":
                setattr(company, key, value)
        updated_count += 1
    
    await db.commit()
    return {"updated_count": updated_count}

@router.put("/{company_id}", response_model=CompanyResponse)
async def update_company(company_id: int, company_update: CompanyUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Company).filter(Company.CompanyID == company_id))
    company = result.scalar_one_or_none()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    
    for key, value in company_update.model_dump(exclude_unset=True).items():
        setattr(company, key, value)
    
    await db.commit()
    await db.refresh(company)
    return company

# Bulk Delete
@router.delete("/delete_list", response_model=dict)
async def bulk_delete_companies(payload: DeleteCompanies, db: AsyncSession = Depends(get_db)):
    if not payload.ids:
        raise HTTPException(status_code=400, detail="No IDs provided")
    
    result = await db.execute(select(Company).filter(Company.CompanyID.in_(payload.ids)))
    companies = result.scalars().all()
    
    for company in companies:
        await db.delete(company)
        
    await db.commit()
    return {"deleted_count": len(companies)}

@router.delete("/{company_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_company(company_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Company).filter(Company.CompanyID == company_id))
    company = result.scalar_one_or_none()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    
    await db.delete(company)
    await db.commit()
