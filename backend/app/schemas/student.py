from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from app.schemas.exam import ExamResponse
class StudentLoginRequest(BaseModel):
    """
    Validation schema for student logins.
    """
    username: str = Field(..., description="Student username")
    password: str = Field(..., description="Student password")
class QRValidationRequest(BaseModel):
    """
    Validation schema for student QR-code scans.
    """
    token: str = Field(..., description="The JWT token string decoded from the start QR code")
class QRValidationResponse(BaseModel):
    """
    Response schema returning exam validation metrics.
    """
    is_valid: bool
    message: str
    exam: Optional[ExamResponse] = None
class ExamStartResponse(BaseModel):
    """
    Response details for a successfully initialized exam.
    """
    status: str
    started_at: datetime
    message: str
class ViolationSync(BaseModel):
    """
    Schema for synchronizing violation logs during post-exam sync.
    """
    violation_type: str = Field(..., description="Type of violation (e.g. SCREENSHOT)")
    timestamp: datetime
    details: Optional[str] = None
    chain_index: int = Field(..., description="Sequential log index")
    hash_value: str = Field(..., description="Cumulative SHA-256 hash value")
class ExamSubmissionRequest(BaseModel):
    """
    Schema for direct student submission of offline exam answers.
    """
    exam_id: str = Field(..., description="ID of the exam being submitted")
    encrypted_answers_b64: str = Field(..., description="Base64-encoded answers encrypted with server public key")
    client_signature: str = Field(..., description="Digital signature of (answers_hash + final_violation_hash) signed by device private key")
    violations: List[ViolationSync] = Field(default=[], description="List of recorded environmental violations")
class ExamSubmissionResponse(BaseModel):
    """
    Response status return indicating submission verification.
    """
    status: str # 'submitted', 'flagged', or 'tampered'
    message: str
    submitted_at: datetime
