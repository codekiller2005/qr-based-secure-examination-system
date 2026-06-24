import uuid
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.qr_token import QRToken
from app.models.exam import Exam
def generate_secure_qr_token(db: Session, exam_id: str, expires_in_minutes: int) -> QRToken:
    """
    Generates a secure UUID-based QR token linked to a specific exam.
    
    Args:
        db: Database session.
        exam_id: Target exam ID.
        expires_in_minutes: Longevity of the token.
    Returns:
        The generated QRToken model instance.
    """
    # 1. Verify target exam exists
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Target exam for QR code not found."
        )
    # 2. Compile token details
    token_value = str(uuid.uuid4())
    expiry = datetime.now() + timedelta(minutes=expires_in_minutes)
    db_token = QRToken(
        exam_id=exam_id,
        token_type="START_EXAM",
        token_value=token_value,
        is_used=False,
        expires_at=expiry
    )
    
    db.add(db_token)
    db.commit()
    db.refresh(db_token)
    return db_token
def validate_qr_token(db: Session, token_value: str) -> QRToken:
    print("TOKEN RECEIVED =", repr(token_value))
    """
    Validates a QR token. Checks existence, status, and expiration.
    
    Args:
        db: Database session.
        token_value: Scanned UUID token.
    Returns:
        The validated QRToken database instance.
    """
    # 1. Fetch token details
    token = db.query(QRToken).filter(QRToken.token_value == token_value).first()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="QR token not found or invalid."
        )
    # 2. Check if token is already used
    if token.is_used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="QR token has already been scanned and used."
        )
    # 3. Check expiration
    # SQLite/MySQL timezone-naive datetime comparison
    db_now = datetime.now()
    if token.expires_at < db_now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="QR token has expired. Invigilator must generate a new one."
        )
    return token
def use_qr_token(db: Session, token_value: str) -> dict:
    """
    Invalidates a QR token by marking it as used. Prevents double-scan cheats.
    
    Args:
        db: Database session.   
        token_value: Scanned UUID token to invalidate.
    Returns:
        Confirmation dictionary.
    """
    token = validate_qr_token(db, token_value)
    
    token.is_used = True
    db.commit()
    db.refresh(token)
    
    return {
        "status": "success",
        "message": "QR token successfully consumed.",
        "token_value": token.token_value,
        "is_used": token.is_used
    }
