import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _dataService.getReminders();
      if (mounted) {
        setState(() {
          _reminders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải nhắc nhở: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addReminder() async {
    final titleController = TextEditingController();
    DateTime now = DateTime.now();

    // Sửa lỗi: Cung cấp đầy đủ các tham số bắt buộc cho DatePicker
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000), // Ngày bắt đầu có thể chọn
      lastDate: DateTime(2100),  // Ngày kết thúc có thể chọn
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute
        );

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thêm nhắc nhở mới'),
            content: TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Nhập tiêu đề nhắc nhở...')
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy')
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  Navigator.pop(context);

                  final newReminder = await _dataService.createReminder(
                      titleController.text,
                      selectedDateTime
                  );

                  if (newReminder != null) {
                    // FIX: Gọi hàm thông báo với các tham số có tên (Named Parameters)
                    await _notificationService.scheduleNotification(
                      id: newReminder.id.hashCode,
                      title: '🔔 Nhắc nhở của bạn',
                      body: newReminder.title,
                      scheduledTime: newReminder.reminderTime,
                    );
                    _loadReminders();
                  }
                },
                child: const Text('Lưu'),
              )
            ],
          ),
        );
      }
    }
  }

  Future<void> _toggleReminder(Reminder reminder, bool value) async {
    await _dataService.updateReminder(reminder.id, value);
    if (value) {
      // FIX: Thêm tên tham số khi bật nhắc nhở
      await _notificationService.scheduleNotification(
        id: reminder.id.hashCode,
        title: '🔔 Nhắc nhở!',
        body: reminder.title,
        scheduledTime: reminder.reminderTime,
      );
    } else {
      await _notificationService.cancelNotification(reminder.id.hashCode);
    }
    _loadReminders();
  }

  Future<void> _deleteReminder(String id) async {
    final success = await _dataService.deleteReminder(id);
    if (success) {
      await _notificationService.cancelNotification(id.hashCode);
      _loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc nhở')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadReminders,
        child: _reminders.isEmpty
            ? const Center(child: Text('Chưa có nhắc nhở nào'))
            : ListView.builder(
          itemCount: _reminders.length,
          itemBuilder: (context, index) {
            final reminder = _reminders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              elevation: 2,
              child: ListTile(
                title: Text(
                    reminder.title,
                    style: TextStyle(
                        decoration: reminder.isEnabled ? null : TextDecoration.lineThrough,
                        fontWeight: FontWeight.bold
                    )
                ),
                subtitle: Text(
                    DateFormat('HH:mm - dd/MM/yyyy').format(reminder.reminderTime)
                ),
                leading: Switch(
                  activeColor: Colors.blue,
                  value: reminder.isEnabled,
                  onChanged: (value) => _toggleReminder(reminder, value),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _deleteReminder(reminder.id),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        child: const Icon(Icons.add_alert),
        tooltip: 'Thêm nhắc nhở',
      ),
    );
  }
}