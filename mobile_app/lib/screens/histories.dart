import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';
import 'package:intl/intl.dart';

class Histories extends StatefulWidget {
  const Histories({super.key});
  @override
  State<Histories> createState() => _HistoriesState();
}

class _HistoriesState extends State<Histories> {
  List<dynamic> _allHistoryData = []; // เก็บข้อมูลดิบจาก API
  List<dynamic> _filteredHistory = []; // เก็บข้อมูลที่กรองตามวันที่เลือก
  bool _isLoading = true; // สถานะการโหลด
  DateTime _selectedDate = DateTime.now(); // วันที่กำลังเลือกดู

  @override
  void initState() {
    super.initState();
    _fetchHistoryData(); // ดึงข้อมูลทันทีเมื่อเปิดหน้า
  }

  // ✅ ฟังก์ชันดึงข้อมูลจาก API
  Future<void> _fetchHistoryData() async {
    String? userId = await AuthService.getUserId();
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/history/$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          setState(() {
            _allHistoryData = responseData['data'];
            _filterByDate(_selectedDate); // กรองข้อมูลของวันนี้เริ่มต้น
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // ✅ ฟังก์ชันกรองข้อมูลตามวันที่
  void _filterByDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _filteredHistory = _allHistoryData.where((item) {
        DateTime itemDate = DateTime.parse(item['history_date']);
        return itemDate.year == date.year &&
            itemDate.month == date.month &&
            itemDate.day == date.day;
      }).toList();
    });
  }

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
                    minWidth: MediaQuery.of(context).size.width - 40,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      // ✅ คำนวณวันที่ย้อนหลังจากปัจจุบัน
                      DateTime dateToShow = DateTime.now().subtract(
                        Duration(days: index),
                      );

                      List<String> weekDays = [
                        "",
                        "M",
                        "T",
                        "W",
                        "Th",
                        "F",
                        "Sa",
                        "S",
                      ];
                      String dayLabel = weekDays[dateToShow.weekday];
                      String dateLabel = dateToShow.day.toString();

                      // ✅ เช็กสถานะการเลือกจาก _selectedDate จริงๆ
                      bool isSelected =
                          dateToShow.day == _selectedDate.day &&
                          dateToShow.month == _selectedDate.month &&
                          dateToShow.year == _selectedDate.year;

                      return GestureDetector(
                        // ✅ เมื่อกดที่วันที่ ให้ทำการกรองข้อมูลใหม่
                        onTap: () => _filterByDate(dateToShow),
                        child: _buildDateItem(
                          dayLabel,
                          dateLabel,
                          isSelected: isSelected,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF28B446),
                      ),
                    )
                  : _filteredHistory.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text("No cooking history for this day."),
                      ),
                    )
                  : Column(
                      children: _filteredHistory.map((item) {
                        // 1. แปลงวันที่และเวลาจาก API
                        DateTime dateTime = DateTime.parse(
                          item['history_date'],
                        );
                        String formattedTime =
                            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

                        return Dismissible(
                          key: Key(
                            item['history_id'].toString(),
                          ), // ✅ ใช้ ID จริงจาก DB
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) async {
                            // 1. เก็บ ID ไว้ก่อนที่จะลบออกจาก List ในเครื่อง
                            final int historyIdToDelete = item['history_id'];

                            // 2. อัปเดต UI ทันทีเพื่อให้ผู้ใช้รู้สึกว่าแอปเร็ว (Optimistic Update)
                            setState(() {
                              _allHistoryData.removeWhere(
                                (h) => h['history_id'] == historyIdToDelete,
                              );
                              _filterByDate(_selectedDate);
                            });
                            try {
                              final response = await http.delete(
                                Uri.parse(
                                  '${AuthService.baseUrl}/history/remove/$historyIdToDelete',
                                ),
                                headers: {'Content-Type': 'application/json'},
                              );

                              if (response.statusCode == 200) {
                                final responseData = jsonDecode(response.body);
                                if (responseData['status'] == 'success') {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          responseData['message'] ??
                                              "Removed from history",
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } else {
                                print("Failed to delete on server");
                                _fetchHistoryData();
                              }
                            } catch (e) {
                              print("Delete Error: $e");
                            }
                          },
                          child: _buildScheduleCard(
                            mealTime:
                                "${item['history_type'].toUpperCase()} - $formattedTime",
                            menuName: item['recipe_title'],
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
        color: isSelected
            ? const Color(0xFF28B446)
            : Colors.white, // ✅ เปลี่ยนเป็นสีเขียวถ้าเลือก
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF28B446) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
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
