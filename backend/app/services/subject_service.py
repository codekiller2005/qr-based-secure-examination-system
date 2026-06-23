from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.subject import Subject
from app.models.exam import Exam
from app.schemas.subject import SubjectCreate, SubjectUpdate
def create_subject(db: Session, subject_in: SubjectCreate) -> Subject:
    """
    Creates a new Subject. Checks for duplicate code entries.
    """
    # Check if subject code already exists
    existing = db.query(Subject).filter(Subject.code == subject_in.code).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Subject code '{subject_in.code}' already registered."
        )
    db_subject = Subject(
        code=subject_in.code,
        name=subject_in.name,
        description=subject_in.description
    )
    db.add(db_subject)
    db.commit()
    db.refresh(db_subject)
    return db_subject
def get_subjects(db: Session, skip: int = 0, limit: int = 100):
    """
    Retrieves all Subject records with pagination.
    """
    return db.query(Subject).offset(skip).limit(limit).all()
def get_subject_by_id(db: Session, subject_id: str) -> Subject:
    """
    Retrieves a Subject by ID. Raises 404 if not found.
    """
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Subject not found."
        )
    return subject
def update_subject(db: Session, subject_id: str, subject_in: SubjectUpdate) -> Subject:
    """
    Updates a Subject record.
    """
    db_subject = get_subject_by_id(db, subject_id)
    
    # Update fields if provided
    if subject_in.name is not None:
        db_subject.name = subject_in.name
    if subject_in.description is not None:
        db_subject.description = subject_in.description
        
    db.commit()
    db.refresh(db_subject)
    return db_subject
def delete_subject(db: Session, subject_id: str) -> None:
    """
    Deletes a Subject. Verifies that it has no linked exams first.
    """
    db_subject = get_subject_by_id(db, subject_id)
    
    # Check if subject is associated with any exams
    linked_exams = db.query(Exam).filter(Exam.subject_id == subject_id).first()
    if linked_exams:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete subject. It has examinations scheduled."
        )
        
    db.delete(db_subject)
    db.commit()
