import 'package:flutter/material.dart';

class RecipeDetails extends StatelessWidget {
  final String title;
  const RecipeDetails({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: ชื่อเมนู และป้ายระดับความยาก
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FAF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Easy",
                    style: TextStyle(color: Color(0xFF28B446), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Summary Card: ตัวเลข 3 ช่อง
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem("350", "Kcal"),
                  _buildVerticalDivider(),
                  _buildStatItem("100%", "Ingredients"),
                  _buildVerticalDivider(),
                  _buildStatItem("10", "นาที"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Section: Ingredients required
            const Text(
              "Ingredients required",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FAF0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB2E7C6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF28B446), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "It's already in the refrigerator.",
                        style: TextStyle(color: Color(0xFF28B446), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Chicken eggs, minced pork, fish sauce",
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 4. Section: How to do it
            const Text(
              "How to do it",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // รายการขั้นตอน (ใช้ List.generate เพื่อความง่าย)
            ...List.generate(6, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "${index + 1}. TEXT",
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            )),
            
            const SizedBox(height: 40),

            // 5. ปุ่ม Read reviews
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble, color: Color(0xFF28B446)),
                label: const Text("Read reviews"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper สำหรับสร้างช่องตัวเลข
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // Helper สำหรับสร้างเส้นคั่นแนวตั้ง
  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }
}