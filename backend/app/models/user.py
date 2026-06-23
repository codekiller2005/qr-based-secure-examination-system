import uuid
from sqlalchemy import Column, String, Enum, Text, DateTime, func
from sqlalchemy.orm import relationship
from app.database import Base
class User(Base):
    """
    SQLAlchemy model representing system users (Students, Invigilators, and Admins).
    Stores credentials, role, and the cryptographic public key for student devices.
    """
    __tablename__ = "users"
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum("student", "invigilator", "admin", name="user_roles"), nullable=False, default="student")
    public_key = Column(Text, nullable=True) # RSA-2048 public key for verifying offline submissions
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    # Relationships
    student_exams = relationship("StudentExam", back_populates="student", cascade="all, delete-orphan")
    invigilator_credentials = relationship("InvigilatorCredential", back_populates="user", cascade="all, delete-orphan")
    def __repr__(self) -> str:
        return f"<User username={self.username} role={self.role}>"
