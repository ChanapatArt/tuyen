import pandas as pd
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

# 1. โหลดค่าการเชื่อมต่อฐานข้อมูลจากไฟล์ .env
load_dotenv(os.path.join("app", ".env"))
DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)

def migrate_data():
    print("⏳ กำลังโหลดข้อมูลจากไฟล์ cleaned_all_recipes.pkl...")
    df = pd.read_pickle(os.path.join("data", "cleaned_all_recipes.pkl"))

    print("🔄 กำลังแปลงโครงสร้างคอลัมน์ให้เข้ากับตารางใหม่...")
    # 2. สร้าง DataFrame ตัวใหม่เพื่อจับคู่คอลัมน์ (Mapping)
    df_mapped = pd.DataFrame()
    df_mapped['title'] = df['name']          # เปลี่ยน name เป็น title
    df_mapped['prep_time'] = df['minutes']   # เปลี่ยน minutes เป็น prep_time
    df_mapped['calories'] = df['calories']   # calories คงเดิม
    
    # ถ้ามีคอลัมน์ steps ให้แปลงเป็น String แล้วใส่ในช่อง description
    if 'steps' in df.columns:
        df_mapped['description'] = df['steps'].apply(lambda x: str(x) if isinstance(x, list) else x)
    else:
        df_mapped['description'] = None
        
    # เว้นว่างช่องรูปภาพไว้ก่อน (ถ้าอนาคตมีรูปค่อยมาอัปเดต)
    df_mapped['image_url'] = None 

    print(f"📦 เตรียมข้อมูลสูตรอาหารทั้งหมด {len(df_mapped):,} รายการ...")
    
    # 3. นำเข้าข้อมูลลงตาราง recipes บน AWS RDS
    print("🚀 กำลังอัปโหลดขึ้น AWS RDS (อาจใช้เวลา 1-3 นาที กรุณารอจนกว่าจะเสร็จ)...")
    with engine.connect() as conn:
        # ใช้ chunksize=5000 เพื่อแบ่งส่งข้อมูลทีละ 5,000 แถว ป้องกันเน็ตหลุดกลางทาง
        df_mapped.to_sql('recipes', conn, if_exists='append', index=False, chunksize=5000)
        
    print("✅ อัปโหลดข้อมูลสูตรอาหารลงตาราง 'recipes' โครงสร้างใหม่สำเร็จเรียบร้อยแล้ว!")

if __name__ == "__main__":
    migrate_data()