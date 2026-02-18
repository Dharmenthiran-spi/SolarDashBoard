import base64
from pydantic import BaseModel, field_validator, ConfigDict
from typing import Optional, List

class CustomerBase(BaseModel):
    CustomerName: str
    CustomerAddress: Optional[str] = None
    Location: Optional[str] = None
    CompanyID: Optional[int] = None
    image: Optional[str] = None

class CustomerCreate(CustomerBase):

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
        return v

class CustomerUpdate(BaseModel):
    CustomerID: Optional[int] = None
    CustomerName: Optional[str] = None
    CustomerAddress: Optional[str] = None
    Location: Optional[str] = None
    CompanyID: Optional[int] = None
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

class CustomerResponse(CustomerBase):
    CustomerID: int
    
    model_config = ConfigDict(from_attributes=True)

    @field_validator('image', mode='before')
    @classmethod
    def encode_image(cls, v):
        if not v:
            return None
        if isinstance(v, bytes):
            return base64.b64encode(v).decode('utf-8')
        return v

class CustomerDelete(BaseModel):
    ids: List[int]
