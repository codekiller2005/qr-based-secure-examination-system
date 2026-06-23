import pymysql

try:
    conn = pymysql.connect(
        host="localhost",
        user="exam_user",
        password="test123",
        database="qr_exam_system"
    )

    print("CONNECTED SUCCESSFULLY")
    conn.close()

except Exception as e:
    print("ERROR:", e)