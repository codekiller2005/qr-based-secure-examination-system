
import sys
import os
import base64
from datetime import datetime, timedelta
import traceback
# Append project root to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.config import settings
print("SEED SCRIPT URL =", settings.DATABASE_URL)
from app.database import SessionLocal, Base, engine
from app.models.user import User
from app.models.subject import Subject
from app.models.exam import Exam
from app.models.student_exam import StudentExam
from app.models.violation import Violation
from app.models.invigilator_credential import InvigilatorCredential
from app.models.qr_token import QRToken
from app.auth.security import hash_password
# Sample Student PEM public key blocks for cryptographic signing tests
TEST_STUDENT_A_PUB_KEY = (
    "-----BEGIN PUBLIC KEY-----\n"
    "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzV1x15tD7a9A4K8E0o1G\n"
    "H5qS6uT8xGgH5F5F+nZtJ1wF2v4D2F2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb\n"
    "4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2V\n"
    "fG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2k\n"
    "F4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb\n"
    "4wIDAQAB\n"
    "-----END PUBLIC KEY-----\n"
)
TEST_STUDENT_B_PUB_KEY = (
    "-----BEGIN PUBLIC KEY-----\n"
    "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxT0w81sF8b9B5L9Fc9X2\n"
    "H5qS6uT8xGgH5F5F+nZtJ1wF2v4D2F2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb\n"
    "4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2V\n"
    "fG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2k\n"
    "F4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb4B2VfG2kF4Vb\n"
    "5wIDAQAB\n"
    "-----END PUBLIC KEY-----\n"
)
def clear_database(db):
    print("Deleting violations...")
    db.query(Violation).delete()

    print("Deleting student_exams...")
    db.query(StudentExam).delete()

    print("Deleting qr_tokens...")
    db.query(QRToken).delete()

    print("Deleting invigilator_credentials...")
    db.query(InvigilatorCredential).delete()

    print("Deleting exams...")
    db.query(Exam).delete()

    print("Deleting subjects...")
    db.query(Subject).delete()

    print("Deleting users...")
    db.query(User).delete()

    db.commit()
    print("Database cleared successfully.")
def seed_database():
    """
    Seeds database with test data models.
    """
    db = SessionLocal()
    try:
        # 1. Clear database
        clear_database(db)
        # 2. Seed Users
        print("Inserting user records (Admin, Invigilators, Students)...")
        
        # Admin (pwd: AdminSecretPass123!)
        admin = User(
            
            username="admin_sarah",
            email="sarah.admin@academy.edu",
            hashed_password=hash_password("AdminSecretPass123!"),
            role="admin"
        )
        db.add(admin)
        # Invigilator (pwd: GuardPass456!)
        invigilator = User(
            
            username="invig_robert",
            email="robert.guard@academy.edu",
            hashed_password=hash_password("GuardPass456!"),
            role="invigilator"
        )
        db.add(invigilator)
        # Student A (pwd: StudentPassA!) - Valid Device key
        student_a = User(
            
            username="john_doe",
            email="john.doe@student.edu",
            hashed_password=hash_password("StudentPassA!"),
            role="student",
            public_key=TEST_STUDENT_A_PUB_KEY
        )
        db.add(student_a)
        # Student B (pwd: StudentPassB!) - Valid Device key
        student_b = User(
            
            username="jane_cheater",
            email="jane.cheater@student.edu",
            hashed_password=hash_password("StudentPassB!"),
            role="student",
            public_key=TEST_STUDENT_B_PUB_KEY
        )
        db.add(student_b)
        # 3. Seed Subjects
        print("Inserting subject records (CS-302, CS-101)...")
        sub_os = Subject(
            
            code="CS-302",
            name="Operating Systems",
            description="Detailed look at scheduling, processes, memory paging, filesystem and kernel logic."
        )
        db.add(sub_os)
        sub_intro = Subject(
            
            code="CS-101",
            name="Introduction to Programming",
            description="Foundational concepts of computing using Python language."
        )
        db.add(sub_intro)
        # Save to DB so we can reference IDs
        db.commit()
        # 4. Seed Exams
        print("Inserting scheduled examinations...")
        
        # Base64 encrypted mock payloads representing questions
        os_questions_mock = base64.b64decode(
            "T3BlcmF0aW5nIFN5c3RlbXMgTWlkdGVybSBRdWVzdGlvbnMgUGFja2FnZSBFbmNyeXB0ZWQgVmlhIEFFUy1HQ00u"
        )
        intro_questions_mock = base64.b64decode(
            "SW50cm9kdWN0aW9uIHRvIFByb2dyYW1taW5nIEZpbmFsIFF1ZXN0aW9ucyBQYWNrYWdlIEVuY3J5cHRlZCBWaWEgQUVTLUdDTS4="
        )
        exam_os = Exam(
           
            subject_id=sub_os.id,
            title="Operating Systems Midterm 2026",
            description="Testing processes, virtual memory architectures, and disk scheduling.",
            start_time=datetime.now() - timedelta(hours=1), # Ongoing
            end_time=datetime.now() + timedelta(hours=2),
            duration_minutes=120,
            encrypted_questions=os_questions_mock,
            passcode_hash=hash_password("UnlockOS2026!"),
            status="ongoing"
        )
        db.add(exam_os)
        exam_intro = Exam(
           
            subject_id=sub_intro.id,
            title="Python Fundamentals Final 2026",
            description="Basic syntax, recursive algorithms, control logic, and data structures.",
            start_time=datetime.now() + timedelta(days=2), # Upcoming
            end_time=datetime.now() + timedelta(days=2, hours=3),
            duration_minutes=180,
            encrypted_questions=intro_questions_mock,
            passcode_hash=hash_password("UnlockIntro2026!"),
            status="scheduled"
        )
        db.add(exam_intro)
        
        db.commit()
        # 5. Seed Student Exam Registrations
        print("Enrolling students into exams...")
        
        # John Doe registered for Operating Systems
        reg_john_os = StudentExam(
          
            student_id=student_a.id,
            exam_id=exam_os.id,
            status="registered"
        )
        db.add(reg_john_os)
        # Jane Cheater registered for Operating Systems
        reg_jane_os = StudentExam(
           
            student_id=student_b.id,
            exam_id=exam_os.id,
            status="registered"
        )
        db.add(reg_jane_os)
        # John Doe registered for Python final
        reg_john_intro = StudentExam(
           
            student_id=student_a.id,
            exam_id=exam_intro.id,
            status="registered"
        )
        db.add(reg_john_intro)
        db.commit()
        print("\nSuccess! Database seeded with mock profiles, courses, and schedules.")
        
    except Exception as e:
        print(f"\nAn error occurred while seeding: {e}")
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()
if __name__ == "__main__":
    seed_database()
