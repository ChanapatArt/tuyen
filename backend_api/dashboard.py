import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from wordcloud import WordCloud
from collections import Counter
import os

#streamlit run dashboard.py

# 1. ตั้งค่าหน้าเว็บให้กว้างเต็มจอ
st.set_page_config(page_title="Smart Fridge Analytics", page_icon="🍳", layout="wide")
st.title("🍳 Smart Fridge: Data Analytics Dashboard")
st.markdown("---")

# 2. ฟังก์ชันโหลดข้อมูล
@st.cache_data
def load_data():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    data_path = os.path.join(base_dir, 'data', 'cleaned_all_recipes.pkl')
    if os.path.exists(data_path):
        return pd.read_pickle(data_path)
    return None

df = load_data()

if df is not None:
    # ---------------------------------------------------------
    # เตรียมข้อมูลวัตถุดิบ (ดึง List ทั้งหมดมาต่อกันเพื่อทำ Bar Chart & Word Cloud)
    # ---------------------------------------------------------
    all_ingredients = [ing for sublist in df['ingredients'] for ing in sublist]
    
    # แบ่งหน้าจอเป็น 2 ฝั่ง (ซ้าย col1 / ขวา col2)
    col1, col2 = st.columns(2)
    
    with col1:
        # ==========================================
        # 📊 1. Recipe Overview (Pie Chart)
        # ==========================================
        st.subheader("1. สัดส่วนหมวดหมู่อาหาร (Recipe Categories)")
        category_counts = df['category'].value_counts()
        
        fig1, ax1 = plt.subplots(figsize=(8, 6))
        # ใช้สีแบบพาสเทลให้ดูน่ากิน
        colors = sns.color_palette('pastel')[0:len(category_counts)]
        ax1.pie(category_counts, labels=category_counts.index, autopct='%1.1f%%', 
                startangle=90, colors=colors, textprops={'fontsize': 10})
        ax1.axis('equal') # ทำให้กราฟกลมเป๊ะ
        st.pyplot(fig1)

        # ==========================================
        # 📈 3. Top Ingredients (Bar Chart)
        # ==========================================
        st.subheader("3. 10 อันดับวัตถุดิบยอดฮิต (Top Ingredients)")
        
        # นับคำและดึง 10 อันดับแรก
        top_10 = Counter(all_ingredients).most_common(10)
        top_10_df = pd.DataFrame(top_10, columns=['Ingredient', 'Count'])
        
        fig3, ax3 = plt.subplots(figsize=(8, 5))
        sns.barplot(data=top_10_df, x='Count', y='Ingredient', palette='viridis', ax=ax3)
        ax3.set_xlabel("จำนวนครั้งที่ถูกใช้ในสูตรอาหาร")
        ax3.set_ylabel("วัตถุดิบ")
        st.pyplot(fig3)

    with col2:
        # ==========================================
        # 📌 2. Nutrition Analytics (Scatter Plot)
        # ==========================================
        st.subheader("2. แคลอรี่ vs โปรตีน (Nutrition Analytics)")
        st.caption("จุดไหนอยู่บนซ้าย = แคลอรี่สูงแต่โปรตีนน้อย (กินแล้วอ้วนง่าย)")
        
        fig2, ax2 = plt.subplots(figsize=(8, 6))
        # วาดจุด scatter plot แยกสีตาม category
        sns.scatterplot(data=df, x='protein', y='calories', hue='category', 
                        alpha=0.6, s=50, palette='Set2', ax=ax2)
        
        ax2.set_xlabel('โปรตีน (% Daily Value)')
        ax2.set_ylabel('แคลอรี่ (kcal)')
        # ย้ายกล่อง legend ไปไว้นอกกราฟจะได้ไม่บังจุด
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
        st.pyplot(fig2)

        # ==========================================
        # ☁️ 4. Word Cloud (ก้อนเมฆคำศัพท์)
        # ==========================================
        st.subheader("4. ก้อนเมฆวัตถุดิบ (Ingredients Word Cloud)")
        
        # เอาคำทั้งหมดมาต่อกันเป็น String ยาวๆ ก้อนเดียว
        text = " ".join(all_ingredients)
        
        # สร้าง Word Cloud
        wordcloud = WordCloud(width=800, height=450, 
                              background_color='white', 
                              colormap='magma', 
                              max_words=100).generate(text)
        
        fig4, ax4 = plt.subplots(figsize=(8, 4.5))
        ax4.imshow(wordcloud, interpolation='bilinear')
        ax4.axis('off') # ปิดแกน X, Y ให้ดูเป็นรูปภาพ
        st.pyplot(fig4)

else:
    st.error("ไม่พบไฟล์ข้อมูล กรุณาเช็ค Path ของไฟล์ cleaned_all_recipes.pkl ครับ")