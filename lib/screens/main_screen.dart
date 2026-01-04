import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calendar_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';
import 'admin_users_screen.dart';
import 'staff_calendars_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _userRole = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? 'User';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    if (_userRole == 'Admin') {
      // Admin: Thấy mọi thứ + Quản lý User
      screens = [
        const AdminUsersScreen(),       // Tab 0: Quản lý người dùng
        const StaffCalendarsScreen(),   // Tab 1: Quản lý Lịch Nhóm
        const CalendarScreen(),         // Tab 2: Xem lịch cá nhân
        const ProfileScreen(),          // Tab 3: Cá nhân
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.group_work), label: 'Groups'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (_userRole == 'Staff') {
      // Staff: Lịch cá nhân + Quản lý nhóm
      screens = [
        const CalendarScreen(),         // Tab 0: Lịch cá nhân
        const StaffCalendarsScreen(),   // Tab 1: Quản lý nhóm
        const RemindersScreen(),        // Tab 2: Nhắc nhở
        const ProfileScreen(),          // Tab 3: Cá nhân
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch'),
        BottomNavigationBarItem(icon: Icon(Icons.group_work), label: 'Nhóm'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Nhắc nhở'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else {
      // User: Lịch cá nhân + Nhắc nhở
      screens = [
        const CalendarScreen(),
        const RemindersScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Nhắc nhở'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá nhân'),
      ];
    }

    // Reset index nếu role thay đổi làm số lượng tab thay đổi
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Quan trọng để icon không bị nhảy khi có >3 tab
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
      ),
    );
  }
}
