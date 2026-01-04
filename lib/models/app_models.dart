class User {
  final String id;
  final String userName;
  final String email;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.userName,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      isActive: json['isActive'] ?? false,
    );
  }
}

class Calendar {
  final String id;
  final String title;
  final String description;
  final bool isHidden;
  final List<String> members; // Danh sách thành viên trong nhóm

  Calendar({
    required this.id, 
    required this.title, 
    required this.description, 
    required this.isHidden,
    this.members = const [],
  });

  factory Calendar.fromJson(Map<String, dynamic> json) {
    var membersList = <String>[];
    if (json['members'] != null) {
      membersList = List<String>.from(json['members']);
    }
    return Calendar(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isHidden: json['isHidden'] ?? false,
      members: membersList,
    );
  }
}

class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isHidden;
  final String? calendarId;
  final List<String> attendees;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.isHidden,
    this.calendarId,
    this.attendees = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    var attendeesList = <String>[];
    if (json['attendees'] != null) {
      attendeesList = List<String>.from(json['attendees']);
    }

    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now(),
      isHidden: json['isHidden'] ?? false,
      calendarId: json['calendarId'],
      attendees: attendeesList,
    );
  }
}

class Reminder {
  final String id;
  final String title;
  final DateTime reminderTime;
  bool isEnabled;

  Reminder({required this.id, required this.title, required this.reminderTime, this.isEnabled = true});

 factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      reminderTime: json['reminderTime'] != null ? DateTime.parse(json['reminderTime']) : DateTime.now(),
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}


class LoginResponse {
  final String token;
  final String role;
  final bool needOtp;

  LoginResponse({required this.token, required this.role, required this.needOtp});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      role: json['role'] ?? '',
      needOtp: json['needOtp'] ?? false,
    );
  }
}
