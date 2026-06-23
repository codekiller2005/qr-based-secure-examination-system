import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL
class Settings(BaseSettings):
    """
    Application configurations and settings container.
    Loads values from environment variables or a local `.env` file.
    """
    # Application Configuration
    APP_NAME: str = "Secure Offline Exam API"
    APP_ENV: str = "development"
    DEBUG: bool = True
    # Database Settings (MySQL)
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_USER: str = "root"
    DB_PASSWORD: str = ""
    DB_NAME: str = "qr_exam_system"
    # Security & JWT Token Config
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 120
    # Configure Pydantic to read from environment file
    model_config = SettingsConfigDict(
        env_file=os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )
    @property
    def DATABASE_URL(self) -> str:
        """
        Constructs the MySQL connection URI string using SQLAlchemy's URL.create() utility.
        This handles URL encoding for passwords containing special characters (e.g. @, #, %, $).
        """
        return str(
            URL.create(
                drivername="mysql+pymysql",
                username=self.DB_USER,
                password=self.DB_PASSWORD,
                host=self.DB_HOST,
                port=self.DB_PORT,
                database=self.DB_NAME
            )
        )
# Instantiate settings to be imported throughout the project


settings = Settings()

print("DB_USER =", settings.DB_USER)
print("DB_PASSWORD =", repr(settings.DB_PASSWORD))
print("DB_HOST =", settings.DB_HOST)
print("DB_NAME =", settings.DB_NAME)
print("DATABASE_URL =", settings.DATABASE_URL)