import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // Controller สำหรับรับค่าจากช่องกรอกข้อมูล
  final TextEditingController _emailController = TextEditingController(
    text: "chef@smartfridge.app",
  );
  final TextEditingController _nameController = TextEditingController(
    text: "Chef Scientist",
  );
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
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    child: const Text(
                      "C",
                      style: TextStyle(fontSize: 40, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Chef Scientist",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "chef@smartfridge.app",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                onPressed: () {
                  // Logic สำหรับบันทึกข้อมูล
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Saved Successfully!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28B446), // สีเขียวตามธีม
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
