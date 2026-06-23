from sqlalchemy import create_engine, text

engine = create_engine(
    "mysql+pymysql://exam_user:exam123@localhost:3306/qr_exam_system"
)

try:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("SQLALCHEMY CONNECTED:", result.scalar())
except Exception as e:
    print("ERROR:", e)