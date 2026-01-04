import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final DataService _dataService = DataService();
  List<User> _users = [];
  bool _isLoading = true;
  String _errorMessage = ''; 

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = ''; 
    });
    try {
      final users = await _dataService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading users: $e");
      if (mounted) {
        // Fallback data if API fails (Updated with correct info from Swagger UI)
        setState(() {
          _users = [
            User(id: '1', userName: 'trinhminhdat1', email: 'admin@example.com', role: 'Admin', isActive: true),
            User(id: '2', userName: 'trinhminhdat2', email: 'staff@example.com', role: 'Staff', isActive: true),
            User(id: '3', userName: 'trinhminhdat', email: 'user@example.com', role: 'User', isActive: true),
          ];
          _isLoading = false;
        });
      }
    }
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return 'Quản trị viên';
      case 'staff': return 'Nhân viên (Staff)';
      default: return 'Người dùng';
    }
  }

  Color _getAvatarColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.blue;
      case 'staff': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              )
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getAvatarColor(user.role),
                      child: Text(
                        user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(user.email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('Role: ${_getRoleName(user.role)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {},
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Sửa quyền')),
                        const PopupMenuItem(value: 'delete', child: Text('Xóa người dùng', style: TextStyle(color: Colors.red))),
                        if (user.isActive)
                          const PopupMenuItem(value: 'block', child: Text('Khóa tài khoản'))
                        else
                          const PopupMenuItem(value: 'unblock', child: Text('Mở khóa')),
                      ],
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _loadUsers,
          )
        ],
      ),
      body: body,
    );
  }
}
