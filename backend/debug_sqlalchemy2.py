from sqlalchemy import create_engine, text

url = "mysql+pymysql://exam_user:test123@127.0.0.1:3306/qr_exam_system"

print("URL:", url)

try:
    engine = create_engine(url)

    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1"))
        print("SUCCESS:", result.scalar())

except Exception as e:
    print("ERROR:", e)