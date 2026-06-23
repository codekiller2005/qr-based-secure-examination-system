import sys
import os
# Append the project root to sys.path so we can run this script directly
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.database import engine, Base
# Importing the models package automatically registers all models with SQLAlchemy's metadata Base
from app.models import User, Subject, Exam, StudentExam, Violation, InvigilatorCredential, QRToken
def init_database():
    """
    Imports all models and initializes the database by creating all tables.
    Use this for direct schema creation in development environments.
    """
    print("Connecting to database engine and preparing schema initialization...")
    try:
        # Create all tables defined in models if they do not exist
        Base.metadata.create_all(bind=engine)
        print("Database initialized successfully! All tables created.")
    except Exception as e:
        print(f"Error initializing database: {e}")
        sys.exit(1)
if __name__ == "__main__":
    init_database()
