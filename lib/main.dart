import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import thư viện intl
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';

// Class to bypass SSL certificate verification for local development
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Lịch tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Apply the SSL override
  HttpOverrides.global = MyHttpOverrides();

  // Khởi tạo Notification Service
  await NotificationService().init();

  // Kiểm tra xem người dùng đã đăng nhập chưa
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Nếu đã đăng nhập, vào MainScreen, ngược lại thì vào LoginScreen
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
