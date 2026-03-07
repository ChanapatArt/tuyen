import 'package:flutter/material.dart';

class Histories extends StatefulWidget {
  const Histories({super.key});
  @override
  State<Histories> createState() => _FoodSchedulePage();
}

class _FoodSchedulePage extends State<Histories> {
  List<Map<String, String>> scheduleItems = [
    {"meal": "Breakfast - 08:00", "menu": "Omelet"},
    {"meal": "Lunch - 12:00", "menu": "Green Curry"},
    {"meal": "Dinner - 12:00", "menu": "Green Curry"},
  ];
  final TextEditingController menuController = TextEditingController();
  String selectedMeal = "Dinner - 17:00";
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
                    "Histories",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.history, size: 30),
                ],
              ),
              const SizedBox(height: 20),

              // 2. แถบเลือกวันที่ (Date Selector)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth:
                        MediaQuery.of(context).size.width -
                        40, // ลบ padding ซ้าย-ขวา (20+20)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      // ✅ คำนวณย้อนหลัง: วันนี้ลบด้วย index (0 คือวันนี้, 1 คือเมื่อวาน...)
                      DateTime dateToShow = DateTime.now().subtract(
                        Duration(days: index),
                      );

                      // รายชื่อวันย่อ (ลำดับตาม weekday ของ Flutter: 1=Mon, 7=Sun)
                      List<String> weekDays = [ "","M","T","W","Th","F","Sa","S",];

                      String dayLabel = weekDays[dateToShow.weekday];
                      String dateLabel = dateToShow.day.toString();

                      // เช็กว่าเป็นวันปัจจุบันหรือไม่ (index 0 คือวันนี้)
                      bool isSelected = index == 0;

                      return _buildDateItem(
                        dayLabel,
                        dateLabel,
                        isSelected: isSelected,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Column(
                children: scheduleItems.map((item) {
                  return Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    onDismissed: (direction) {
                      setState(() {
                        scheduleItems.remove(item); // ลบข้อมูลออกจาก List
                      });

                      // แจ้งเตือนสั้นๆ ด้านล่าง (Optional)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${item['meal']} removed")),
                      );
                    },
                    child: _buildScheduleCard(
                      mealTime: item['meal']!,
                      menuName: item['menu']!,
                      calories: "350",
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
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
  Widget _buildScheduleCard({
    required String mealTime,
    required String menuName,
    required String calories,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        // เพื่อให้เส้นสีเขียวด้านข้างสูงเท่ากับเนื้อหา
        child: Row(
          children: [
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
                          mealTime.split(' - ')[0],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          mealTime.split(' - ')[1],
                          style: TextStyle(
                            color: Colors.grey,
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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ชื่ออาหารและรายละเอียด
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                menuName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "subtitle",
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
