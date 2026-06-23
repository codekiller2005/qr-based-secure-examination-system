import uuid
from sqlalchemy import Column, String, Enum, LargeBinary, Text, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import relationship
from app.database import Base
class StudentExam(Base):
    """
    SQLAlchemy model representing a student's enrollment and submission status in an exam.
    Stores the final asymmetric encrypted answers and device signatures.
    """
    __tablename__ = "student_exams"
    __table_args__ = (
        UniqueConstraint("student_id", "exam_id", name="uq_student_exam"),
    )
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("users.id", ondelete="RESTRICT", onupdate="CASCADE"), nullable=False)
    exam_id = Column(String(36), ForeignKey("exams.id", ondelete="RESTRICT", onupdate="CASCADE"), nullable=False)
    status = Column(Enum("registered", "started", "submitted", "flagged", "absent", name="student_exam_status"), nullable=False, default="registered")
    encrypted_answers = Column(LargeBinary, nullable=True) # Answer payload encrypted with server public key
    client_signature = Column(Text, nullable=True) # RSA digital signature of answers + violation chain hash
    started_at = Column(DateTime, nullable=True)
    submitted_at = Column(DateTime, nullable=True)
    synced_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    # Relationships
    student = relationship("User", back_populates="student_exams")
    exam = relationship("Exam", back_populates="student_exams")
    violations = relationship("Violation", back_populates="student_exam", cascade="all, delete-orphan")
    def __repr__(self) -> str:
        return f"<StudentExam student_id={self.student_id} exam_id={self.exam_id} status={self.status}>"
