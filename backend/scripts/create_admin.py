import sys
import os
import getpass
# Append project root to sys.path so we can import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.database import SessionLocal
from app.models.user import User
from app.auth.security import hash_password
def create_admin():
    """
    CLI command to generate the first administrative user in the database.
    """
    print("====================================================")
    # Correct backticks in system prompt messages
    print("Initial Admin Account Creation Script")
    print("====================================================")
    
    db = SessionLocal()
    try:
        username = input("Enter admin username: ").strip()
        if not username:
            print("Error: Username cannot be blank.")
            return
        # Check if username exists
        existing_user = db.query(User).filter(User.username == username).first()
        if existing_user:
            print(f"Error: A user with username '{username}' already exists.")
            return
        email = input("Enter admin email address: ").strip()
        if not email or "@" not in email:
            print("Error: Invalid email format.")
            return
            
        existing_email = db.query(User).filter(User.email == email).first()
        if existing_email:
            print(f"Error: A user with email '{email}' already exists.")
            return
        password = getpass.getpass("Enter admin password: ")
        confirm_password = getpass.getpass("Confirm admin password: ")
        
        if password != confirm_password:
            print("Error: Passwords do not match.")
            return
        if len(password) < 6:
            print("Error: Password must contain at least 6 characters.")
            return
        # Create Admin
        hashed = hash_password(password)
        admin = User(
            username=username,
            email=email,
            hashed_password=hashed,
            role="admin",
            public_key=None
        )
        db.add(admin)
        db.commit()
        db.refresh(admin)
        print("\nSuccess! Admin account created successfully:")
        print(f"  ID:       {admin.id}")
        print(f"  Username: {admin.username}")
        print(f"  Email:    {admin.email}")
        print(f"  Role:     {admin.role}")
    except Exception as e:
        print(f"\nAn error occurred during creation: {e}")
        db.rollback()
    finally:
        db.close()
if __name__ == "__main__":
    create_admin()
