import 'package:flutter/material.dart';
import 'package:mobile_app/screens/login.dart';
import 'package:mobile_app/screens/nutrition.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  // สถานะสำหรับเลือกเป้าหมาย (0 = Keep in shape, 1 = Lose weight)
  int _targetIndex = 0;

  // สถานะการติ๊กอาการแพ้อาหาร
  bool _isPeanutsAllergy = false;
  bool _isSeafoodAllergy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. หัวข้อและไอคอนตั้งค่า
              Row(
                children: [
                  const Text(
                    "Personal information",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Profile Card (สีเขียวอ่อน)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FAF0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB2E7C6)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      // สามารถใส่รูปได้ที่นี่: backgroundImage: AssetImage(...),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Data Scientist Chef",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Text(
                          "Free Member",
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. ส่วน Target
              const Text(
                "Target",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTargetButton(0, "Keep in shape"),
                  const SizedBox(width: 12),
                  _buildTargetButton(1, "Lose weight"),
                ],
              ),
              const SizedBox(height: 30),

              // 4. ส่วน Food allergies
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Food allergies",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF28B446),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAllergyItem(
                "Peanuts",
                _isPeanutsAllergy,
                (val) => setState(() => _isPeanutsAllergy = val!),
              ),
              const SizedBox(height: 10),
              _buildAllergyItem(
                "Seafood",
                _isSeafoodAllergy,
                (val) => setState(() => _isSeafoodAllergy = val!),
              ),

              const SizedBox(height: 30),

              // 5. ปุ่ม Log out (สีแดงจาง)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false, // false หมายถึงไม่เก็บหน้าเก่าไว้เลย
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Log out",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50), // เว้นที่ว่างก่อนถึงปุ่มล่างสุด
              // 6. ปุ่ม Look at nutrition
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NutritionPage()),
                    );
                  },
                  icon: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF28B446),
                  ),
                  label: const Text("Look at nutrition"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
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

  // Helper: สร้างปุ่มเลือกเป้าหมาย
  Widget _buildTargetButton(int index, String label) {
    bool isSelected = _targetIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _targetIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.grey.shade400 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  // Helper: สร้างรายการแพ้อาหารพร้อม Checkbox
  Widget _buildAllergyItem(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(fontSize: 16)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF28B446),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
