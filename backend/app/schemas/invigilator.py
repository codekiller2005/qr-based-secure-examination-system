from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
class InvigilatorLoginRequest(BaseModel):
    """
    Schema for validating invigilator login credentials.
    """
    username: str = Field(..., description="Username of the invigilator")
    password: str = Field(..., description="Password of the invigilator")
class CredentialValidationRequest(BaseModel):
    """
    Schema for validating a one-time passcode credential.
    """
    passcode: str = Field(..., min_length=4, max_length=20, description="The plain passcode to validate")
class CredentialValidationResponse(BaseModel):
    """
    Response schema for credential verification queries.
    """
    is_valid: bool
    message: str
    expires_at: Optional[datetime] = None
