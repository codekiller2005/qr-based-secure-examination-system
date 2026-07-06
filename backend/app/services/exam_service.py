import base64
import secrets
import string
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status
from app.models.exam import Exam
from app.models.subject import Subject
from app.models.user import User
from app.models.invigilator_credential import InvigilatorCredential
from app.models.qr_token import QRToken
from app.schemas.exam import ExamCreate, ExamUpdate, InvigilatorCredentialCreate, QRTokenCreate
from app.auth.security import hash_password
from app.auth.jwt_handler import create_access_token

from app.models.student_exam import StudentExam
def generate_random_passcode(length: int = 8) -> str:
    """
    Generates a highly readable alphanumeric code (e.g. "A8X2B9W3") for invigilators.
    """
    alphabet = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))
def create_exam(db: Session, exam_in: ExamCreate) -> Exam:
    """
    Creates a new Exam. Verifies the linked Subject.
    """
    # 1. Verify subject exists
    subject = db.query(Subject).filter(Subject.id == exam_in.subject_id).first()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Linked subject not found."
        )
    # 2. Decode base64 questions payload to bytes
    try:
        decoded_questions = base64.b64decode(exam_in.encrypted_questions_b64)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid base64 format for encrypted questions."
        )
    # 3. Hash passcode
    hashed_pass = hash_password(exam_in.passcode)
    db_exam = Exam(
        subject_id=exam_in.subject_id,
        title=exam_in.title,
        description=exam_in.description,
        start_time=exam_in.start_time,
        end_time=exam_in.end_time,
        duration_minutes=exam_in.duration_minutes,
        pdf_path=exam_in.pdf_path,
        encrypted_questions=decoded_questions,
        passcode_hash=hashed_pass,
        status="scheduled"
    )
    db.add(db_exam)
    db.commit()
    db.refresh(db_exam)
    
    students = db.query(User).filter(User.role == "student").all()
    for student in students:
        registration = StudentExam(
        student_id=student.id,
        exam_id=db_exam.id,
        status="registered"
    )
        db.add(registration)
    db.commit()
    return db_exam
def get_exams(db: Session, skip: int = 0, limit: int = 100):
    """
    Retrieves all Exams with pagination.
    """
    return db.query(Exam).offset(skip).limit(limit).all()
def get_exam_by_id(db: Session, exam_id: str) -> Exam:
    """
    Retrieves an Exam by ID. Raises 404 if not found.
    """
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam not found."
        )
    return exam
def update_exam(db: Session, exam_id: str, exam_in: ExamUpdate) -> Exam:
    """
    Updates an Exam. Decodes base64 questions or hashes passcode if updated.
    """
    db_exam = get_exam_by_id(db, exam_id)
    # Update simple fields
    if exam_in.title is not None:
        db_exam.title = exam_in.title
    if exam_in.description is not None:
        db_exam.description = exam_in.description
    if exam_in.start_time is not None:
        db_exam.start_time = exam_in.start_time
    if exam_in.end_time is not None:
        db_exam.end_time = exam_in.end_time
    if exam_in.duration_minutes is not None:
        db_exam.duration_minutes = exam_in.duration_minutes
    if exam_in.pdf_path is not None:
        db_exam.pdf_path = exam_in.pdf_path
    if exam_in.status is not None:
        db_exam.status = exam_in.status
    # Decode updated questions if provided
    if exam_in.encrypted_questions_b64 is not None:
        try:
            db_exam.encrypted_questions = base64.b64decode(exam_in.encrypted_questions_b64)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid base64 format for encrypted questions."
            )
    # Hash new passcode if provided
    if exam_in.passcode is not None:
        db_exam.passcode_hash = hash_password(exam_in.passcode)
    db.commit()
    db.refresh(db_exam)
    return db_exam
def delete_exam(db: Session, exam_id: str) -> None:
    """
    Deletes an Exam.
    """
    db_exam = get_exam_by_id(db, exam_id)
    db.delete(db_exam)
    db.commit()
def generate_invigilator_credentials(db: Session, credential_in: InvigilatorCredentialCreate) -> dict:
    """
    Generates a one-time passcode verification block for an invigilator.
    """
    # 1. Verify user exists and is an invigilator
    user = db.query(User).filter(User.id == credential_in.user_id).first()
    if not user or user.role != "invigilator":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Target user is not registered as an invigilator."
        )
    # 2. Generate random readable passcode
    plain_passcode = generate_random_passcode(8)
    hashed_passcode = hash_password(plain_passcode)
    # 3. Save to database
    expiry = datetime.now(timezone.utc) + timedelta(hours=credential_in.expires_in_hours)
    
    db_cred = InvigilatorCredential(
        user_id=credential_in.user_id,
        credential_type="passcode",
        credential_value=hashed_passcode,
        is_active=True,
        expires_at=expiry
    )
    db.add(db_cred)
    db.commit()
    db.refresh(db_cred)
    # Return dict including plain passcode (returned ONLY once)
    return {
        "id": db_cred.id,
        "user_id": db_cred.user_id,
        "credential_type": db_cred.credential_type,
        "plain_passcode": plain_passcode,
        "is_active": db_cred.is_active,
        "created_at": db_cred.created_at,
        "expires_at": db_cred.expires_at
    }
def generate_exam_qr_token(db: Session, exam_id: str, qr_in: QRTokenCreate) -> QRToken:
    """
    Generates an encrypted JWT QR token authorizing the start of an exam.
    """
    # 1. Verify exam exists
    exam = get_exam_by_id(db, exam_id)
    # 2. Set expiry
    expiry_delta = timedelta(minutes=qr_in.expires_in_minutes)
    expiry_time = datetime.now(timezone.utc) + expiry_delta
    # 3. Create signed token payload
    token_payload = {
        "sub": exam.id,
        "type": "START_EXAM",
        "title": exam.title,
        "duration": exam.duration_minutes
    }
    jwt_token = create_access_token(data=token_payload, expires_delta=expiry_delta)
    # 4. Save token meta to DB
    db_token = QRToken(
        exam_id=exam.id,
        token_type="START_EXAM",
        token_value=jwt_token,
        is_used=False,
        expires_at=expiry_time
    )
    db.add(db_token)
    db.commit()
    db.refresh(db_token)
    return db_token
def generate_exam_passcode(db: Session, exam_id: str):
    """
    Generates a new passcode for an exam.
    """

    exam = get_exam_by_id(db, exam_id)

    plain_passcode = generate_random_passcode(8)

    exam.passcode_hash = hash_password(plain_passcode)

    db.commit()
    db.refresh(exam)

    return {
        "exam_id": exam.id,
        "passcode": plain_passcode
    }
from app.models.violation import Violation

def get_dashboard_stats(db: Session):
    """
    Returns statistics for the Admin Dashboard.
    """

    total_exams = db.query(Exam).count()

    total_students = (
        db.query(User)
        .filter(User.role == "student")
        .count()
    )

    active_proctors = (
        db.query(Exam)
        .filter(Exam.invigilator_id.isnot(None))
        .count()
    )

    total_violations = db.query(Violation).count()

    return {
        "total_exams": total_exams,
        "total_students": total_students,
        "active_proctors": active_proctors,
        "total_violations": total_violations,
    }