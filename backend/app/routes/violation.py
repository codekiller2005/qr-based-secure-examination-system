from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.auth.dependencies import RoleChecker
from app.schemas.violation import (
    ViolationCreate, ViolationSyncRequest, ViolationResponse,
    StudentViolationReport, ExamViolationReport
)
from app.services import violation_service
router = APIRouter(prefix="/violations", tags=["Violation Auditing"])
# ==============================================================================
# Client / Submission Integration Paths (Students, Invigilators, Admins)
# ==============================================================================
@router.post(
    "", 
    response_model=ViolationResponse, 
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RoleChecker(["admin", "invigilator", "student"]))]
)
def record_violation(violation: ViolationCreate, db: Session = Depends(get_db)):
    """
    Log a single environmental integrity violation (e.g. Screenshot taken).
    Accessible to Students, Invigilators, and Admins.
    """
    return violation_service.record_single_violation(db, violation)
@router.post(
    "/sync", 
    response_model=List[ViolationResponse],
    dependencies=[Depends(RoleChecker(["admin", "invigilator", "student"]))]
)
def sync_offline_violations(request: ViolationSyncRequest, db: Session = Depends(get_db)):
    """
    Bulk synchronize offline collected violation logs.
    Audits the client-side cryptographical hash chain before registering logs.
    Accessible to Students, Invigilators, and Admins.
    """
    return violation_service.sync_offline_violations(
        db, 
        student_exam_id=request.student_exam_id, 
        violations=request.violations
    )
# ==============================================================================
# Administrative Reporting Paths (Admins and Invigilators only)
# ==============================================================================
@router.get(
    "/student/{student_id}", 
    response_model=List[ViolationResponse],
    dependencies=[Depends(RoleChecker(["admin", "invigilator"]))]
)
def get_student_violations(student_id: str, db: Session = Depends(get_db)):
    """
    Retrieve all violation logs associated with a student across all exams.
    """
    return violation_service.get_student_violations(db, student_id)
@router.get(
    "/exam/{exam_id}", 
    response_model=List[ViolationResponse],
    dependencies=[Depends(RoleChecker(["admin", "invigilator"]))]
)
def get_exam_violations(exam_id: str, db: Session = Depends(get_db)):
    """
    Retrieve all violation logs associated with a specific exam session.
    """
    return violation_service.get_exam_violations(db, exam_id)
@router.get(
    "/reports/exam/{exam_id}", 
    response_model=ExamViolationReport,
    dependencies=[Depends(RoleChecker(["admin", "invigilator"]))]
)
def get_exam_violation_report(exam_id: str, db: Session = Depends(get_db)):
    """
    Generate an aggregated security audit report for an exam.
    Computes total flags, ratios, and registers list of flagged students.
    """
    return violation_service.get_exam_violation_report(db, exam_id)
@router.get(
    "/reports/student/{student_id}/exam/{exam_id}", 
    response_model=StudentViolationReport,
    dependencies=[Depends(RoleChecker(["admin", "invigilator"]))]
)
def get_student_exam_violation_report(student_id: str, exam_id: str, db: Session = Depends(get_db)):
    """
    Retrieve a detailed audit profile of a student's violations for a specific exam.
    """
    return violation_service.get_student_exam_report(db, student_id, exam_id)
