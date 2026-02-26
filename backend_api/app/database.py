from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
import os
from dotenv import load_dotenv

# --- เริ่มส่วนที่แก้ใหม่ ---
# 1. หาตำแหน่งของโฟลเดอร์ app ปัจจุบัน
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# 2. ชี้ไปที่ไฟล์ .env ที่อยู่ในโฟลเดอร์ app/
ENV_PATH = os.path.join(BASE_DIR, ".env")

# 3. โหลดไฟล์ .env แบบระบุตำแหน่งชัดเจน
load_dotenv(ENV_PATH)

# ดึง URL ของฐานข้อมูลมา
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

# ดัก Error ไว้เตือนตัวเอง ถ้ายังหาไม่เจออีก
if SQLALCHEMY_DATABASE_URL is None:
    raise ValueError(f"หาไฟล์ .env ไม่เจอ หรือในไฟล์ไม่มี DATABASE_URL ลองเช็คที่: {ENV_PATH}")
# --- จบส่วนที่แก้ใหม่ ---

# สร้าง Engine สำหรับเชื่อมต่อ AWS RDS
engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()