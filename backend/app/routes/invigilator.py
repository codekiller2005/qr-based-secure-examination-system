from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import timedelta
from app.database import get_db
from app.models.user import User
from app.auth.security import verify_password
from app.auth.jwt_handler import create_access_token
from app.auth.dependencies import RoleChecker, get_current_user
from app.schemas.auth import LoginResponse
from app.schemas.subject import SubjectResponse
from app.schemas.exam import ExamResponse, QRTokenResponse
from app.schemas.invigilator import InvigilatorLoginRequest, CredentialValidationRequest, CredentialValidationResponse
from app.services import invigilator_service
router = APIRouter(prefix="/invigilator", tags=["Invigilator Management"])
# ------------------------------------------------------------------------------
# Login Route (Open to public, verifies role is invigilator)
# ------------------------------------------------------------------------------
@router.post("/login", response_model=LoginResponse)
def login(request: InvigilatorLoginRequest, db: Session = Depends(get_db)):
    """
    Dedicated login route for Invigilators.
    """
    user = db.query(User).filter(User.username == request.username).first()
    if not user or user.role != "invigilator":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username, password, or role authorization."
        )
    if not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username, password, or role authorization."
        )
    # Issue tokens
    access_token = create_access_token(data={"sub": user.id, "role": user.role, "type": "access"})
    refresh_token = create_access_token(
        data={"sub": user.id, "role": user.role, "type": "refresh"}, 
        expires_delta=timedelta(days=7)
    )
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "role": user.role
    }
# ------------------------------------------------------------------------------
# Protected Routes (Require invigilator role authorization)
# ------------------------------------------------------------------------------
@router.get("/exams", response_model=List[ExamResponse], dependencies=[Depends(RoleChecker(["invigilator"]))])
def get_assigned_exams(db: Session = Depends(get_db)):
    """
    Get a list of all active or scheduled examinations.
    """
    return invigilator_service.get_assigned_exams(db)
@router.get("/subjects/{subject_id}", response_model=SubjectResponse, dependencies=[Depends(RoleChecker(["invigilator"]))])
def get_subject_details(subject_id: str, db: Session = Depends(get_db)):
    """
    Fetch descriptive course metadata details for a subject.
    """
    return invigilator_service.get_subject_details(db, subject_id)
@router.get("/exams/{exam_id}/qr-code", response_model=QRTokenResponse, dependencies=[Depends(RoleChecker(["invigilator"]))])
def display_exam_qr_code(exam_id: str, db: Session = Depends(get_db)):
    """
    Display/retrieve the active encrypted QR start token for an exam.
    Students scan this QR to unlock their local exam offline.
    """
    return invigilator_service.get_active_exam_qr_token(db, exam_id)
@router.get("/schedule", response_model=List[ExamResponse], dependencies=[Depends(RoleChecker(["invigilator"]))])
def get_exam_schedule(db: Session = Depends(get_db)):
    """
    Retrieve the chronological exam schedule list.
    """
    # Simply retrieves ongoing and scheduled exam list
    return invigilator_service.get_assigned_exams(db)
@router.post("/validate-credential", response_model=CredentialValidationResponse)
def validate_one_time_credential(
    request: CredentialValidationRequest, 
    current_user: User = Depends(RoleChecker(["invigilator"])), 
    db: Session = Depends(get_db)
):
    """
    Validate a one-time passcode verification block assigned to this invigilator.
    Used during offline unlock audits.
    """
    return invigilator_service.validate_one_time_passcode(db, current_user.id, request.passcode)
