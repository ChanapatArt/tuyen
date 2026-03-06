from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import joblib
import numpy as np
import re
from sklearn.metrics.pairwise import cosine_similarity
import os
from sqlalchemy.orm import Session
from sqlalchemy import text
from .database import get_db, engine
from passlib.context import CryptContext

# ==========================================
# 1. ตั้งค่า API และโหลด AI Models
# ==========================================
app = FastAPI(title="Smart Fridge API", description="AI Recipe Recommendation & User System")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "../models")

print("กำลังอุ่นเครื่อง AI Models...")
try:
    word2vec_model = joblib.load(os.path.join(MODELS_DIR, 'word2vec_model.joblib'))
    recipe_vectors = joblib.load(os.path.join(MODELS_DIR, 'recipe_vectors.joblib'))
    bigram_model = joblib.load(os.path.join(MODELS_DIR, 'bigram_model.joblib'))
    df_api = joblib.load(os.path.join(MODELS_DIR, 'df_for_api.joblib'))
    print("✅ AI พร้อมรับออเดอร์แล้ว!")
except Exception as e:
    print(f"❌ โหลด AI ไม่สำเร็จ: {e}")

# เครื่องมือเข้ารหัสผ่าน
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ==========================================
# 2. Pydantic Models (หน้าตาข้อมูล รับ/ส่ง)
# ==========================================
# สำหรับ AI แนะนำอาหาร
class FridgeRequest(BaseModel):
    ingredients: List[str]
    top_k: int = 5

class RecipeResult(BaseModel):
    name: str
    category: str
    match_score_percent: float
    used_ingredients: List[str]
    missing_ingredients: List[str]
    all_ingredients: List[str]

# สำหรับ User Login / Register (โครงสร้าง DB ใหม่)
class UserRegisterSchema(BaseModel):
    email: str
    password: str
    display_name: str
    allergies: Optional[str] = None
    diet_type: Optional[str] = None

class UserLoginSchema(BaseModel):
    email: str
    password: str

# ==========================================
# 3. Helper Functions (ฟังก์ชันช่วยประมวลผล)
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
# 4. API Endpoints (ช่องทางติดต่อ)
# ==========================================

# 4.1 Health Check (เช็คสถานะเซิร์ฟเวอร์)
@app.get("/")
def read_root():
    return {"status": "ok", "message": "Smart Fridge API is running perfectly!"}

# 4.2 DB Connection Check (เช็คฐานข้อมูล)
@app.get("/test-db")
def test_database_connection(db: Session = Depends(get_db)):
    try:
        result = db.execute(text("SELECT version();")).fetchone()
        return {"status": "success", "message": "Connected to AWS RDS successfully!", "db_version": result[0]}
    except Exception as e:
        return {"status": "error", "message": "Failed to connect to AWS RDS", "error_detail": str(e)}

# 4.3 AI แนะนำอาหาร
@app.post("/recommend", response_model=dict)
def recommend_recipes(request: FridgeRequest):
    raw_tokens = tokenize_ingredients(request.ingredients)
    user_tokens = bigram_model[raw_tokens]
    user_vec = get_recipe_vector(user_tokens, word2vec_model).reshape(1, -1)
    
    if np.all(user_vec == 0):
        raise HTTPException(status_code=400, detail="AI ไม่รู้จักวัตถุดิบเหล่านี้ ลองเปลี่ยนคำดูนะครับ")
    
    similarities = cosine_similarity(user_vec, recipe_vectors)[0]
    top_indices = similarities.argsort()[-request.top_k:][::-1]
    
    results = []
    user_set = set(user_tokens)
    
    for idx in top_indices:
        row = df_api.iloc[idx]
        recipe_ingr_list = row['ingredients']
        
        # ป้องกันบั๊ก String
        if isinstance(recipe_ingr_list, str):
            try:
                import ast
                recipe_ingr_list = ast.literal_eval(recipe_ingr_list)
            except:
                recipe_ingr_list = [recipe_ingr_list]

        recipe_tokens = tokenize_ingredients(recipe_ingr_list)
        recipe_set = set(bigram_model[recipe_tokens])
        
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

# 4.4 สมัครสมาชิก (Register)
@app.post("/register")
def register(user: UserRegisterSchema):
    with engine.connect() as conn:
        result = conn.execute(text("SELECT email FROM users WHERE email = :e"), {"e": user.email}).fetchone()
        if result:
            return {"status": "error", "message": "มี Email นี้ในระบบแล้ว"}
        
        hashed_pw = pwd_context.hash(user.password)
        conn.execute(
            text("""
                INSERT INTO users (email, password, display_name, allergies, diet_type) 
                VALUES (:e, :p, :d, :a, :dt)
            """), 
            {
                "e": user.email, "p": hashed_pw, "d": user.display_name,
                "a": user.allergies, "dt": user.diet_type
            }
        )
        conn.commit()
        return {"status": "success", "message": "สมัครสมาชิกสำเร็จ!"}

# 4.5 เข้าสู่ระบบ (Login)
@app.post("/login")
def login(user: UserLoginSchema):
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT password, display_name, user_id FROM users WHERE email = :e"), 
            {"e": user.email}
        ).fetchone()
        
        if not result:
            return {"status": "error", "message": "ไม่พบ Email นี้ในระบบ"}
        
        if pwd_context.verify(user.password, result[0]):
            return {
                "status": "success", "message": "เข้าสู่ระบบสำเร็จ!", 
                "user_id": result[2], "email": user.email, "display_name": result[1]
            }
        else:
            return {"status": "error", "message": "รหัสผ่านไม่ถูกต้อง"}