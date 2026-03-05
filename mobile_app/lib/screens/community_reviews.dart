import 'package:flutter/material.dart';

class CommunityReviews extends StatelessWidget {
  const CommunityReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: EdgeInsets.only(right: 8, top: 6.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Community reviews",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 1. รายการรีวิว (ใช้ Expanded เพื่อให้กินพื้นที่ที่เหลือ)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildReviewCard(
                  userName: "User_99",
                  time: "2 hours ago",
                  comment:
                      "This recipe is so easy, even dorm students can make it!",
                  initial: "U",
                  rating: 4,
                ),
                const SizedBox(height: 16),
                _buildReviewCard(
                  userName: "HealtyGuy",
                  time: "1 day ago",
                  comment:
                      "Reduce the oil a bit; it'll be delicious and healthier.",
                  initial: "H",
                  rating: 5,
                ),
              ],
            ),
          ),

          // 2. ส่วนพิมพ์รีวิว (ติดอยู่ด้านล่าง)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildReviewInput(),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างการ์ดรีวิวแต่ละอัน
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // วงกลมชื่อย่อ
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
              // ชื่อและเวลา
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
              // ดาว Rating
              Row(
                children: List.generate(
                  rating,
                  (index) =>
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ข้อความรีวิว
          Text(comment, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างช่องพิมพ์ด้านล่าง
  Widget _buildReviewInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(18)
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Write your review...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ปุ่มส่ง (สีดำ)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.all(Radius.circular(12))
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
