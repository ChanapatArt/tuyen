import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/screens/recipe_details.dart';

class MenuResultsScreen extends StatefulWidget {
  final List<String> ingredients; // รับค่ารายชื่อวัตถุดิบ
  final VoidCallback onBack;

  const MenuResultsScreen({
    super.key,
    required this.ingredients,
    required this.onBack,
  });

  @override
  State<MenuResultsScreen> createState() => _MenuResultsScreenState();
}

class _MenuResultsScreenState extends State<MenuResultsScreen> {
  List<dynamic> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations(); // ดึงข้อมูลทันทีเมื่อเปิดหน้า
  }

  Future<void> _fetchRecommendations() async {
    if (widget.ingredients.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "ingredients":
              widget.ingredients, // ✅ ข้อมูลจากหน้าตู้เย็นมาถึงนี่แล้ว!
          "top_k": 10,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _recommendations = responseData['recommendations'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching recommendations: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- ส่วน Header ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Menu results",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isLoading
                            ? "Searching..."
                            : "I found ${_recommendations.length} menu items",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- ส่วนแสดงผล Card ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    )
                  : _recommendations.isEmpty
                  ? const Center(child: Text("No recipes found."))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _recommendations.length,
                      itemBuilder: (context, index) {
                        final item = _recommendations[index];
                        return RecipeCard(
                          title: item['name'],
                          kcal: item['category'], // แสดงหมวดหมู่แทน
                          time:
                              "${item['used_ingredients'].length} used", // แสดงจำนวนที่ใช้
                          matchPercent:
                              "${item['match_score_percent'].toStringAsFixed(0)}%",
                          imageColor: Colors.grey.shade100,
                          recipeId:
                              0, // สุรเดชต้องดูว่า API ส่ง ID มาไหมเพื่อใช้กดเข้าไปดูรายละเอียด
                        );
                      },
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
  final int recipeId;
  final Color imageColor;

  const RecipeCard({
    super.key,
    required this.title,
    required this.kcal,
    required this.time,
    required this.matchPercent,
    required this.imageColor,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetails(title: title, matchPercent: matchPercent),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2, // เพิ่มเงาเล็กน้อยให้ดูมีมิติ
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            // ✅ เปลี่ยนเป็น Row เพื่อจัดวางแนวนอน
            children: [
              // 1. ส่วนข้อมูลด้านซ้าย (ชื่อ และ รายละเอียด)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                          size: 20,
                        ),
                        Text(
                          " $kcal",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          color: Colors.blue,
                          size: 20,
                        ),
                        Text(
                          " $time",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. ส่วน Match ด้านขวา (ป้ายกำกับ 100% Match)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ), // เส้นขอบบางๆ
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
            ],
          ),
        ),
      ),
    );  
  }
}
