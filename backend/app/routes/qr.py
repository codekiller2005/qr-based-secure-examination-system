from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth.dependencies import RoleChecker
from app.schemas.qr import QRTokenGenerateRequest, QRTokenValidateRequest, QRTokenDetailResponse
from app.services import qr_service
router = APIRouter(prefix="/qr", tags=["QR Code Token Validation"])
@router.post(
    "/generate", 
    response_model=QRTokenDetailResponse, 
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(RoleChecker(["admin", "invigilator"]))]
)
def generate_qr_token(request: QRTokenGenerateRequest, db: Session = Depends(get_db)):
    """
    Generate a secure UUID-based QR token for starting an exam.
    Accessible only to Admins and Invigilators.
    """
    return qr_service.generate_secure_qr_token(
        db, 
        exam_id=request.exam_id, 
        expires_in_minutes=request.expires_in_minutes
    )
@router.post(
    "/validate", 
    response_model=QRTokenDetailResponse,
    dependencies=[Depends(RoleChecker(["admin", "invigilator", "student"]))]
)
def validate_qr_token(request: QRTokenValidateRequest, db: Session = Depends(get_db)):
    """
    Validate a scanned QR code token value.
    Verifies existence, token reuse status, and expiration windows.
    """
    return qr_service.validate_qr_token(db, token_value=request.token_value)
@router.post(
    "/use", 
    dependencies=[Depends(RoleChecker(["admin", "invigilator", "student"]))]
)
def consume_qr_token(request: QRTokenValidateRequest, db: Session = Depends(get_db)):
    """
    Consume a scanned QR token to prevent future token reuse.
    Executed when the student client launches the exam paper.
    """
    return qr_service.use_qr_token(db, token_value=request.token_value)
