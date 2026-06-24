from fastapi import APIRouter, Depends, status, Response,UploadFile,File
import os
import uuid
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.auth.dependencies import RoleChecker
from app.schemas.subject import SubjectCreate, SubjectUpdate, SubjectResponse
from app.schemas.exam import (
    ExamCreate, ExamUpdate, ExamResponse,
    InvigilatorCredentialCreate, InvigilatorCredentialResponse,
    QRTokenCreate, QRTokenResponse
)
from app.services import subject_service, exam_service
# Define Admin restricted router. All routes check for admin role.
router = APIRouter(
    prefix="/admin",
    tags=["Admin Management"],
    dependencies=[Depends(RoleChecker(["admin"]))]
)
# ------------------------------------------------------------------------------
# Subject Endpoints
# ------------------------------------------------------------------------------
@router.post("/subjects", response_model=SubjectResponse, status_code=status.HTTP_201_CREATED)
def create_subject(subject: SubjectCreate, db: Session = Depends(get_db)):
    """
    Create an academic subject course code.
    """
    return subject_service.create_subject(db, subject)
@router.get("/subjects", response_model=List[SubjectResponse])
def get_subjects(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    List all academic subject courses.
    """
    return subject_service.get_subjects(db, skip=skip, limit=limit)
@router.get("/subjects/{subject_id}", response_model=SubjectResponse)
def get_subject_by_id(subject_id: str, db: Session = Depends(get_db)):
    """
    Get course details of a specific subject by ID.
    """
    return subject_service.get_subject_by_id(db, subject_id)
@router.put("/subjects/{subject_id}", response_model=SubjectResponse)
def update_subject(subject_id: str, subject: SubjectUpdate, db: Session = Depends(get_db)):
    """
    Update a subject's metadata details.
    """
    return subject_service.update_subject(db, subject_id, subject)
@router.delete("/subjects/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subject(subject_id: str, db: Session = Depends(get_db)):
    """
    Delete a subject. Blocks if the subject has active scheduled exams.
    """
    subject_service.delete_subject(db, subject_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
# ------------------------------------------------------------------------------
# Exam Endpoints
# ------------------------------------------------------------------------------
@router.post("/exams", response_model=ExamResponse, status_code=status.HTTP_201_CREATED)
def create_exam(exam: ExamCreate, db: Session = Depends(get_db)):
    """
    Create a scheduled examination. Accepts Base64 questions and passcode.
    """
    return exam_service.create_exam(db, exam)
@router.get("/exams", response_model=List[ExamResponse])
def get_exams(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    List all scheduled examinations.
    """
    return exam_service.get_exams(db, skip=skip, limit=limit)
@router.get("/exams/{exam_id}", response_model=ExamResponse)
def get_exam_by_id(exam_id: str, db: Session = Depends(get_db)):
    """
    Get exam details by ID.
    """
    return exam_service.get_exam_by_id(db, exam_id)
@router.put("/exams/{exam_id}", response_model=ExamResponse)
def update_exam(exam_id: str, exam: ExamUpdate, db: Session = Depends(get_db)):
    """
    Update details, passcode, or questions payload of an exam.
    """
    return exam_service.update_exam(db, exam_id, exam)
@router.delete("/exams/{exam_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_exam(exam_id: str, db: Session = Depends(get_db)):
    """
    Delete an exam.
    """
    exam_service.delete_exam(db, exam_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
# ------------------------------------------------------------------------------
# Security Credentials & Token Generators
# ------------------------------------------------------------------------------
@router.post("/invigilators/credentials", response_model=InvigilatorCredentialResponse)
def generate_invigilator_credentials(credential: InvigilatorCredentialCreate, db: Session = Depends(get_db)):
    """
    Generate a one-time readable passcode authorization block for an invigilator user.
    """
    return exam_service.generate_invigilator_credentials(db, credential)
@router.post("/exams/{exam_id}/qr-token", response_model=QRTokenResponse)
def generate_exam_qr_token(exam_id: str, qr_in: QRTokenCreate, db: Session = Depends(get_db)):
    """
    Generate an encrypted dynamic QR code JWT token representing verification parameters to launch an exam.
    """
    return exam_service.generate_exam_qr_token(db, exam_id, qr_in)
@router.post("/upload-pdf")
async def upload_pdf(file: UploadFile = File(...)):
    upload_dir = "uploads/pdfs"
    os.makedirs(upload_dir, exist_ok=True)

    filename = f"{uuid.uuid4()}_{file.filename}"
    file_path = os.path.join(upload_dir, filename)

    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    return {
        "pdf_path": file_path
    }
