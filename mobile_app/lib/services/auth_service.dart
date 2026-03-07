import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'https://smartfridge-api-gp-fudkfahvfeazgced.southeastasia-01.azurewebsites.net';

  // --- 1. ฟังก์ชัน Login ---
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        String userId = data['user_id'].toString();
        await saveUserSession(userId);
        return true;
      } else {
        print("Login Error: ${data['message']}");
        return false;
      }
    }
    return false;
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id'); // ลบค่า user_id ทิ้งเพื่อให้ระบบจำไม่ได้
  }

  // --- 2. ฟังก์ชัน Register ---
  static Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String allergies = "",
    String dietType = "",
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
        "display_name": displayName,
        "allergies": allergies,
        "diet_type": dietType,
      }),
    );

    if (response.statusCode == 200) {
      String userId = jsonDecode(response.body);
      await saveUserSession(userId); // ลงทะเบียนเสร็จให้ Login อัตโนมัติเลย
      return true;
    }
    return false;
  }

  // --- ส่วนจัดการ Local Storage ---
  static Future<void> saveUserSession(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id'); //
  }
}
