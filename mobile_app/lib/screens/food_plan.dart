import 'package:flutter/material.dart';

class FoodPlanPage extends StatelessWidget {
  const FoodPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. หัวข้อหน้าพร้อมไอคอนปฏิทิน
              const Row(
                children: [
                  Text(
                    "Food schedule",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.calendar_month, size: 30),
                ],
              ),
              const SizedBox(height: 20),

              // 2. แถบเลือกวันที่ (Date Selector)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // ✅ ใช้ ConstrainedBox เพื่อบังคับให้ Row มีความกว้างอย่างน้อยเท่ากับหน้าจอ
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth:
                        MediaQuery.of(context).size.width -
                        40, // ลบ padding ซ้าย-ขวา (20+20)
                  ),
                  child: Row(
                    // ✅ ใช้ MainAxisAlignment.spaceBetween เพื่อให้กระจายตัวเต็มพื้นที่
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateItem("M", "18", isSelected: false),
                      _buildDateItem("T", "19", isSelected: false),
                      _buildDateItem("W", "20", isSelected: false),
                      _buildDateItem("Th", "21", isSelected: true),
                      _buildDateItem("F", "22", isSelected: false),
                      _buildDateItem("Sa", "23", isSelected: false),
                      _buildDateItem("S", "24", isSelected: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 3. รายการอาหารตามมื้อ (Meal Items)
              _buildMealCard(
                mealType: "BreakFast",
                time: "08:00",
                title: "Black coffee + bread",
                subtitle: "120 kcal - Preparation time: 5 minutes",
                indicatorColor: Colors.transparent,
              ),
              const SizedBox(height: 16),
              _buildMealCard(
                mealType: "Lunch",
                time: "NOW",
                title: "Minced pork omelet",
                subtitle: "350 kcal - Preparation time: 10 minutes",
                indicatorColor: const Color(
                  0xFF28B446,
                ), // สีเขียวบ่งบอกว่าเป็นมื้อปัจจุบัน
                isCurrent: true,
              ),
              const SizedBox(height: 24),

              // 4. ปุ่มเพิ่มแผน (+ Plan)
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.grey),
                  label: const Text(
                    "Plan",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างปุ่มวันที่
  Widget _buildDateItem(String day, String date, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(date, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Widget สร้างการ์ดมื้ออาหาร
  Widget _buildMealCard({
    required String mealType,
    required String time,
    required String title,
    required String subtitle,
    required Color indicatorColor,
    bool isCurrent = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        // เพื่อให้เส้นสีเขียวด้านข้างสูงเท่ากับเนื้อหา
        child: Row(
          children: [
            // เส้นบ่งบอกสถานะ (มื้อปัจจุบัน)
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          mealType,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            color: isCurrent
                                ? const Color(0xFF28B446)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // กล่องรูปภาพจำลอง
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ชื่ออาหารและรายละเอียด
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
