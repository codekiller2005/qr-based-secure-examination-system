import hashlib
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status
from typing import List
from app.models.violation import Violation
from app.models.student_exam import StudentExam
from app.models.user import User
from app.models.exam import Exam
from app.schemas.violation import ViolationCreate
def record_single_violation(db: Session, violation_in: ViolationCreate) -> Violation:
    """
    Directly logs a single security violation.
    Updates the parent StudentExam session status to 'flagged'.
    """
    # Verify registration exists
    registration = db.query(StudentExam).filter(StudentExam.id == violation_in.student_exam_id).first()
    if not registration:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student exam registration session not found."
        )
    # Log violation
    db_violation = Violation(
        student_exam_id=violation_in.student_exam_id,
        violation_type=violation_in.violation_type,
        timestamp=violation_in.timestamp,
        details=violation_in.details,
        chain_index=violation_in.chain_index,
        hash_value=violation_in.hash_value
    )
    db.add(db_violation)
    # Flag registration status
    registration.status = "flagged"
    db.commit()
    db.refresh(db_violation)
    return db_violation
def sync_offline_violations(db: Session, student_exam_id: str, violations: List[ViolationCreate]) -> List[Violation]:
    """
    Performs batch synchronization and validation of offline violation logs.
    """
    registration = db.query(StudentExam).filter(StudentExam.id == student_exam_id).first()
    if not registration:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student registration session not found."
        )
    # Check and audit cryptographic hash chain
    prev_hash = "EXAM_START"
    sorted_violations = sorted(violations, key=lambda x: x.chain_index)
    
    created_violations = []
    for v in sorted_violations:
        details_str = v.details if v.details else ""
        # Reconstruct chain string format
        payload_str = f"{prev_hash}|{v.timestamp.isoformat()}|{v.violation_type}|{details_str}|{v.chain_index}"
        calculated_hash = hashlib.sha256(payload_str.encode()).hexdigest()
        
        if calculated_hash != v.hash_value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Verification failed: Tampered offline logs at index {v.chain_index}."
            )
            
        db_violation = Violation(
            student_exam_id=student_exam_id,
            violation_type=v.violation_type,
            timestamp=v.timestamp,
            details=v.details,
            chain_index=v.chain_index,
            hash_value=v.hash_value
        )
        db.add(db_violation)
        created_violations.append(db_violation)
        prev_hash = v.hash_value
    if created_violations:
        registration.status = "flagged"
        
    db.commit()
    return created_violations
def get_student_violations(db: Session, student_id: str) -> List[Violation]:
    """
    Retrieves all violation logs recorded for a given student across all exams.
    """
    return db.query(Violation).join(StudentExam).filter(StudentExam.student_id == student_id).all()
def get_exam_violations(db: Session, exam_id: str) -> List[Violation]:
    """
    Retrieves all violation logs recorded for a specific exam across all students.
    """
    return db.query(Violation).join(StudentExam).filter(StudentExam.exam_id == exam_id).all()
def get_student_exam_report(db: Session, student_id: str, exam_id: str) -> dict:
    """
    Generates a detailed audit profile of a student's violations for a specific exam.
    """
    student = db.query(User).filter(User.id == student_id).first()
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    
    if not student or not exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student or Exam entity not found."
        )
    registration = db.query(StudentExam).filter(
        StudentExam.student_id == student_id,
        StudentExam.exam_id == exam_id
    ).first()
    if not registration:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student is not registered for this exam."
        )
    violations = db.query(Violation).filter(Violation.student_exam_id == registration.id).order_by(Violation.chain_index).all()
    
    return {
        "student_id": student.id,
        "username": student.username,
        "email": student.email,
        "exam_id": exam.id,
        "exam_title": exam.title,
        "student_exam_status": registration.status,
        "violation_count": len(violations),
        "violations": violations
    }
def get_exam_violation_report(db: Session, exam_id: str) -> dict:
    """
    Generates an aggregated report of all flagged incidents for an examination session.
    """
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exam not found."
        )
    # 1. Total registered students
    total_registered = db.query(func.count(StudentExam.id)).filter(StudentExam.exam_id == exam_id).scalar()
    # 2. Flagged student counts
    total_flagged = db.query(func.count(StudentExam.id)).filter(
        StudentExam.exam_id == exam_id,
        StudentExam.status == "flagged"
    ).scalar()
    # 3. Total violations recorded
    total_violations = db.query(func.count(Violation.id)).join(StudentExam).filter(StudentExam.exam_id == exam_id).scalar()
    # 4. Group by violation counts by type
    type_counts = db.query(
        Violation.violation_type,
        func.count(Violation.id)
    ).join(StudentExam).filter(
        StudentExam.exam_id == exam_id
    ).group_by(Violation.violation_type).all()
    counts_dict = {str(vt): count for vt, count in type_counts}
    # 5. List flagged students
    flagged_students = db.query(
        User.id,
        User.username,
        User.email,
        func.count(Violation.id).label("v_count")
    ).join(StudentExam, StudentExam.student_id == User.id)\
     .join(Violation, Violation.student_exam_id == StudentExam.id)\
     .filter(StudentExam.exam_id == exam_id)\
     .group_by(User.id, User.username, User.email).all()
    student_list = [
        {
            "student_id": fs.id,
            "username": fs.username,
            "email": fs.email,
            "violations_count": str(fs.v_count)
        } for fs in flagged_students
    ]
    return {
        "exam_id": exam_id,
        "exam_title": exam.title,
        "total_students_registered": total_registered,
        "total_flagged_students": total_flagged,
        "total_violations": total_violations,
        "violation_counts_by_type": counts_dict,
        "flagged_student_list": student_list
    }
