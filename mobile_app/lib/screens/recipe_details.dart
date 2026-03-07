import 'package:flutter/material.dart';
import 'package:mobile_app/screens/community_reviews.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class RecipeDetails extends StatefulWidget {
  final int recipeId;
  final String title;
  const RecipeDetails({super.key, required this.title, required this.recipeId});
  // const RecipeDetails({super.key, required this.title});
  @override
  State<RecipeDetails> createState() => _RecipeDetailsState();
}

class _RecipeDetailsState extends State<RecipeDetails> {
  Map<String, dynamic>? _recipeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/recipes/${widget.recipeId}/details'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _recipeData = responseData['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching details: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // ✅ เช็คสถานะการโหลด: ถ้ากำลังโหลดให้แสดงวงกลมหมุน
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF28B446)),
              )
            : _recipeData == null
            ? const Center(child: Text("Recipe details not found."))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header: ปุ่มย้อนกลับ ชื่อเมนู และระดับความยาก
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.arrow_back, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recipeData!['title'] ??
                                widget.title, // ✅ ดึงชื่อจาก API
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FAF0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Easy", // หรือสามารถเพิ่ม Field difficulty ใน API ได้
                            style: TextStyle(
                              color: Color(0xFF28B446),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Summary Card: ข้อมูล Calories, Match % และเวลาที่ใช้
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            "${_recipeData!['calories'] ?? 0}",
                            "Kcal",
                          ), // ✅
                          _buildVerticalDivider(),
                          _buildStatItem("100%", "Match"),
                          _buildVerticalDivider(),
                          _buildStatItem(
                            "${_recipeData!['prep_time'] ?? 0}",
                            "นาที",
                          ), // ✅
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Section: รายการวัตถุดิบ (Ingredients)
                    const Text(
                      "Ingredients required",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF28B446),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Required ingredients list",
                                style: TextStyle(
                                  color: Color(0xFF28B446),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_recipeData!['ingredients'] as List).join(
                              ", ",
                            ), // ✅ แปลง List เป็นข้อความ
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 4. Section: ขั้นตอนการทำ (Steps)
                    const Text(
                      "How to do it",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ✅ วนลูปแสดงขั้นตอนตามจำนวนที่มีใน API
                    ...(_recipeData!['steps'] as List).asMap().entries.map((
                      entry,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${entry.key + 1}. ",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 40),

                    // 5. ปุ่ม Read reviews
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommunityReviews(recipeId: _recipeData!['recipe_id']),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.chat_bubble,
                          color: Color(0xFF28B446),
                        ),
                        label: const Text("Read reviews"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // Helper สำหรับสร้างช่องตัวเลข
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  // Helper สำหรับสร้างเส้นคั่นแนวตั้ง
  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade300);
  }
}
