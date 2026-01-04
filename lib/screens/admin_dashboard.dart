import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.admin_panel_settings, size: 100, color: Colors.blueAccent),
          SizedBox(height: 20),
          Text(
            'Chào mừng Admin',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Sử dụng thanh điều hướng bên dưới để quản lý hệ thống.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
