from sqlalchemy.orm import Session
from datetime import datetime, timezone
from fastapi import HTTPException, status
from app.models.exam import Exam
from app.models.subject import Subject
from app.models.qr_token import QRToken
from app.models.invigilator_credential import InvigilatorCredential
from app.auth.security import verify_password
def get_assigned_exams(db: Session):
    """
    Retrieves all ongoing or scheduled exams that the invigilator can monitor.
    """
    return db.query(Exam).filter(Exam.status.in_(["scheduled", "ongoing"])).all()
def get_subject_details(db: Session, subject_id: str) -> Subject:
    """
    Fetches course metadata details for a specific subject.
    """
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subject details not found."
        )
    return subject
def get_active_exam_qr_token(db: Session, exam_id: str) -> QRToken:
    """
    Retrieves the latest active, non-expired QR token for starting an exam.
    """
    now = datetime.now(timezone.utc)
    token = db.query(QRToken).filter(
        QRToken.exam_id == exam_id,
        QRToken.is_used == False,
        QRToken.expires_at > now
    ).order_by(QRToken.created_at.desc()).first()
    
    if not token:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active start QR token found for this exam. Contact Admin to generate one."
        )
    return token
def validate_one_time_passcode(db: Session, invigilator_id: str, passcode: str) -> dict:
    """
    Validates a plain text passcode against the invigilator's active hashed credentials.
    """
    now = datetime.now(timezone.utc)
    
    # Query all active credentials assigned to this invigilator
    credentials = db.query(InvigilatorCredential).filter(
        InvigilatorCredential.user_id == invigilator_id,
        InvigilatorCredential.is_active == True,
        (InvigilatorCredential.expires_at == None) | (InvigilatorCredential.expires_at > now)
    ).all()
    for cred in credentials:
        # Check if hash matches plain text passcode
        if verify_password(passcode, cred.credential_value):
            return {
                "is_valid": True,
                "message": "Passcode validated successfully.",
                "expires_at": cred.expires_at
            }
            
    return {
        "is_valid": False,
        "message": "Invalid, expired, or deactivated passcode.",
        "expires_at": None
    }
