import uuid
from sqlalchemy import Column, String, Text, DateTime, func
from sqlalchemy.orm import relationship
from app.database import Base
class Subject(Base):
    """
    SQLAlchemy model representing academic subjects/courses (e.g. CS-101, MATH-202).
    Used to categorize and organize examinations.
    """
    __tablename__ = "subjects"
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    code = Column(String(20), unique=True, nullable=False, index=True) # e.g. 'CS-101'
    name = Column(String(100), nullable=False) # e.g. 'Intro to Computer Science'
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    # Relationships
    exams = relationship("Exam", back_populates="subject", cascade="all, delete-orphan")
    def __repr__(self) -> str:
        return f"<Subject code={self.code} name={self.name}>"
