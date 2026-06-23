# Expose all SQLAlchemy ORM models here
# This makes it easy to import all models from `app.models` and ensuring they register with Declarative Base
from app.models.user import User
from app.models.subject import Subject
from app.models.exam import Exam
from app.models.student_exam import StudentExam
from app.models.violation import Violation
from app.models.invigilator_credential import InvigilatorCredential
from app.models.qr_token import QRToken
__all__ = [
    "User",
    "Subject",
    "Exam",
    "StudentExam",
    "Violation",
    "InvigilatorCredential",
    "QRToken",
]