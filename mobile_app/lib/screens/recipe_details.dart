import 'package:flutter/material.dart';
import 'package:mobile_app/screens/community_reviews.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class RecipeDetails extends StatefulWidget {
  final String title;
  final String? matchPercent;
  const RecipeDetails({super.key, required this.title, this.matchPercent});
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
        Uri.parse(
          '${AuthService.baseUrl}/recipesbyname/${widget.title}/details',
        ),
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
    bool isFromMenu = widget.matchPercent != null;
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
                          _buildStatItem(
                            isFromMenu ? "100%" : "-",
                            "Ingredients",
                          ),
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
                    Row(
                      children: [
                        // ✅ ถ้ามาจาก Menu Result ให้โชว์ปุ่ม Let's Cook
                        if (isFromMenu) ...[
                          Expanded(
                            child: _buildActionButton(
                              label: "Let's Cook",
                              icon: Icons.restaurant_menu,
                              iconColor: Colors.white,
                              color: const Color(0xFF12B347),
                              onTap: () async {
                                // 1. แสดง Dialog ยืนยันการทำอาหาร
                                bool confirm =
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        title: const Text(
                                          "Confirm Cooking",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          "Do you want to start cooking ${widget.title}?",
                                        ),
                                        actions: [
                                          Row(
                                            children: [
                                              // ✅ ปุ่มยกเลิก (สีแดง)
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(
                                                      0xFFF41F11,
                                                    ), // สีแดงเดียวกับปุ่ม Cancel
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // ✅ ปุ่มยืนยัน (สีเขียว)
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(
                                                      0xFF28B446,
                                                    ), // สีเขียวเดียวกับปุ่ม OK
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Confirm",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;

                                if (confirm) {
                                  // 2. ดึงข้อมูล User และเตรียมข้อมูลส่ง API
                                  String? userId =
                                      await AuthService.getUserId();
                                  if (userId == null) return;

                                  try {
                                    final response = await http.post(
                                      Uri.parse(
                                        '${AuthService.baseUrl}/history/add',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        "user_id": int.parse(userId),
                                        "recipe_id": _recipeData!['recipe_id'],
                                        "history_date": DateTime.now()
                                            .toIso8601String(),
                                        "history_type": "cooking",
                                      }),
                                    );

                                    final responseData = jsonDecode(
                                      response.body,
                                    );

                                    if (responseData['status'] == 'success') {
                                      // 3. แจ้งเตือนเมื่อสำเร็จตาม Message จาก API
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              responseData['message'],
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    print("History Error: $e");
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],

                        // ปุ่ม Read reviews (แสดงเสมอ)
                        Expanded(
                          child: _buildActionButton(
                            label: "Read reviews",
                            icon: Icons.chat_bubble,
                            color: Colors.black,
                            iconColor: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityReviews(
                                    recipeId: _recipeData!['recipe_id'],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

Widget _buildActionButton({
  required String label,
  required IconData icon,
  required Color color,
  required Color iconColor,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 55,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: iconColor),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
