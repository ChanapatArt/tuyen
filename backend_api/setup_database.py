from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv

# โหลดค่าจากไฟล์ .env
load_dotenv(os.path.join("app", ".env"))
DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)

def create_all_tables():
    with engine.connect() as conn:
        print("กำลังล้างตารางเก่า (ถ้ามี)...")
        # ลบตารางเก่าทิ้งเพื่อสร้างใหม่ (CASCADE จะลบตารางที่เชื่อมกันอยู่ด้วย)
        conn.execute(text("DROP TABLE IF EXISTS favorites, reviews, shopping_lists, meal_plans, recipe_ingredients, fridge_items, ingredients, recipes, users CASCADE"))
        conn.commit()

        print("กำลังสร้างตารางใหม่ทั้ง 9 ตาราง...")

        # 1. ตารางผู้ใช้งาน (Users)
        conn.execute(text("""
            CREATE TABLE users (
                user_id SERIAL PRIMARY KEY,
                email VARCHAR(100) UNIQUE NOT NULL,
                password VARCHAR(255) NOT NULL,
                display_name VARCHAR(100),
                allergies TEXT,
                diet_type VARCHAR(50),
                targetCal INT
                          
            )
        """))

        # 2. ตารางสูตรอาหาร (Recipes)
        conn.execute(text("""
            CREATE TABLE recipes (
                recipe_id SERIAL PRIMARY KEY,
                title VARCHAR(200) NOT NULL,
                description TEXT,
                image_url TEXT,
                prep_time INT,
                calories INT
            )
        """))

        # 3. ตารางวัตถุดิบหลัก (Ingredients)
        conn.execute(text("""
            CREATE TABLE ingredients (
                ingredient_id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                category VARCHAR(150)
            )
        """))

        # 4. ตารางของในตู้เย็น (Fridge_Items)
        conn.execute(text("""
            CREATE TABLE fridge_items (
                fridge_id SERIAL PRIMARY KEY,
                user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
                ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
                quantity DECIMAL(10, 2),
                unit VARCHAR(20),
                expiry_date DATE
            )
        """))

        # 5. ตารางส่วนผสมของสูตรอาหาร (Recipe_Ingredients)
        conn.execute(text("""
            CREATE TABLE recipe_ingredients (
                recipe_ing_id SERIAL PRIMARY KEY,
                recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,
                ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
                quantity DECIMAL(10, 2),
                unit VARCHAR(80)
            )
        """))

        # 6. ตารางอาหาร (History)
        conn.execute(text("""
            CREATE TABLE history (
                history_id SERIAL PRIMARY KEY,
                user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
                recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,
                history_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                history_type VARCHAR(100)
            )
        """))

        # 7. ตารางรายการซื้อของ (Shopping_Lists)
        conn.execute(text("""
            CREATE TABLE shopping_lists (
                list_id SERIAL PRIMARY KEY,
                user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
                ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
                quantity DECIMAL(10, 2),
                unit VARCHAR(20),
                is_bought BOOLEAN DEFAULT FALSE
            )
        """))

        # 8. ตารางรีวิว (Reviews)
        conn.execute(text("""
            CREATE TABLE reviews (
                review_id SERIAL PRIMARY KEY,
                user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
                recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,
                rating INT CHECK (rating >= 1 AND rating <= 5),
                comment TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))

        # 9. ตารางเมนูโปรด (Favorites)
        conn.execute(text("""
            CREATE TABLE favorites (
                favorite_id SERIAL PRIMARY KEY,
                user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
                recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE
            )
        """))

        conn.commit()
        print("✅ สร้างตารางทั้ง 9 สำเร็จเรียบร้อยแล้ว!")

if __name__ == "__main__":
    create_all_tables()