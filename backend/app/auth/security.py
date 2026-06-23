from passlib.context import CryptContext
# Define cryptography context using bcrypt hashing algorithm
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
def hash_password(password: str) -> str:
    """
    Hashes a plain-text password using the bcrypt algorithm.
    
    Args:
        password: Plain text password to hash.
    Returns:
        The hashed password string.
    """
    return pwd_context.hash(password)
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verifies a plain password against an existing hash.
    
    Args:
        plain_password: Plain text password.
        hashed_password: Salted hash from database.
    Returns:
        Boolean indicating if the password matches the hash.
    """
    return pwd_context.verify(plain_password, hashed_password)
