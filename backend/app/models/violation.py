import uuid
from sqlalchemy import Column, String, Enum, DateTime, Text, Integer, ForeignKey, func
from sqlalchemy.orm import relationship
from app.database import Base
class Violation(Base):
    """
    SQLAlchemy model representing a security violation event during an exam.
    Part of a hash chain verifying the integrity of logged exam events.
    """
    __tablename__ = "violations"
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_exam_id = Column(String(36), ForeignKey("student_exams.id", ondelete="CASCADE", onupdate="CASCADE"), nullable=False)
    violation_type = Column(
        Enum("SCREENSHOT", "APP_BACKGROUNDED", "INTERNET_ON", "CLOCK_DRIFT", "USB_CONNECTED", name="violation_event_type"), 
        nullable=False,
        index=True
    )
    timestamp = Column(DateTime, nullable=False)
    details = Column(Text, nullable=True)
    chain_index = Column(Integer, nullable=False) # Index of violation in the device hash chain
    hash_value = Column(String(64), nullable=False) # SHA-256 cumulative chain hash
    created_at = Column(DateTime, server_default=func.now())
    # Relationships
    student_exam = relationship("StudentExam", back_populates="violations")
    def __repr__(self) -> str:
        return f"<Violation type={self.violation_type} chain_index={self.chain_index}>"
