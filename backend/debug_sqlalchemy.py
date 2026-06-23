from app.config import settings
from sqlalchemy import create_engine, text

print("URL:", settings.DATABASE_URL)

engine = create_engine(settings.DATABASE_URL)

try:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("SUCCESS:", result.scalar())
except Exception as e:
    print("ERROR:", e)