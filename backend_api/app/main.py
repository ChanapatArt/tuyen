from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import joblib
import numpy as np
import re
from sklearn.metrics.pairwise import cosine_similarity
import os
import ast
from fastapi import Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from .database import get_db, engine # นำเข้าไฟล์ database.py ที่เราเพิ่งสร้าง

#uvicorn app.main:app --reload
#http://127.0.0.1:8000/docs

# 1. กำหนดตัวแปรสำหรับ API
app = FastAPI(title="Smart Fridge API", description="AI Recipe Recommendation System")

# 2. จัดการ Path ของไฟล์ให้อ่านจากโฟลเดอร์ models/ ได้ถูกต้อง
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "../models")

print("กำลังอุ่นเครื่อง AI Models...")
# โหลดกล่องทัปเปอร์แวร์ทั้งหมดที่เราเตรียมไว้
word2vec_model = joblib.load(os.path.join(MODELS_DIR, 'word2vec_model.joblib'))
recipe_vectors = joblib.load(os.path.join(MODELS_DIR, 'recipe_vectors.joblib'))
bigram_model = joblib.load(os.path.join(MODELS_DIR, 'bigram_model.joblib'))
df_api = joblib.load(os.path.join(MODELS_DIR, 'df_for_api.joblib'))
print("✅ AI พร้อมรับออเดอร์แล้ว!")

# ==========================================
# 3. กำหนดหน้าตาข้อมูลที่รับเข้าและส่งออก (Pydantic Models)
# ==========================================
class FridgeRequest(BaseModel):
    ingredients: List[str]  # รับของในตู้เย็นมาเป็น List เช่น ["chicken", "egg"]
    top_k: int = 5          # อยากให้แนะนำกี่เมนู (ค่าเริ่มต้นคือ 5)

class RecipeResult(BaseModel):
    name: str
    category: str
    match_score_percent: float
    used_ingredients: List[str]     # ของที่มีและได้ใช้
    missing_ingredients: List[str]  # ของที่ขาด ต้องไปซื้อเพิ่ม
    all_ingredients: List[str]      # วัตถุดิบทั้งหมดของสูตรนี้

# ==========================================
# 4. ฟังก์ชันตัวช่วย (Helper Functions)
# ==========================================
def tokenize_ingredients(ingredient_list):
    text = " ".join(ingredient_list).lower()
    text = re.sub(r'[^a-z\s]', '', text)
    return text.split()

def get_recipe_vector(tokens, model):
    vectors = [model.wv[word] for word in tokens if word in model.wv]
    if len(vectors) == 0:
        return np.zeros(model.vector_size)
    return np.mean(vectors, axis=0)

# ==========================================
# 5. สร้าง Endpoints (ช่องทางติดต่อ)
# ==========================================

# Endpoint ที่ 1: เอาไว้เช็คว่า Server ล่มไหม (Health Check)
@app.get("/")
def read_root():
    return {"status": "ok", "message": "Smart Fridge API is running perfectly!"}
@app.get("/test-db")
def test_database_connection(db: Session = Depends(get_db)):
    try:
        # ลองสั่ง Query ง่ายๆ ไปที่ AWS RDS
        result = db.execute(text("SELECT version();")).fetchone()
        return {
            "status": "success",
            "message": "Connected to AWS RDS successfully!",
            "db_version": result[0]
        }
    except Exception as e:
        return {
            "status": "error",
            "message": "Failed to connect to AWS RDS",
            "error_detail": str(e)
        }

# Endpoint ที่ 2: ระบบแนะนำอาหารหลัก (Core Feature)
@app.post("/recommend", response_model=dict)
def recommend_recipes(request: FridgeRequest):
    # 1. จัดการคำศัพท์ของผู้ใช้
    raw_tokens = tokenize_ingredients(request.ingredients)
    user_tokens = bigram_model[raw_tokens] # เข้ากระบวนการจับคู่คำ (Bigram)
    
    # 2. แปลงเป็นตัวเลข (Vector)
    user_vec = get_recipe_vector(user_tokens, word2vec_model).reshape(1, -1)
    
    # ถ้าพิมพ์คำมั่วๆ ที่ AI ไม่รู้จักเลย
    if np.all(user_vec == 0):
        raise HTTPException(status_code=400, detail="AI ไม่รู้จักวัตถุดิบเหล่านี้ ลองเปลี่ยนคำดูนะครับ")
    
    # 3. คำนวณความเหมือน (Cosine Similarity)
    similarities = cosine_similarity(user_vec, recipe_vectors)[0]
    top_indices = similarities.argsort()[-request.top_k:][::-1]
    
    # 4. เตรียมข้อมูลส่งกลับให้ Mobile App
    results = []
    user_set = set(user_tokens) # ทำเป็น Set เพื่อไว้ลบหาของที่ขาด
    
    for idx in top_indices:
        row = df_api.iloc[idx]
        
        # ดึงวัตถุดิบของสูตรอาหารเมนูนี้
        recipe_ingr_list = row['ingredients']
        
        # แปลงวัตถุดิบสูตรอาหารให้เป็น token แบบเดียวกัน เพื่อใช้เปรียบเทียบหาของที่ขาด
        recipe_tokens = tokenize_ingredients(recipe_ingr_list)
        recipe_set = set(bigram_model[recipe_tokens])
        
        # ✨ Logic หาของที่มี vs ของที่ขาด (Set Theory)
        used = list(recipe_set.intersection(user_set))
        missing = list(recipe_set.difference(user_set))
        
        results.append({
            "name": row['name'],
            "category": row['category'],
            "match_score_percent": round(float(similarities[idx]) * 100, 2),
            "used_ingredients": used,
            "missing_ingredients": missing,
            "all_ingredients": recipe_ingr_list
        })
        
    return {"recommendations": results}