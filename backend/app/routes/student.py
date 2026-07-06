from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from datetime import timedelta
from app.database import get_db
from app.models.user import User
from app.auth.security import verify_password
from app.auth.jwt_handler import create_access_token
from app.auth.dependencies import RoleChecker, get_current_user
from app.schemas.auth import LoginResponse, UserResponse
from app.schemas.exam import ExamResponse
from app.schemas.student import (
    StudentLoginRequest, QRValidationRequest, QRValidationResponse,
    ExamStartResponse, ExamSubmissionRequest, ExamSubmissionResponse
)
from app.services import student_service
from app.services.exam_service import get_exam_by_id
router = APIRouter(prefix="/student", tags=["Student Exam Portal"])
# ------------------------------------------------------------------------------
# Login Endpoint (Public, enforces student role check)
# ------------------------------------------------------------------------------
@router.post("/login", response_model=LoginResponse)
def login(request: StudentLoginRequest, db: Session = Depends(get_db)):
    """
    Dedicated login route for students.
    """
    user = db.query(User).filter(User.username == request.username).first()
    if not user or user.role != "student":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username, password, or student registration authorization."
        )
    if not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username, password, or student registration authorization."
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
# Protected Student Routes
# ------------------------------------------------------------------------------
@router.get("/profile", response_model=UserResponse)
def get_profile(current_user: User = Depends(RoleChecker(["student"]))):
    """
    Retrieve authenticated student profile details.
    """
    return current_user
@router.post("/validate-qr", response_model=QRValidationResponse, dependencies=[Depends(RoleChecker(["student"]))])
def validate_exam_start_qr(request: QRValidationRequest, db: Session = Depends(get_db)):
    """
    Validate the scanned start QR code.
    Returns the exam's metadata description if successful.
    """
    return student_service.validate_start_qr_token(db, request.token)
@router.post("/exams/{exam_id}/start", response_model=ExamStartResponse)
def start_exam_session(
    exam_id: str, 
    current_user: User = Depends(RoleChecker(["student"])), 
    db: Session = Depends(get_db)
):
    """
    Initialize an active exam session on the server.
    Fails if the student is not registered or has already submitted.
    """
    return student_service.start_exam_session(db, current_user.id, exam_id)
@router.post("/submit", response_model=ExamSubmissionResponse)
def submit_exam_responses(
    request: ExamSubmissionRequest, 
    current_user: User = Depends(RoleChecker(["student"])), 
    db: Session = Depends(get_db)
):
    """
    Synchronize completed offline answers and violation logs back to the server.
    Verifies cryptographic signatures and hash chain bounds before committing.
    """
    return student_service.submit_exam_session(db, current_user.id, request)
@router.get("/exams")
def get_my_exams(
    current_user: User = Depends(RoleChecker(["student"])),
    db: Session = Depends(get_db)
):
    print("CURRENT STUDENT ID:", current_user.id)
    """
    Returns all exams assigned to the logged-in student.
    """
    return student_service.get_student_exams(db, current_user.id)
@router.get("/exams/{exam_id}", response_model=ExamResponse, dependencies=[Depends(RoleChecker(["student"]))])
def get_exam_details(exam_id: str, db: Session = Depends(get_db)):
    """
    Fetch metadata info for a specific exam by ID.
    """
    return get_exam_by_id(db, exam_id)


    

@router.get(
    "/exams/{exam_id}/question-paper",
    dependencies=[Depends(RoleChecker(["student"]))]
)
def download_question_paper(
    exam_id: str,
    current_user: User = Depends(RoleChecker(["student"])),
    db: Session = Depends(get_db),
):
    """
    Download the question paper PDF for an assigned exam.
    """
    return student_service.download_question_paper(
        db,
        current_user.id,
        exam_id,
    )
@router.post(
    "/exams/{exam_id}/finish",
    dependencies=[Depends(RoleChecker(["student"]))]
)
def finish_exam(
    exam_id: str,
    current_user: User = Depends(RoleChecker(["student"])),
    db: Session = Depends(get_db),
):
    return student_service.finish_exam(
        db,
        current_user.id,
        exam_id,
    )

