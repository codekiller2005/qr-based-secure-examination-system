from app.auth.security import verify_password
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()

user = db.query(User).filter(User.username == "admin_sarah").first()

print("User found:", user is not None)
print("Hash:", user.hashed_password)

result = verify_password(
    "AdminSecretPass123!",
    user.hashed_password
)

print("Password valid:", result)

db.close()