import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/app_models.dart';
import 'notification_service.dart';

class DataService {
  final NotificationService _notificationService = NotificationService();

  // Hàm bổ trợ lấy Header kèm JWT Token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- QUẢN LÝ NGƯỜI DÙNG (USERS - Dành cho Admin) ---
  Future<List<User>> getUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(Config.usersUrl), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh sách người dùng');
  }

  Future<bool> updateUser(String id, String username, String role) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Config.usersUrl}/$id'),
      headers: headers,
      body: jsonEncode({'id': id, 'userName': username, 'role': role}),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> deleteUser(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('${Config.usersUrl}/$id'), headers: headers);
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> enableUser(String id) async {
    final headers = await _getHeaders();
    final response = await http.put(Uri.parse(Config.enableUserUrl(id)), headers: headers);
    return response.statusCode == 200;
  }

  Future<bool> disableUser(String id) async {
    final headers = await _getHeaders();
    final response = await http.put(Uri.parse(Config.disableUserUrl(id)), headers: headers);
    return response.statusCode == 200;
  }

  // --- QUẢN LÝ LỊCH (CALENDARS - Dành cho Admin) ---
  Future<List<Calendar>> getCalendars() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(Config.calendarsUrl), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Calendar.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh sách lịch');
  }

  Future<Calendar?> createCalendar(String title, String description) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(Config.calendarsUrl),
      headers: headers,
      body: jsonEncode({'title': title, 'description': description}),
    );
    // Chấp nhận cả 201 Created và 200 OK
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Calendar.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> updateCalendar(String id, String title, String description) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Config.calendarsUrl}/$id'),
      headers: headers,
      body: jsonEncode({'id': id, 'title': title, 'description': description}),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> deleteCalendar(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('${Config.calendarsUrl}/$id'), headers: headers);
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // --- QUẢN LÝ SỰ KIỆN (EVENTS) ---

  Future<List<Event>> getEvents() async {
    try {
      final headers = await _getHeaders();
      print("Đang tải sự kiện từ: ${Config.eventsUrl}");

      final response = await http.get(
          Uri.parse(Config.eventsUrl),
          headers: headers
      ).timeout(const Duration(seconds: 15));

      print("Response code: ${response.statusCode}");

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        print("Tải thành công ${data.length} sự kiện");
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        print("Lỗi tải sự kiện: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Lỗi kết nối DataService (getEvents): $e");
      return [];
    }
  }

  Future<Event?> createEvent(String title, DateTime startTime, DateTime endTime, {String? calendarId, bool notifyGroup = false}) async {
    final headers = await _getHeaders();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    final Map<String, dynamic> body = {
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'userId': userId,
      'notifyGroup': notifyGroup 
    };

    if (calendarId != null) {
      body['calendarId'] = calendarId;
    }

    final response = await http.post(
      Uri.parse(Config.eventsUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final newEvent = Event.fromJson(jsonDecode(response.body));
      return newEvent;
    }
    return null;
  }

  Future<bool> updateEvent(String id, String title, DateTime startTime, DateTime endTime) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Config.eventsUrl}/$id'),
      headers: headers,
      body: jsonEncode({
        'id': id,
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      }),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<bool> deleteEvent(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('${Config.eventsUrl}/$id'), headers: headers);
    if (response.statusCode == 204 || response.statusCode == 200) {
      await _notificationService.cancelNotification(id.hashCode);
      return true;
    }
    return false;
  }

  // --- QUẢN LÝ NHẮC NHỞ (REMINDERS) ---
  Future<List<Reminder>> getReminders() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('${Config.baseUrl}/Reminders'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Reminder.fromJson(json)).toList();
    }
    return [];
  }

  Future<Reminder?> createReminder(String title, DateTime reminderTime) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/Reminders'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'reminderTime': reminderTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final reminder = Reminder.fromJson(jsonDecode(response.body));
      await _notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: '🔔 Nhắc nhở',
        body: reminder.title,
        scheduledTime: reminderTime,
      );
      return reminder;
    }
    return null;
  }

  Future<bool> updateReminder(String id, bool isEnabled) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/Reminders/$id'),
      headers: headers,
      body: jsonEncode({'id': id, 'isEnabled': isEnabled}),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      if (!isEnabled) {
        await _notificationService.cancelNotification(id.hashCode);
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteReminder(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('${Config.baseUrl}/Reminders/$id'), headers: headers);
    if (response.statusCode == 204 || response.statusCode == 200) {
      await _notificationService.cancelNotification(id.hashCode);
      return true;
    }
    return false;
  }
}
