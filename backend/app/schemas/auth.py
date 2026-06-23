from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from datetime import datetime
class LoginRequest(BaseModel):
    """
    Schema for validating login requests.
    Allows students, invigilators, and admins to authenticate.
    """
    username: str = Field(..., min_length=3, max_length=50, description="The unique username of the user")
    password: str = Field(..., min_length=6, description="The user's secret password")
class LoginResponse(BaseModel):
    """
    Schema representing successful authentication.
    Returns access tokens, token type, and user role.
    """
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: str
class RefreshTokenRequest(BaseModel):
    """
    Schema for validating token refresh requests.
    """
    refresh_token: str = Field(..., description="The valid JWT refresh token")
class TokenPayload(BaseModel):
    """
    Schema for validating JWT token payload content.
    """
    sub: Optional[str] = None # Standard JWT subject (maps to user_id)
    role: Optional[str] = None # Custom claim representing user role
    type: Optional[str] = None # Token type: 'access' or 'refresh'
    exp: Optional[int] = None # Expiration epoch timestamp
class UserResponse(BaseModel):
    """
    Schema for returning authenticated user details.
    """
    id: str
    username: str
    email: str
    role: str
    public_key: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    model_config = {
        "from_attributes": True
    }
