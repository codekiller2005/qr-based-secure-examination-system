import uuid
from sqlalchemy import Column, String, Text, Integer, DateTime, Enum, LargeBinary, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base
class Exam(Base):
    """
    SQLAlchemy model representing an Examination.
    Stores metadata, session timeframe parameters, and the encrypted exam questions package.
    """
    __tablename__ = "exams"
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    subject_id = Column(String(36), ForeignKey("subjects.id", ondelete="RESTRICT", onupdate="CASCADE"), nullable=False)
    title = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(DateTime, nullable=False, index=True)
    end_time = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    pdf_path = Column(String(500), nullable=True)
    encrypted_questions = Column(LargeBinary, nullable=False) # LONGBLOB containing AES-256-GCM questions payload
    passcode_hash = Column(String(255), nullable=False) # Verification hash to unlock the exam offline
    status = Column(Enum("draft", "scheduled", "ongoing", "completed", name="exam_status"), nullable=False, default="draft", index=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    # Relationships
    subject = relationship("Subject", back_populates="exams")
    student_exams = relationship("StudentExam", back_populates="exam", cascade="all, delete-orphan")
    qr_tokens = relationship("QRToken", back_populates="exam", cascade="all, delete-orphan")
    def __repr__(self) -> str:
        return f"<Exam title={self.title} status={self.status}>"
