import pandas as pd
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

# --- 1. ตั้งค่า Path สำหรับหาไฟล์ ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ENV_PATH = os.path.join(BASE_DIR, "app", ".env")  # ชี้ไปที่ไฟล์ .env ในโฟลเดอร์ app
DATA_PATH = os.path.join(BASE_DIR, "data", "cleaned_all_recipes.pkl") # ดึงข้อมูลจากโฟลเดอร์ data

# --- 2. โหลดการเชื่อมต่อฐานข้อมูล ---
load_dotenv(ENV_PATH)
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    print("หา DATABASE_URL ไม่เจอ เช็คไฟล์ .env ด่วนครับ!")
    exit()

engine = create_engine(DATABASE_URL)

# --- 3. โหลดข้อมูล ---
print("1. กำลังอ่านข้อมูลจากไฟล์ .pkl...")
df = pd.read_pickle(DATA_PATH)

# เลือกเฉพาะคอลัมน์ที่จะเอาไปใช้ในแอปจริงๆ เพื่อประหยัดพื้นที่ฐานข้อมูล
cols_to_keep = ['id', 'name', 'category', 'minutes', 'calories', 'protein', 'ingredients', 'steps']
# กรองเอาเฉพาะคอลัมน์ที่มีอยู่จริงใน df
cols_to_keep = [col for col in cols_to_keep if col in df.columns]
df_to_upload = df[cols_to_keep].copy()

# --- 4. แปลงข้อมูล List เป็นข้อความ (Text) ---
# ฐานข้อมูล SQL ทั่วไปจะไม่เข้าใจโครงสร้างแบบ Python List เราเลยต้องแปลงเป็นตัวหนังสือ (String) ก่อน
print("2. กำลังแปลงชนิดข้อมูล...")
for col in ['ingredients', 'steps']:
    if col in df_to_upload.columns:
        df_to_upload[col] = df_to_upload[col].astype(str)

# --- 5. อัปโหลดข้อมูลขึ้น AWS RDS ---
# if_exists='replace' หมายถึง ถ้ามีตารางชื่อนี้อยู่แล้ว ให้ลบทิ้งแล้วสร้างใหม่ทับลงไป
print(f"3. กำลังอัปโหลดข้อมูล {len(df_to_upload)} เมนู ขึ้น AWS RDS...")
print("⏳ (ขั้นตอนนี้อาจใช้เวลา 1-3 นาที ขึ้นอยู่กับความเร็วเน็ตและขนาดข้อมูล)")

df_to_upload.to_sql('recipes', engine, if_exists='replace', index=False)

print("อัปโหลดข้อมูลลงตาราง 'recipes' ใน AWS RDS สำเร็จเรียบร้อยแล้ว!")