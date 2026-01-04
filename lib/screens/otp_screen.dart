import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'main_screen.dart'; // Điều hướng về MainScreen mới

class OtpScreen extends StatefulWidget {
  final String username;
  const OtpScreen({super.key, required this.username});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _verifyOtp() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.verifyOtp(widget.username, _otpController.text);
      
      if (mounted) {
        if (success) {
          // Xác thực thành công, chuyển đến MainScreen
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const MainScreen()), // Về màn hình chính có Tab
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mã OTP sai hoặc đã hết hạn!'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nhập mã OTP đã được gửi tới email của bạn', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'OTP'),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _verifyOtp, child: const Text('Xác nhận')),
          ],
        ),
      ),
    );
  }
}
