import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minhdattrinh/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Sửa lỗi: Cung cấp tham số `isLoggedIn` bắt buộc.
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Xác minh rằng màn hình đăng nhập hiển thị đúng.
    // Thay vì test bộ đếm cũ, chúng ta test các text trên màn hình login.
    expect(find.text('Ứng dụng Lịch & Nhắc nhở'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);

    // Phần test cũ không còn phù hợp nữa.
    // expect(find.text('0'), findsOneWidget);
    // expect(find.text('1'), findsNothing);
  });
}
