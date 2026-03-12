import 'package:flutter/material.dart';
import 'package:mobile_app/screens/account_page.dart';
import 'package:mobile_app/screens/login.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  String displayName = "Loading...";
  int target = 0;
  int consumed_calories = 0;
  String email = "";
  List<String> foodAllergies = [];
  List<String> dietTypes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // ดึงข้อมูลทันทีเมื่อเปิดหน้า
  }

  Future<void> _fetchUserProfile() async {
    String? userId = await AuthService.getUserId();
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/user/$userId/profile'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          final data = responseData['data'];
          setState(() {
            displayName = data['display_name'] ?? "No Name";
            target = data['target_cal'] ?? 2000;
            consumed_calories = data['consumed_calories'] ?? 0;
            foodAllergies = List<String>.from(data['allergies'] ?? []);
            dietTypes = List<String>.from(data['diet_types'] ?? []);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  final TextEditingController _inputController = TextEditingController();

  // --- ฟังก์ชันแสดง Dialog แบบ Custom ---
  void _showCustomDialog(
    String title,
    List<String> targetList, {
    bool isAllergy = true,
  }) {
    _inputController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0), // คุมระยะห่างด้วยตัวเอง
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: isAllergy ? "Seafood" : "Vegan",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          if (_inputController.text.isNotEmpty) {
                            String? userId = await AuthService.getUserId();
                            if (userId == null) return;
                            String subPath = isAllergy
                                ? "allergies/add"
                                : "diet-type/add";
                            String bodyKey = isAllergy
                                ? "allergy_name"
                                : "diet_name";
                            try {
                              final response = await http.post(
                                Uri.parse(
                                  '${AuthService.baseUrl}/user/$userId/$subPath',
                                ),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  bodyKey: _inputController
                                      .text, // ส่ง Key ให้ตรงตาม Schema
                                }),
                              );

                              if (response.statusCode == 200) {
                                setState(() {
                                  targetList.add(_inputController.text);
                                });
                                if (context.mounted) Navigator.pop(context);
                              }
                            } catch (e) {
                              print("Error: $e");
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28B446),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF41F11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancle",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _fetchUserProfile,
        color: Colors.green,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildCalorieCard(), // ใช้ตัวเดิมที่คุณชอบ
                const SizedBox(height: 25),

                // 2. แสดงรายการ Food Allergies ตามจำนวนจริง
                _buildSectionHeader(
                  "Food allergies",
                  () => _showCustomDialog(
                    "Food allergies",
                    foodAllergies,
                    isAllergy: true,
                  ),
                ),
                const SizedBox(height: 10),
                ...foodAllergies.map(
                  (item) => Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    // 🗑️ ฟังก์ชันที่จะทำงานเมื่อสไลด์จนสุด
                    onDismissed: (direction) async {
                      final String itemToRemove = item;

                      setState(() {
                        foodAllergies.remove(itemToRemove);
                      });

                      try {
                        String? userId = await AuthService.getUserId();
                        if (userId == null) return;

                        // ✅ ปรับ URL ให้ส่งแบบ Query Parameter (?allergy_name=ชื่อ)
                        final response = await http.delete(
                          Uri.parse(
                            '${AuthService.baseUrl}/user/$userId/allergies/remove?allergy_name=$itemToRemove',
                          ),
                          headers: {'Content-Type': 'application/json'},
                        );

                        if (response.statusCode == 200) {
                          final responseData = jsonDecode(response.body);
                          if (context.mounted &&
                              responseData['status'] == 'success') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  responseData['message'] ??
                                      "$itemToRemove removed",
                                ),
                              ),
                            );
                          }
                        } else {
                          _fetchUserProfile(); // คืนค่าหากลบไม่สำเร็จ
                        }
                      } catch (e) {
                        print("Delete Allergy Error: $e");
                        _fetchUserProfile();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildInfoTile(item),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // 3. แสดงรายการ Diet type ตามจำนวนจริง
                _buildSectionHeader(
                  "Diet type",
                  () => _showCustomDialog(
                    "Diet type",
                    dietTypes,
                    isAllergy: false,
                  ),
                ),
                const SizedBox(height: 10),
                ...dietTypes.map(
                  (item) => Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    onDismissed: (direction) async {
                      final String itemToRemove = item;

                      setState(() {
                        dietTypes.remove(itemToRemove);
                      });

                      try {
                        String? userId = await AuthService.getUserId();
                        if (userId == null) return;
                        final response = await http.delete(
                          Uri.parse(
                            '${AuthService.baseUrl}/user/$userId/diet-type/remove?diet_name=$itemToRemove',
                          ),
                          headers: {'Content-Type': 'application/json'},
                        );

                        if (response.statusCode == 200) {
                          final responseData = jsonDecode(response.body);
                          if (context.mounted &&
                              responseData['status'] == 'success') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  responseData['message'] ??
                                      "$itemToRemove removed",
                                ),
                              ),
                            );
                          }
                        } else {
                          _fetchUserProfile(); // คืนค่าหากลบไม่สำเร็จ
                        }
                      } catch (e) {
                        print("Delete Diet Type Error: $e");
                        _fetchUserProfile();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildInfoTile(item),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                _buildSignOutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          "Personal information",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 8),
        const Icon(Icons.settings_outlined, size: 28),
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onAdd,
          child: const Icon(
            Icons.add_circle_outline,
            color: Color(0xFF28B446),
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildCalorieCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF071E1D),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF1F1F1F),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : "?", // ใช้ตัวอักษรแรกของชื่อ
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(color: Colors.green, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Total calories (target ${isLoading ? '...' : target})",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isLoading ? '0' : consumed_calories}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Calories",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: target > 0 ? (consumed_calories / target) : 0,
                minHeight: 10,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // 1. ลบข้อมูล User Session ออกจากเครื่อง
          await AuthService.logout(); // เรียกใช้ฟังก์ชันที่เราสร้างไว้ใน AuthService

          // 2. ย้อนกลับไปหน้า Login และล้าง History ของหน้าก่อนๆ ทั้งหมด
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false, // ล้าง stack หน้าจอทั้งหมดทิ้ง
            );
          }
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: const Text(
          "Sign Out",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEBEE),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
