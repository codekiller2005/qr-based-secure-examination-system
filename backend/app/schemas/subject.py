from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
class SubjectCreate(BaseModel):
    """
    Schema for validating subject creation requests.
    """
    code: str = Field(..., min_length=2, max_length=20, description="Unique subject code, e.g. CS-101")
    name: str = Field(..., min_length=3, max_length=100, description="Subject name, e.g. Introduction to Programming")
    description: Optional[str] = Field(None, description="Optional description of the course subject")
class SubjectUpdate(BaseModel):
    """
    Schema for validating subject update requests.
    """
    name: Optional[str] = Field(None, min_length=3, max_length=100)
    description: Optional[str] = Field(None)
class SubjectResponse(BaseModel):
    """
    Schema for returning subject details.
    """
    id: str
    code: str
    name: str
    description: Optional[str]
    created_at: datetime
    updated_at: datetime
    model_config = {
        "from_attributes": True
    }
