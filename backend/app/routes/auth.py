from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta
from app.database import get_db
from app.models.user import User
from app.auth.security import verify_password
from app.auth.jwt_handler import create_access_token, decode_access_token
from app.auth.dependencies import get_current_user
from app.schemas.auth import LoginRequest, LoginResponse, RefreshTokenRequest, UserResponse
router = APIRouter(prefix="/auth", tags=["Authentication"])
@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    User login endpoint.
    Verifies user credentials, and issues an access token and a refresh token.
    """
    # 1. Fetch user by username
    user = db.query(User).filter(User.username == request.username).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    # 2. Verify hashed password
    if not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    # 3. Create tokens
    access_token_payload = {
        "sub": user.id,
        "role": user.role,
        "type": "access"
    }
    refresh_token_payload = {
        "sub": user.id,
        "role": user.role,
        "type": "refresh"
    }
    # Refresh tokens last longer (e.g., 7 days)
    access_token = create_access_token(data=access_token_payload)
    refresh_token = create_access_token(
        data=refresh_token_payload, 
        expires_delta=timedelta(days=7)
    )
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "role": user.role
    }
@router.post("/refresh-token", response_model=LoginResponse)
def refresh_token(request: RefreshTokenRequest, db: Session = Depends(get_db)):
    """
    Refresh access token endpoint.
    Takes a valid refresh token, validates it, and issues a fresh set of tokens.
    """
    # 1. Decode and validate incoming refresh token
    payload = decode_access_token(request.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    # 2. Extract user subject
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token payload"
        )
    # 3. Fetch user from DB
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    # 4. Generate new token pair
    access_token_payload = {
        "sub": user.id,
        "role": user.role,
        "type": "access"
    }
    refresh_token_payload = {
        "sub": user.id,
        "role": user.role,
        "type": "refresh"
    }
    access_token = create_access_token(data=access_token_payload)
    new_refresh_token = create_access_token(
        data=refresh_token_payload, 
        expires_delta=timedelta(days=7)
    )
    return {
        "access_token": access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "role": user.role
    }
@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    """
    Get profile details of the currently authenticated user.
    """
    return current_user
