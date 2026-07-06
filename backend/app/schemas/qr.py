from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
class QRTokenGenerateRequest(BaseModel):
    """
    Request payload schema for generating a new UUID-based QR token.
    """
    exam_id: str = Field(..., description="ID of the exam associated with this QR token")
    expires_in_minutes: Optional[int] = Field(15, gt=0, description="Lifespan of the QR token in minutes")
class QRTokenValidateRequest(BaseModel):
    """
    Request payload schema for validating a scanned QR token.
    """
    token_value: str = Field(..., description="The UUID token string scanned from the QR code")
class QRExamResponse(BaseModel):
    """
    Exam details returned after successful QR validation.
    """
    id: str
    title: str
    subject_code: str
    duration: int
    start_time: datetime
    status: str
class QRTokenDetailResponse(BaseModel):
    """
    Response schema returning comprehensive QR token metadata details.
    """

    id: str
    exam_id: str
    token_type: str
    token_value: str
    is_used: bool
    created_at: datetime
    expires_at: datetime

    exam: Optional[QRExamResponse] = None

    model_config = {
        "from_attributes": True
    }