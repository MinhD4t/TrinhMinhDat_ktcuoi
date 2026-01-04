import 'dart:io';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    print("🔔 NotificationService: Bắt đầu khởi tạo...");
    tz.initializeTimeZones();
    
    // Cố gắng set timezone, nếu lỗi thì bỏ qua
    try {
        final location = tz.getLocation('Asia/Ho_Chi_Minh');
        tz.setLocalLocation(location);
        print("🔔 Timezone đã set: Asia/Ho_Chi_Minh");
    } catch (e) {
        print("⚠️ Không set được timezone HCM, dùng default local: $e");
    }

    // QUAN TRỌNG: Dùng @mipmap/ic_launcher là chuẩn nhất cho Flutter mặc định
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🔔 Đã bấm vào thông báo: ${response.payload}");
      },
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      print("🔔 Quyền thông báo: ${granted == true ? 'ĐƯỢC CẤP' : 'TỪ CHỐI'}");
      
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> showNotificationNow({required int id, required String title, required String body}) async {
    print("🔔 Đang gọi showNotificationNow cho ID: $id");
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
              'reminder_channel_id_FINAL_V2', // Đổi ID lần nữa
              'Lịch Sự Kiện Quan Trọng',
              channelDescription: 'Thông báo nhắc nhở sự kiện',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true,
              icon: '@mipmap/ic_launcher', // Đảm bảo icon này tồn tại
          );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await flutterLocalNotificationsPlugin.show(
          id, title, body, platformChannelSpecifics);
      print("✅ showNotificationNow THÀNH CÔNG");
    } catch (e) {
      print("❌ showNotificationNow THẤT BẠI: $e");
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    print("🔔 Yêu cầu đặt lịch lúc: $scheduledTime (Hiện tại: $now)");

    // Logic 1: Nếu thời gian đã qua hoặc còn dưới 5 giây -> Hiện ngay lập tức
    if (scheduledTime.difference(now).inSeconds < 5) {
      print("⚠️ Thời gian quá sát, hiển thị ngay lập tức.");
      await showNotificationNow(id: id, title: title, body: body);
      return;
    }

    // Logic 2: Dùng Timer nếu < 1 phút
    if (scheduledTime.difference(now).inMinutes < 1) {
       print("🕒 Thời gian < 1 phút, dùng Timer.");
       Timer(scheduledTime.difference(now), () {
          print("⏰ Timer đã kích hoạt!");
          showNotificationNow(id: id, title: title, body: body);
       });
       return;
    }

    // Logic 3: Dùng zonedSchedule
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel_id_FINAL_V2',
            'Lịch Sự Kiện Quan Trọng',
            channelDescription: 'Thông báo nhắc nhở sự kiện',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("✅ Đã lên lịch (Zoned) ID:$id thành công.");
    } catch (e) {
      print("❌ Lỗi scheduleNotification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
