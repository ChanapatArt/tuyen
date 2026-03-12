import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchAccountData(); // ดึงข้อมูลทันทีเมื่อเข้าหน้า
  }

  Future<void> _fetchAccountData() async {
    String? userId = await AuthService.getUserId();
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/user/$userId/account'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final data = responseData['data'];

          setState(() {
            // นำข้อมูลจาก API มาใส่ใน Controller
            _emailController.text = data['email'] ?? "";
            _nameController.text = data['display_name'] ?? "";
            _targetController.text = (data['target_cal'] ?? 2000).toString();
            // รหัสผ่านมักไม่ส่งกลับมาเพื่อความปลอดภัย หรือส่งมาเป็นค่าว่าง

            _passwordController.text = "********";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching account: $e");
      setState(() => _isLoading = false);
    }
  }

  // Controller สำหรับรับค่าจากช่องกรอกข้อมูล
  final TextEditingController _emailController = TextEditingController(
    text: "",
  );
  final TextEditingController _nameController = TextEditingController(text: "");
  final TextEditingController _passwordController = TextEditingController(
    text: "********",
  );
  final TextEditingController _targetController = TextEditingController(
    text: "2000",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. Profile Picture Section
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator() // แสดงตัวโหลดขณะรอข้อมูล
                  : Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text[0].toUpperCase()
                                : "U",
                            style: TextStyle(fontSize: 40, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _nameController.text,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _emailController.text,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // 2. Setting Form Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Setting",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            _buildInputLabel("Email"),
            _buildTextField(_emailController),

            _buildInputLabel("Name"),
            _buildTextField(_nameController),

            _buildInputLabel("Password"),
            _buildTextField(_passwordController, isPassword: true),

            _buildInputLabel("Target"),
            _buildTextField(
              _targetController,
              width: 150,
            ), // ช่อง Target สั้นลงตามรูป

            const SizedBox(height: 40),

            // 3. Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String? userId = await AuthService.getUserId();
                  if (userId == null) return;

                  try {
                    Map<String, dynamic> updateData = {
                      "display_name": _nameController.text,
                      "email": _emailController.text,
                      "target_cal":
                          int.tryParse(_targetController.text) ?? 2000,
                    };
                    // ตรวจสอบ: ถ้ามีการพิมพ์รหัสใหม่ (ไม่ใช่ค่าเดิมที่ดึงมา) ให้ส่งไปด้วย
                    if (_passwordController.text != "********" &&
                        _passwordController.text.isNotEmpty) {
                      updateData["password"] = _passwordController.text;
                    }

                    final response = await http.put(
                      Uri.parse('${AuthService.baseUrl}/user/$userId/edit'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(updateData),
                    );

                    final responseData = jsonDecode(response.body);

                    if (responseData['status'] == 'success') {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Account Updated Successfully!"),
                          ),
                        );
                      }
                      _fetchAccountData(); 
                    } else {
                      // จัดการ Error เช่น Email ซ้ำ
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              responseData['message'] ?? "Update failed",
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print("Update Error: $e");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget ช่วยสร้าง Label เหนือช่องกรอก
  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 15),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Widget ช่วยสร้าง TextField
  Widget _buildTextField(
    TextEditingController controller, {
    bool isPassword = false,
    double? width,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF28B446)),
          ),
        ),
      ),
    );
  }
}
