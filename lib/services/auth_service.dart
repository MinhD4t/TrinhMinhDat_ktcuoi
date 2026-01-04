import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  // Hàm dùng chung để lưu thông tin user
  Future<void> _saveUserData(Map<String, dynamic> data, String username) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) await prefs.setString('jwt_token', data['token']);
    if (data['role'] != null) await prefs.setString('user_role', data['role']);
    if (data['userId'] != null) await prefs.setString('user_id', data['userId']);
    await prefs.setString('user_name', username);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse(Config.loginUrl);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // QUAN TRỌNG: Nếu login thành công và có token luôn (không cần OTP), lưu ngay lập tức
        if (data['token'] != null && (data['needOtp'] == false || data['needOtp'] == null)) {
           await _saveUserData(data, username);
        }
        
        return data;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyOtp(String username, String otp) async {
    final url = Uri.parse(Config.verifyOtpUrl);
    try {
      print('Verifying OTP for $username with code $otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'otp': otp}),
      );

      print('OTP Verify Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUserData(data, username); // Sử dụng hàm chung
        return true;
      }
      return false;
    } catch (e) {
      print('OTP Verify Error: $e');
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    final url = Uri.parse(Config.registerUrl);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'email': email, 'password': password, 'role': 'User'}),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
