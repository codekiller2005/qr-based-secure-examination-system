from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
class ExamCreate(BaseModel):
    """
    Schema for validating exam creation requests.
    Accepts raw passcode and base64-encoded encrypted questions questions.
    """
    subject_id: str = Field(..., description="ID of the associated subject")
    title: str = Field(..., min_length=3, max_length=150)
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    duration_minutes: int = Field(..., gt=0, description="Exam duration in minutes")
    pdf_path: Optional[str] = None
    encrypted_questions_b64: str = Field(..., description="Base64 encoded ciphertext of exam questions")
    passcode: str = Field(..., min_length=6, description="Cleartext passcode for invigilator unlocking")
class ExamUpdate(BaseModel):
    """
    Schema for validating exam update requests.
    """
    title: Optional[str] = Field(None, min_length=3, max_length=150)
    description: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, gt=0)
    pdf_path: Optional[str] = None
    encrypted_questions_b64: Optional[str] = None
    passcode: Optional[str] = Field(None, min_length=6)
    status: Optional[str] = None # 'draft', 'scheduled', 'ongoing', 'completed'
class ExamResponse(BaseModel):
    """
    Schema for returning exam metadata details.
    Excludes sensitive questions payload and passcode hash.
    """
    id: str
    subject_id: str
    invigilator_id: Optional[str] = None
    title: str
    description: Optional[str]
    pdf_path: Optional[str]
    start_time: datetime
    end_time: datetime
    duration_minutes: int
    status: str
    created_at: datetime
    updated_at: datetime
    model_config = {
        "from_attributes": True
    }
class InvigilatorCredentialCreate(BaseModel):
    """
    Request schema to generate a one-time credential for an invigilator.
    """
    user_id: str = Field(..., description="User ID of the invigilator")
    expires_in_hours: Optional[int] = Field(24, gt=0, description="Expiration buffer time in hours")
class InvigilatorCredentialResponse(BaseModel):
    """
    Response schema returning generated credential.
    Provides plain_passcode ONLY once on generation.
    """
    id: str
    user_id: str
    credential_type: str
    plain_passcode: str # The generated plain passcode to show to the admin
    is_active: bool
    created_at: datetime
    expires_at: Optional[datetime]
    model_config = {
        "from_attributes": True
    }
class QRTokenCreate(BaseModel):
    """
    Request schema to generate a QR Token for an exam.
    """
    expires_in_minutes: Optional[int] = Field(15, gt=0, description="Expiration time of QR code in minutes")
class QRTokenResponse(BaseModel):
    """
    Response schema for generated QR Token verification blocks.
    """
    id: str
    exam_id: str
    token_type: str
    token_value: str
    is_used: bool
    created_at: datetime
    expires_at: datetime
    model_config = {
        "from_attributes": True
    }

class AssignInvigilatorRequest(BaseModel):
    exam_id: str
    invigilator_id: str
