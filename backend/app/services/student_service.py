import base64
import os
import hashlib
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.serialization import load_pem_public_key
from app.models.exam import Exam
from app.models.student_exam import StudentExam
from app.models.violation import Violation
from app.models.user import User
from app.models.qr_token import QRToken
from app.auth.jwt_handler import decode_access_token
from app.schemas.student import ExamSubmissionRequest
from fastapi.responses import FileResponse
def verify_client_signature(public_key_pem: str, signature_b64: str, data: bytes) -> bool:
    """
    Verifies an RSA signature using the student's registered public key.
    """
    try:
        # Load the student public key from database
        public_key = load_pem_public_key(public_key_pem.encode())
        signature = base64.b64decode(signature_b64)
        
        # Verify the signature against data using PKCS1v15 padding and SHA256
        public_key.verify(
            signature,
            data,
            padding.PKCS1v15(),
            hashes.SHA256()
        )
        return True
    except Exception as e:
        print(f"Cryptographic validation error: {e}")
        return False
def validate_start_qr_token(db: Session, token_str: str) -> dict:
    """
    Validates a scanned QR token JWT. Extracts exam metadata on success.
    """
    # 1. Decode token
    payload = decode_access_token(token_str)
    if not payload or payload.get("type") != "START_EXAM":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid, corrupted, or incompatible QR token."
        )
    exam_id = payload.get("sub")
    if not exam_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Exam ID missing in QR token payload."
        )
    # 2. Check if exam exists
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Associated exam not found in system record."
        )
    # 3. Check QR Token model inside DB
    qr_token = db.query(QRToken).filter(
        QRToken.token_value == token_str,
        QRToken.is_used == False
    ).first()
    
    if not qr_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="QR token has already been used or revoked."
        )
    now = datetime.now(timezone.utc)
    # Check timezone-naive/aware compatibility. DB stores timezone-naive, make now naive
    db_now = datetime.now()
    if qr_token.expires_at < db_now:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="QR token has expired. Request the invigilator to project a new one."
        )
    return {
        "is_valid": True,
        "message": "QR code validated successfully. Ready to start.",
        "exam": exam
    }
def start_exam_session(db: Session, student_id: str, exam_id: str) -> dict:
    """
    Initializes the exam session, updating student status to started.
    """
    print("========== START EXAM ==========")
    print("Student ID:", student_id)
    print("Exam ID:", exam_id)
    # 1. Verify student registration
    registration = db.query(StudentExam).filter(
        StudentExam.student_id == student_id,
        StudentExam.exam_id == exam_id
    ).first()
    print("Registration:", registration)
    if not registration:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not registered/eligible to take this examination."
        )
    # 2. Verify status
    if registration.status in ["submitted", "flagged"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already submitted answers for this examination."
        )
    # 3. Mark as started
    registration.status = "started"
    registration.started_at = datetime.now()
    db.commit()
    db.refresh(registration)
    
    return {
        "status": registration.status,
        "started_at": registration.started_at,
        "message": "Examination session started successfully."
    }
def submit_exam_session(db: Session, student_id: str, request: ExamSubmissionRequest) -> dict:
    """
    Verifies signatures and hash chains, then saves student offline responses.
    """
    # 1. Fetch student registration
    registration = db.query(StudentExam).filter(
        StudentExam.student_id == student_id,
        StudentExam.exam_id == request.exam_id
    ).first()
    if not registration:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student registration details not found for this exam."
        )
    if registration.status in ["submitted", "flagged"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Answers for this examination have already been synchronized."
        )
    # 2. Decode base64 answers payload
    try:
        answers_bytes = base64.b64decode(request.encrypted_answers_b64)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid base64 payload for encrypted answers."
        )
    # 3. Verify student public key & signature for non-repudiation
    student = db.query(User).filter(User.id == student_id).first()
    if not student or not student.public_key:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No device public key registered for this student. Contact Admin."
        )
    # Validate violation hash chain integrity
    prev_hash = "EXAM_START"
    sorted_violations = sorted(request.violations, key=lambda x: x.chain_index)
    
    for v in sorted_violations:
        details_str = v.details if v.details else ""
        # Reconstruct chain string format
        payload_str = f"{prev_hash}|{v.timestamp.isoformat()}|{v.violation_type}|{details_str}|{v.chain_index}"
        calculated_hash = hashlib.sha256(payload_str.encode()).hexdigest()
        
        if calculated_hash != v.hash_value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Tampering detected: Violation hash chain mismatch at index {v.chain_index}."
            )
        prev_hash = v.hash_value
    # Reconstruct data used for signing: EncryptedAnswers + FinalViolationHash
    data_to_verify = answers_bytes + prev_hash.encode()
    if not verify_client_signature(student.public_key, request.client_signature, data_to_verify):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Digital signature validation failed. Submission payload has been modified."
        )
    # 4. Save Submission Details
    registration.encrypted_answers = answers_bytes
    registration.client_signature = request.client_signature
    registration.submitted_at = datetime.now()
    
    # Save violations if any were synchronized
    if request.violations:
        registration.status = "flagged"
        for v in request.violations:
            db_violation = Violation(
                student_exam_id=registration.id,
                violation_type=v.violation_type,
                timestamp=v.timestamp,
                details=v.details,
                chain_index=v.chain_index,
                hash_value=v.hash_value
            )
            db.add(db_violation)
    else:
        registration.status = "submitted"
    db.commit()
    db.refresh(registration)
    
    return {
        "status": registration.status,
        "message": "Exam responses synchronized and validated successfully.",
        "submitted_at": registration.submitted_at
    }
def get_student_exams(db: Session, student_id: str):
    """
    Returns all exams assigned to the authenticated student.
    """

    registrations = (
        db.query(StudentExam)
        .filter(StudentExam.student_id == student_id)
        .all()
    )

    exams = []

    for registration in registrations:
        exam = db.query(Exam).filter(Exam.id == registration.exam_id).first()

        if exam:
           exams.append({
               "id": exam.id,
               "student_exam_id": registration.id,
               "title": exam.title,
               "subject_code": exam.subject.code,
               "duration": exam.duration_minutes,
               "status": registration.status,
               "start_time": exam.start_time,
               "end_time": exam.end_time,
})

    return exams
def download_question_paper(
    db: Session,
    student_id: str,
    exam_id: str,
):
    """
    Allows a registered student to download the question paper PDF.
    """

    # 1. Verify the student is registered for this exam
    registration = db.query(StudentExam).filter(
        StudentExam.student_id == student_id,
        StudentExam.exam_id == exam_id,
    ).first()

    if not registration:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not registered for this examination."
        )

    # 2. Fetch the exam
    exam = db.query(Exam).filter(
        Exam.id == exam_id
    ).first()

    if not exam:
        raise HTTPException(
            status_code=404,
            detail="Exam not found."
        )

    # 3. Check PDF exists
    if not exam.pdf_path:
        raise HTTPException(
            status_code=404,
            detail="Question paper has not been uploaded yet."
        )

    if not os.path.exists(exam.pdf_path):
        raise HTTPException(
            status_code=404,
            detail="Question paper file is missing."
        )

    # 4. Return PDF
    return FileResponse(
        path=exam.pdf_path,
        media_type="application/pdf",
        filename=os.path.basename(exam.pdf_path),
    )
def finish_exam(
    db: Session,
    student_id: str,
    exam_id: str,
):
    registration = db.query(StudentExam).filter(
        StudentExam.student_id == student_id,
        StudentExam.exam_id == exam_id,
    ).first()

    if not registration:
        raise HTTPException(
            status_code=404,
            detail="Exam registration not found."
        )

    registration.status = "submitted"

    db.commit()

    return {
        "message": "Exam submitted successfully."
    }
