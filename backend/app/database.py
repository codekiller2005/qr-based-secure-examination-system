from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.config import settings
# Create engine to establish connection to the MySQL database
# pool_pre_ping=True checks connections for liveness before executing queries
print("DATABASE_URL:", settings.DATABASE_URL)
engine = create_engine(
    "mysql+pymysql://exam_user:test123@127.0.0.1:3306/qr_exam_system",
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=True
)
# Local session constructor for executing database queries
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)
# Declarative base class for defining database models
Base = declarative_base()
def get_db() -> Generator:
    """
    FastAPI dependency injection provider.
    Yields a database session context that is automatically closed after the request completes.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
