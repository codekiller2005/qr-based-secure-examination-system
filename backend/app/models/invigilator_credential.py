import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text, func
from sqlalchemy.orm import relationship
from app.database import Base
class InvigilatorCredential(Base):
    """
    SQLAlchemy model representing specific authorization keys, passcodes, or 
    certificates assigned to invigilators for offline exam unlocking or signing operations.
    """
    __tablename__ = "invigilator_credentials"
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE", onupdate="CASCADE"), nullable=False)
    credential_type = Column(String(50), nullable=False, default="passcode") # 'passcode', 'key_cert', 'session_token'
    credential_value = Column(Text, nullable=False) # Hashed passcode or cryptographic key block
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, server_default=func.now())
    expires_at = Column(DateTime, nullable=True)
    # Relationships
    user = relationship("User", back_populates="invigilator_credentials")
    def __repr__(self) -> str:
        return f"<InvigilatorCredential user_id={self.user_id} type={self.credential_type} active={self.is_active}>"
