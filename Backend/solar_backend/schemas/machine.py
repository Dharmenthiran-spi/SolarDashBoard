import base64
from pydantic import BaseModel, field_validator, ConfigDict
from typing import Optional, List

class MachineBase(BaseModel):
    MachineName: str
    SerialNo: str
    Description: Optional[str] = None
    CompanyID: Optional[int] = None
    CustomerID: Optional[int] = None
    image: Optional[str] = None

class MachineCreate(MachineBase):

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

class MachineUpdate(BaseModel):
    TableID: Optional[int] = None
    MachineName: Optional[str] = None
    SerialNo: Optional[str] = None
    Description: Optional[str] = None
    CompanyID: Optional[int] = None
    CustomerID: Optional[int] = None
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

class MachineResponse(MachineBase):
    TableID: int
    
    model_config = ConfigDict(from_attributes=True)

    @field_validator('image', mode='before')
    @classmethod
    def encode_image(cls, v):
        if not v:
            return None
        if isinstance(v, bytes):
            return base64.b64encode(v).decode('utf-8')
        return v

class MachineDelete(BaseModel):
    ids: List[int]
