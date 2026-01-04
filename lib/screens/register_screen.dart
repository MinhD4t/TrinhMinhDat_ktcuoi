import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController(); // Thêm Email theo yêu cầu Backend
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Thêm xác nhận mật khẩu
  final _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Kiểm tra dữ liệu đầu vào cơ bản
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Vui lòng nhập đầy đủ thông tin', Colors.orange);
      return;
    }

    if (password != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu xác nhận không khớp', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi hàm register đã cập nhật trong AuthService
      final success = await _authService.register(username, email, password);

      if (mounted) {
        if (success) {
          _showSnackBar('Đăng ký thành công! Vui lòng đăng nhập.', Colors.green);
          Navigator.pop(context); // Quay về màn hình Login
        } else {
          _showSnackBar('Đăng ký thất bại! Tên đăng nhập có thể đã tồn tại.', Colors.red);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối Server', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Tạo tài khoản mới'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tham gia cùng chúng tôi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Tên đăng nhập
              _buildTextField(_usernameController, 'Tên đăng nhập', Icons.person),
              const SizedBox(height: 16),

              // Email
              _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              // Mật khẩu
              _buildTextField(_passwordController, 'Mật khẩu', Icons.lock, isPassword: true),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu
              _buildTextField(_confirmPasswordController, 'Xác nhận mật khẩu', Icons.lock_outline, isPassword: true),

              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget dùng chung cho các ô nhập liệu để code gọn hơn
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}