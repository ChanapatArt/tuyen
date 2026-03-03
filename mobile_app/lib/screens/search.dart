import 'package:flutter/material.dart';
import 'package:mobile_app/screens/recipeDetails.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. หัวข้อ Search menu
              const Row(
                children: [
                  Text(
                    "Search menu",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.search, size: 28),
                ],
              ),
              const SizedBox(height: 16),

              // 2. ช่อง Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: "Type the name of the menu item or ingredient...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. หมวดหมู่ (Tags)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag("Thai food"),
                  _buildTag("Clean"),
                  _buildTag("Easy to do"),
                  _buildTag("Dessert"),
                  _buildTag("High protein"),
                  _buildTag("Vegetarian food"),
                ],
              ),
              const SizedBox(height: 24),

              // 4. ส่วน Popular menu
              const Text(
                "Popular menu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 5. รายการเมนูแบบ Grid
              GridView.builder(
                shrinkWrap: true, // สำคัญ: เพื่อให้ใช้ใน ScrollView ได้
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // แบ่ง 2 คอลัมน์
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85, // ปรับสัดส่วนความสูงของการ์ด
                ),
                itemCount: 6, // จำนวนรายการสมมติ
                itemBuilder: (context, index) {
                  return _buildPopularCard(
                    context,
                    index == 0 ? "Minced pork omelet" : "Chicken Salad",
                    index == 0 ? "350 kcal" : "250 kcal",
                    index == 0 ? Colors.green : Colors.grey.shade300,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง Tag หมวดหมู่
  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
      ),
    );
  }

  // ฟังก์ชันสร้างการ์ดเมนูยอดนิยม
  Widget _buildPopularCard(BuildContext context, String title, String kcal, Color color) {
    return GestureDetector(
      onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetails(title: title),
        ),
      );
    },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนรูปภาพสมมติ
            Expanded(
              child: Container(color: color),
            ),
            // ส่วนรายละเอียด
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    kcal,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}