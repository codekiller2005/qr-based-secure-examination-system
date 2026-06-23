from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.jwt_handler import decode_access_token
from app.models.user import User
from typing import List
# Setup oauth2 scheme pointing to our eventual login route
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")
async def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency to retrieve and validate the currently authenticated user from a JWT.
    
    Args:
        token: Extracted Bearer token.
        db: Database session.
    Returns:
        The SQLAlchemy User model instance.
    Raises:
        HTTPException: 401 Unauthorized if verification fails.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    # Decode token payload
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
        
    user_id: str = payload.get("sub")
    user_role: str = payload.get("role")
    
    if user_id is None or user_role is None:
        raise credentials_exception
        
    # Query database to check if user exists
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
        
    # Optional double check: verify database role matches token role
    if user.role != user_role:
        raise credentials_exception
        
    return user
class RoleChecker:
    """
    Callable dependency to enforce role-based access control (RBAC).
    
    Usage:
        @app.get("/admin", dependencies=[Depends(RoleChecker(["admin"]))])
    """
    def __init__(self, allowed_roles: List[str]):
        self.allowed_roles = allowed_roles
    def __call__(self, current_user: User = Depends(get_current_user)) -> User:
        """
        Intercepts the request and checks the active user's role.
        """
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Insufficient role permissions."
            )
        return current_user
