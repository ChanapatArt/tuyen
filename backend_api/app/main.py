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
from datetime import date
from datetime import datetime

#uvicorn app.main:app --reload
#http://127.0.0.1:8000/docs#/


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

class UserLoginSchema(BaseModel):
    email: str
    password: str

class FridgeItemAddSchema(BaseModel):
    user_id: int
    ingredient_name: str
    quantity: Optional[float] = 1.0
    unit: Optional[str] = "ชิ้น"
    expiry_date: Optional[date] = None

class HistoryAddSchema(BaseModel):
    user_id: int
    recipe_id: int
    history_date: Optional[datetime] = None  # ถ้าไม่ส่งมา จะใช้วันเวลาปัจจุบัน
    history_type: str  # เช่น "Breakfast", "Lunch", "Dinner"

class ReviewAddSchema(BaseModel):
    user_id: int
    recipe_id: int
    rating: int # 1 ถึง 5
    comment: Optional[str] = None
class ShoppingListAddSchema(BaseModel):
    user_id: int
    ingredient_name: str
    quantity: float
    unit: str
class AllergyAddSchema(BaseModel):
    allergy_name: str

class DietTypeAddSchema(BaseModel):
    diet_name: str

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
        # ตัด allergies และ diet_type ออกทั้งใน INSERT และ VALUES
        conn.execute(
            text("""
                INSERT INTO users (email, password, display_name) 
                VALUES (:e, :p, :d)
            """), 
            {
                "e": user.email, "p": hashed_pw, "d": user.display_name
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
        


# ==========================================
# ❄️ 5. API จัดการของในตู้เย็น (Fridge)
# ==========================================
@app.post("/fridge/add")
def add_fridge_item(item: FridgeItemAddSchema):
    with engine.connect() as conn:
        # 1. เช็คว่ามีวัตถุดิบนี้ในตาราง ingredients หรือยัง (ถ้ายังให้เพิ่มใหม่)
        ing_result = conn.execute(text("SELECT ingredient_id FROM ingredients WHERE name = :n"), {"n": item.ingredient_name}).fetchone()
        
        if ing_result:
            ing_id = ing_result[0]
        else:
            # ถ้ายังไม่มี ให้ Insert แล้วดึง ID กลับมา (ใช้ RETURNING)
            new_ing = conn.execute(text("INSERT INTO ingredients (name) VALUES (:n) RETURNING ingredient_id"), {"n": item.ingredient_name}).fetchone()
            ing_id = new_ing[0]

        # 2. เพิ่มเข้าตู้เย็น
        conn.execute(
            text("""
                INSERT INTO fridge_items (user_id, ingredient_id, quantity, unit, expiry_date) 
                VALUES (:u, :i, :q, :un, :e)
            """), 
            {"u": item.user_id, "i": ing_id, "q": item.quantity, "un": item.unit, "e": item.expiry_date}
        )
        conn.commit()
        return {"status": "success", "message": f"เพิ่ม {item.ingredient_name} เข้าตู้เย็นแล้ว!"}

@app.delete("/fridge/remove/{fridge_id}")
def remove_fridge_item(fridge_id: int):
    with engine.connect() as conn:
        conn.execute(text("DELETE FROM fridge_items WHERE fridge_id = :f"), {"f": fridge_id})
        conn.commit()
        return {"status": "success", "message": "ลบของออกจากตู้เย็นแล้ว!"}

# ==========================================
# 🕒 API จัดการประวัติทำอาหาร (History)
# ==========================================
@app.post("/history/add")
def add_history(history: HistoryAddSchema):
    # ถ้าไม่ระบุเวลามา ให้ใช้เวลาปัจจุบันของเซิร์ฟเวอร์
    h_date = history.history_date if history.history_date else datetime.now()
    
    with engine.connect() as conn:
        conn.execute(
            text("""
                INSERT INTO history (user_id, recipe_id, history_date, history_type) 
                VALUES (:u, :r, :d, :t)
            """), 
            {"u": history.user_id, "r": history.recipe_id, "d": h_date, "t": history.history_type}
        )
        conn.commit()
        return {"status": "success", "message": "บันทึกประวัติการทำอาหารเรียบร้อย!"}

@app.delete("/history/remove/{history_id}")
def remove_history(history_id: int):
    with engine.connect() as conn:
        conn.execute(text("DELETE FROM history WHERE history_id = :h"), {"h": history_id})
        conn.commit()
        return {"status": "success", "message": "ลบประวัติแล้ว!"}

@app.get("/history/{user_id}")
def get_user_history(user_id: int):
    with engine.connect() as conn:
        # ดึงประวัติ พร้อมจอย (JOIN) กับตาราง recipes เพื่อเอาชื่อเมนูมาโชว์ด้วย
        result = conn.execute(
            text("""
                SELECT h.history_id, h.history_date, h.history_type, r.recipe_id, r.title 
                FROM history h
                JOIN recipes r ON h.recipe_id = r.recipe_id
                WHERE h.user_id = :u
                ORDER BY h.history_date DESC
            """), 
            {"u": user_id}
        ).fetchall()
        
        # แปลงข้อมูลให้อ่านง่ายสำหรับ Mobile App
        history_list = []
        for row in result:
            history_list.append({
                "history_id": row[0],
                "history_date": row[1].strftime("%Y-%m-%d %H:%M:%S"),
                "history_type": row[2],
                "recipe_id": row[3],
                "recipe_title": row[4]
            })
            
        return {"status": "success", "total": len(history_list), "data": history_list}

# ==========================================
# ⭐ 7. API จัดการรีวิว (Review)
# ==========================================
@app.post("/review/add")
def add_review(review: ReviewAddSchema):
    if review.rating < 1 or review.rating > 5:
        return {"status": "error", "message": "คะแนนต้องอยู่ระหว่าง 1 ถึง 5 เท่านั้น"}
        
    with engine.connect() as conn:
        conn.execute(
            text("""
                INSERT INTO reviews (user_id, recipe_id, rating, comment) 
                VALUES (:u, :r, :rt, :c)
            """), 
            {"u": review.user_id, "r": review.recipe_id, "rt": review.rating, "c": review.comment}
        )
        conn.commit()
        return {"status": "success", "message": "ขอบคุณสำหรับรีวิวครับ!"}

@app.delete("/review/remove/{review_id}")
def remove_review(review_id: int):
    with engine.connect() as conn:
        conn.execute(text("DELETE FROM reviews WHERE review_id = :r"), {"r": review_id})
        conn.commit()
        return {"status": "success", "message": "ลบรีวิวเรียบร้อยแล้ว!"}

# ==========================================
# 🔍 API สำหรับหน้า Search Menu
# ==========================================
@app.get("/recipes/search")
def search_recipes(q: str, limit: int = 20):
    
    if not q or len(q.strip()) == 0:
        return {"status": "success", "total": 0, "data": []}

    with engine.connect() as conn:
        # ใช้ ILIKE เพื่อค้นหาแบบไม่สนตัวพิมพ์เล็ก/ใหญ่ และใส่ % หน้าหลังเพื่อหาคำที่ซ่อนอยู่ข้างใน
        search_query = f"%{q.strip()}%"
        
        result = conn.execute(
            text("""
                SELECT recipe_id, title, calories, prep_time, image_url 
                FROM recipes 
                WHERE title ILIKE :sq 
                LIMIT :lim
            """), 
            {"sq": search_query, "lim": limit}
        ).fetchall()
        
        # จัดฟอร์แมตข้อมูลให้ตรงกับที่ Mobile App ต้องการ (มี title และ calories)
        recipes_list = []
        for row in result:
            recipes_list.append({
                "recipe_id": row[0],
                "title": row[1],
                "calories": row[2],
                "prep_time": row[3],
                "image_url": row[4]
            })
            
        return {"status": "success", "total": len(recipes_list), "data": recipes_list}

# ==========================================
# 🕒 API สำหรับหน้า Histories (ดูตามวันที่)
# ==========================================
@app.get("/history/{user_id}/by-date")
def get_history_by_date(user_id: int, target_date: date):
    """
    ดึงข้อมูลประวัติการทำอาหารของวันที่ผู้ใช้เลือกในปฏิทิน
    - user_id: รหัสผู้ใช้
    - target_date: วันที่ต้องการดู (รูปแบบ YYYY-MM-DD เช่น 2026-03-18)
    """
    with engine.connect() as conn:
        # ใช้คำสั่ง DATE() ของ PostgreSQL เพื่อตัดเวลาออก เอาแค่วันที่มาเทียบกัน
        result = conn.execute(
            text("""
                SELECT h.history_id, h.history_date, h.history_type, r.recipe_id, r.title, r.calories, r.image_url
                FROM history h
                JOIN recipes r ON h.recipe_id = r.recipe_id
                WHERE h.user_id = :u AND DATE(h.history_date) = :d
                ORDER BY h.history_date DESC
            """), 
            {"u": user_id, "d": target_date}
        ).fetchall()
        
        # จัดฟอร์แมตข้อมูลให้ Mobile App เอาไปแสดงผล (ต้องมี title กับ calories ตาม UI)
        history_list = []
        for row in result:
            history_list.append({
                "history_id": row[0],
                "history_date": row[1].strftime("%Y-%m-%d %H:%M:%S"),
                "history_type": row[2],
                "recipe_id": row[3],
                "title": row[4],         # ชื่อเมนู
                "calories": row[5],      # แคลอรี (ตามดีไซน์ในการ์ด)
                "image_url": row[6]      # รูปภาพ (เผื่ออนาคตจะเอารูปมาใส่กรอบสี่เหลี่ยมซ้ายมือ)
            })
            
        return {
            "status": "success", 
            "target_date": str(target_date), 
            "total": len(history_list), 
            "data": history_list
        }
# ==========================================
# 📖 API สำหรับหน้า รายละเอียดเมนู (Recipe Details)
# ==========================================
@app.get("/recipes/{recipe_id}/details")
def get_recipe_details(recipe_id: int):
    """
    ดึงข้อมูลรายละเอียดสูตรอาหาร (แคลอรี, เวลาทำ, วัตถุดิบ, และวิธีทำ)
    - recipe_id: รหัสเมนู (ดึงมาจากหน้า Search หรือ Histories)
    """
    with engine.connect() as conn:
        # 1. ดึงข้อมูลหลักจากตาราง recipes
        recipe = conn.execute(
            text("""
                SELECT title, calories, prep_time, description, image_url 
                FROM recipes 
                WHERE recipe_id = :r
            """), 
            {"r": recipe_id}
        ).fetchone()
        
        if not recipe:
            return {"status": "error", "message": "ไม่พบข้อมูลสูตรอาหารนี้"}
            
        title = recipe[0]
        calories = recipe[1]
        prep_time = recipe[2]
        description = recipe[3]
        
        # 2. แปลง How to do it (description) จากข้อความให้กลายเป็น List (Array)
        import ast
        steps = []
        if description:
            try:
                # แปลง "['step 1', 'step 2']" ให้เป็น List จริงๆ เพื่อให้ Mobile เอาไปทำข้อ 1. 2. 3. ได้ง่าย
                steps = ast.literal_eval(description)
            except:
                steps = [description]
                
        # 3. ดึง Ingredients จาก AI Dataset (เพื่อความแม่นยำ)
        recipe_ingredients = []
        try:
            ai_row = df_api[df_api['name'].str.lower() == title.lower()]
            if not ai_row.empty:
                recipe_ingredients = ai_row.iloc[0]['ingredients']
                if isinstance(recipe_ingredients, str):
                    recipe_ingredients = ast.literal_eval(recipe_ingredients)
        except:
            pass

        return {
            "status": "success",
            "data": {
                "recipe_id": recipe_id,
                "title": title,                 # ชื่อเมนู
                "calories": calories,           # แคลอรี
                "prep_time": prep_time,         # เวลาเตรียม (นาที)
                "ingredients": recipe_ingredients, # วัตถุดิบทั้งหมดที่ต้องใช้
                "steps": steps                  # How to do it (วิธีทำ)
            }
        }
# ==========================================
# 🛒 API สำหรับหน้า Shopping List (Cart)
# ==========================================
@app.post("/shopping-list/add")
def add_shopping_list_item(item: ShoppingListAddSchema):
    """
    เพิ่มรายการวัตถุดิบลงใน Shopping List (หน้า Cart)
    """
    with engine.connect() as conn:
        # 1. เช็คว่ามีวัตถุดิบนี้ในตาราง ingredients หรือยัง (ค้นหาแบบไม่สนพิมพ์เล็ก/ใหญ่)
        ing_result = conn.execute(
            text("SELECT ingredient_id FROM ingredients WHERE name ILIKE :n"), 
            {"n": item.ingredient_name}
        ).fetchone()
        
        if ing_result:
            ing_id = ing_result[0]
        else:
            # ถ้ายังไม่มี ให้เพิ่มใหม่และดึง ID กลับมา
            new_ing = conn.execute(
                text("INSERT INTO ingredients (name) VALUES (:n) RETURNING ingredient_id"), 
                {"n": item.ingredient_name}
            ).fetchone()
            ing_id = new_ing[0]

        # 2. เพิ่มลงตาราง shopping_lists
        conn.execute(
            text("""
                INSERT INTO shopping_lists (user_id, ingredient_id, quantity, unit) 
                VALUES (:u, :i, :q, :un)
            """), 
            {
                "u": item.user_id, 
                "i": ing_id, 
                "q": item.quantity, 
                "un": item.unit
            }
        )
        conn.commit()
        return {"status": "success", "message": f"เพิ่ม {item.ingredient_name} ลงในตะกร้าแล้ว!"}

@app.get("/shopping-list/{user_id}")
def get_shopping_list(user_id: int):
    """
    ดึงข้อมูล Shopping List ของผู้ใช้ไปแสดงผล
    """
    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT s.list_id, i.name, s.quantity, s.unit, s.is_bought 
                FROM shopping_lists s
                JOIN ingredients i ON s.ingredient_id = i.ingredient_id
                WHERE s.user_id = :u
                ORDER BY s.list_id DESC
            """), 
            {"u": user_id}
        ).fetchall()
        
        shopping_list = []
        for row in result:
            shopping_list.append({
                "list_id": row[0],
                "ingredient_name": row[1],
                "quantity": float(row[2]) if row[2] else 0, # ป้องกันค่า Null
                "unit": row[3],
                "is_bought": row[4] # เอาไว้เช็คว่าผู้ใช้กดติ๊กถูก (ซื้อแล้ว) หรือยัง
            })
            
        return {"status": "success", "total": len(shopping_list), "data": shopping_list}

@app.delete("/shopping-list/remove/{list_id}")
def remove_shopping_list_item(list_id: int):
    """
    ลบรายการออกจาก Shopping List
    """
    with engine.connect() as conn:
        conn.execute(text("DELETE FROM shopping_lists WHERE list_id = :l"), {"l": list_id})
        conn.commit()
        return {"status": "success", "message": "ลบรายการเรียบร้อยแล้ว!"}
# ==========================================
# ⚙️ API สำหรับหน้า Personal Information
# ==========================================

# 1. API ดึงข้อมูลโปรไฟล์ไปแสดงผล
@app.get("/user/{user_id}/profile")
def get_user_profile(user_id: int):
    """
    ดึงข้อมูลโปรไฟล์ผู้ใช้ รวมถึงรายการแพ้อาหารและรูปแบบการกิน
    """
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT display_name, allergies, diet_type FROM users WHERE user_id = :u"),
            {"u": user_id}
        ).fetchone()
        
        if not result:
            return {"status": "error", "message": "ไม่พบผู้ใช้งานนี้"}
            
        # หั่นคำที่คั่นด้วยลูกน้ำ (,) ให้กลายเป็น List เพื่อให้ Mobile นำไปโชว์ทีละกล่องได้ง่าย
        allergies_list = [a.strip() for a in result[1].split(",")] if result[1] else []
        diet_list = [d.strip() for d in result[2].split(",")] if result[2] else []
            
        return {
            "status": "success",
            "data": {
                "display_name": result[0],
                "allergies": allergies_list,
                "diet_types": diet_list
            }
        }

# 2. API เพิ่มรายการแพ้อาหาร (Food Allergies)
@app.post("/user/{user_id}/allergies/add")
def add_user_allergy(user_id: int, payload: AllergyAddSchema):
    with engine.connect() as conn:
        curr = conn.execute(text("SELECT allergies FROM users WHERE user_id = :u"), {"u": user_id}).fetchone()
        
        current_allergies = curr[0] if curr and curr[0] else ""
        
        # ถ่ายข้อมูลเดิมมาต่อด้วยของใหม่ (ถ้ายังไม่มีของเดิมก็ใส่ของใหม่เลย)
        if current_allergies:
            # ป้องกันการเพิ่มข้อมูลซ้ำ
            if payload.allergy_name.lower() not in current_allergies.lower():
                new_allergies = f"{current_allergies}, {payload.allergy_name}"
            else:
                new_allergies = current_allergies
        else:
            new_allergies = payload.allergy_name

        conn.execute(
            text("UPDATE users SET allergies = :a WHERE user_id = :u"),
            {"a": new_allergies, "u": user_id}
        )
        conn.commit()
        return {"status": "success", "message": "เพิ่มประวัติแพ้อาหารเรียบร้อย", "updated_allergies": new_allergies}

# 3. API เพิ่มรูปแบบการกิน (Diet Type)
@app.post("/user/{user_id}/diet-type/add")
def add_user_diet(user_id: int, payload: DietTypeAddSchema):
    with engine.connect() as conn:
        curr = conn.execute(text("SELECT diet_type FROM users WHERE user_id = :u"), {"u": user_id}).fetchone()
        
        current_diet = curr[0] if curr and curr[0] else ""
        
        if current_diet:
            if payload.diet_name.lower() not in current_diet.lower():
                new_diet = f"{current_diet}, {payload.diet_name}"
            else:
                new_diet = current_diet
        else:
            new_diet = payload.diet_name

        conn.execute(
            text("UPDATE users SET diet_type = :d WHERE user_id = :u"),
            {"d": new_diet, "u": user_id}
        )
        conn.commit()
        return {"status": "success", "message": "เพิ่มรูปแบบการกินเรียบร้อย", "updated_diet_types": new_diet}
# ==========================================
# ⚙️ ตรวจสอบและอัปเดตฐานข้อมูล (Auto-Patch)
# ==========================================
# สั่งให้ระบบสร้างคอลัมน์ target_cal อัตโนมัติ (ถ้ายังไม่มี)
try:
    with engine.connect() as conn:
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS target_cal INT;"))
        conn.commit()
except Exception as e:
    print(f"DB Patch Note: {e}")

# ==========================================
# 📝 Pydantic Schema สำหรับอัปเดตโปรไฟล์
# ==========================================
class UserEditProfileSchema(BaseModel):
    email: Optional[str] = None
    display_name: Optional[str] = None
    password: Optional[str] = None
    target_cal: Optional[int] = None

# ==========================================
# 👤 API สำหรับแก้ไขข้อมูลบัญชีผู้ใช้
# ==========================================
@app.put("/user/{user_id}/edit")
def edit_user_profile(user_id: int, payload: UserEditProfileSchema):
    """
    อัปเดตข้อมูลผู้ใช้ (Email, Name, Password, Target Calories)
    - สามารถส่งมาแค่บางฟิลด์ได้ ฟิลด์ไหนไม่ส่งมาจะไม่ถูกแก้ไข
    - หากเป็นวันถัดไป ต้องการแก้ไข Target ก็สามารถยิงมาอัปเดตใหม่ได้เลย
    """
    updates = []
    params = {"u": user_id}

    # 1. ตรวจสอบว่าต้องการอัปเดต Email ไหม
    if payload.email:
        updates.append("email = :e")
        params["e"] = payload.email
        
    # 2. ตรวจสอบว่าต้องการอัปเดต ชื่อ (Name) ไหม
    if payload.display_name:
        updates.append("display_name = :d")
        params["d"] = payload.display_name
        
    # 3. ตรวจสอบว่าต้องการอัปเดต รหัสผ่าน ไหม
    if payload.password and len(payload.password.strip()) > 0:
        hashed_pw = pwd_context.hash(payload.password)
        updates.append("password = :p")
        params["p"] = hashed_pw
        
    # 4. ตรวจสอบว่าต้องการอัปเดต เป้าหมายแคลอรี ไหม (รองรับการใส่ 0 หรือค่าใหม่)
    if payload.target_cal is not None:
        updates.append("target_cal = :t")
        params["t"] = payload.target_cal

    # ถ้าไม่มีอะไรส่งมาให้แก้เลย
    if not updates:
        return {"status": "error", "message": "ไม่มีข้อมูลให้แก้ไข"}

    # สร้างคำสั่ง SQL แบบไดนามิก (อัปเดตเฉพาะช่องที่มีข้อมูล)
    update_query = f"UPDATE users SET {', '.join(updates)} WHERE user_id = :u"

    with engine.connect() as conn:
        # เช็คก่อนว่า Email ใหม่ที่ตั้ง แอบไปซ้ำกับคนอื่นในระบบไหม
        if payload.email:
            check_email = conn.execute(
                text("SELECT user_id FROM users WHERE email = :e AND user_id != :u"), 
                {"e": payload.email, "u": user_id}
            ).fetchone()
            if check_email:
                return {"status": "error", "message": "Email นี้ถูกใช้งานโดยบัญชีอื่นแล้ว"}

        # บันทึกข้อมูลลงฐานข้อมูล
        conn.execute(text(update_query), params)
        conn.commit()

    return {"status": "success", "message": "อัปเดตข้อมูลโปรไฟล์เรียบร้อยแล้ว!"}