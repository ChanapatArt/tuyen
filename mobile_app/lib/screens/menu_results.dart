import 'package:flutter/material.dart';
import 'package:mobile_app/screens/recipe_details.dart';

class MenuResultsScreen extends StatelessWidget {
  final VoidCallback onBack;
  const MenuResultsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // ปุ่มย้อนกลับแบบในรูปที่ 3
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Menu results",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "I found 4 menu items",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  RecipeCard(
                    title: "Minced pork omelet",
                    kcal: "test",
                    time: "12:00",
                    matchPercent: "100%",
                    imageColor: Colors.green,
                  ),
                  RecipeCard(
                    title: "Minced pork omelet",
                    kcal: "test",
                    time: "12:00",
                    matchPercent: "100%",
                    imageColor: Colors.grey.shade300,
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

class RecipeCard extends StatelessWidget {
  final String title, kcal, time, matchPercent;
  final Color imageColor;

  const RecipeCard({
    super.key,
    required this.title,
    required this.kcal,
    required this.time,
    required this.matchPercent,
    required this.imageColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(builder: (context) => RecipeDetails(title: title)),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // ส่วนรูปภาพ (ในรูปเป็นสีเขียวพื้นหลัง)
            Stack(
              children: [
                Container(height: 150, color: imageColor),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$matchPercent Match",
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ส่วนรายละเอียดใต้รูป
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 18,
                      ),
                      Text(" $kcal"),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        color: Colors.blue,
                        size: 18,
                      ),
                      Text(" $time"),
                    ],
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
