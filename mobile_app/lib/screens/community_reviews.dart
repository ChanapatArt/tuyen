import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class CommunityReviews extends StatefulWidget {
  final int recipeId; // ✅ รับ recipeId มาจากหน้า RecipeDetails
  const CommunityReviews({super.key, required this.recipeId});

  @override
  State<CommunityReviews> createState() => _CommunityReviewsState();
}

class _CommunityReviewsState extends State<CommunityReviews> {
  List<dynamic> _reviews = [];
  int _selectedRating = 5;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  // ✅ ฟังก์ชันดึงข้อมูลรีวิวจาก API
  Future<void> _fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/recipes/${widget.recipeId}/reviews'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _reviews = responseData['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching reviews: $e");
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
            // ส่วน Header
            _buildHeader(context),

            // 1. รายการรีวิวจริงจากฐานข้อมูล
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C853),
                      ),
                    )
                  : _reviews.isEmpty
                  ? const Center(child: Text("No reviews yet. be the first!"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildReviewCard(
                            userName: review['reviewer_name'] ?? "Anonymous",
                            time: _formatDate(review['created_at'] ?? ""),
                            comment: review['comment'] ?? "",
                            rating: (review['rating'] ?? 5).toInt(),
                            initial: (review['reviewer_name'] ?? "A")[0]
                                .toUpperCase(),
                          ),
                        );
                      },
                    ),
            ),

            // 2. ส่วนพิมพ์รีวิวด้านล่าง
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildReviewInput(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Header
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
      child: Row(
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
          const Text(
            "Community reviews",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper: การ์ดรีวิว (ปรับให้แสดงดาวตามค่าจริง)
  Widget _buildReviewCard({
    required String userName,
    required String time,
    required String comment,
    required String initial,
    required int rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF00C853),
                radius: 18,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color: index < rating
                        ? Colors.orange
                        : Colors.grey.shade300, // ✅ แสดงดาวตามคะแนน
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(comment, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty) return;

    String? userId =
        await AuthService.getUserId(); // ดึง ID ผู้ใช้ที่ Login อยู่
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/review/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": int.parse(userId), // ✅ ตาม Schema
          "recipe_id": widget.recipeId, // ✅ ตาม Schema
          "rating": _selectedRating,
          "comment": _commentController.text, // ✅ ตาม Schema
          "created_at": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _commentController.clear();
        _fetchReviews();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Review submitted!")));
        }
      }
    } catch (e) {
      print("Submit Error: $e");
    }
  }

  Widget _buildReviewInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: "Write your review...",
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            if (_commentController.text.isNotEmpty) {
              _showRatingDialog(); // ✅ ให้เลือกดาวก่อนส่ง
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please write a comment first")),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dateTime = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy - HH:mm').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.orange,
                              size: 40,
                            ),
                            onPressed: () {
                              setModalState(() => _selectedRating = index + 1);
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _submitReview(); 
                            },
                            child: const Text(
                              "OK",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF5350),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
