import base64
from pydantic import BaseModel, field_validator, ConfigDict
from typing import Optional, List

class CompanyBase(BaseModel):
    CompanyName: str
    Address: Optional[str] = None
    Location: Optional[str] = None
    image: Optional[str] = None

class CompanyCreate(CompanyBase):

    @field_validator('image')
    @classmethod
    def validate_image(cls, v):
        if not v:
            return None
        if isinstance(v, str):
            try:
                # Handle data:image/png;base64,... prefixes
                if ',' in v:
                    v = v.split(',')[-1]
                return base64.b64decode(v)
            except Exception:
                # If it's not valid base64 and not empty, return None to avoid garbage in DB
                return None
        return v

class CompanyUpdate(BaseModel):
    CompanyID: Optional[int] = None
    CompanyName: Optional[str] = None
    Address: Optional[str] = None
    Location: Optional[str] = None
    image: Optional[str] = None

    @field_validator('image')
    @classmethod
    def validate_image(cls, v):
        if not v:
            return None
        if isinstance(v, str):
            try:
                if ',' in v:
                    v = v.split(',')[-1]
                return base64.b64decode(v)
            except Exception:
                return None
        return v

class CompanyResponse(CompanyBase):
    CompanyID: int
    
    model_config = ConfigDict(from_attributes=True)

    @field_validator('image', mode='before')
    @classmethod
    def encode_image(cls, v):
        if not v:
            return None
        if isinstance(v, bytes):
            return base64.b64encode(v).decode('utf-8')
        return v

class DeleteCompanies(BaseModel):
    ids: List[int]
