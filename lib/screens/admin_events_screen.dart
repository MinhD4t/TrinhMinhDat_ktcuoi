import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _dataService = DataService();
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() async {
    try {
      final events = await _dataService.getEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Hàm chọn ngày giờ
  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _addOrEditEvent({Event? event}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    DateTime startTime = event?.startTime ?? DateTime.now();
    DateTime endTime = event?.endTime ?? DateTime.now().add(const Duration(hours: 1));
    final isEditing = event != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Sửa sự kiện' : 'Thêm sự kiện mới'),
            content: SingleChildScrollView(
               child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController, 
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Bắt đầu'),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(startTime)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await _pickDateTime(startTime);
                      if (picked != null) setDialogState(() => startTime = picked);
                    },
                  ),
                  ListTile(
                    title: const Text('Kết thúc'),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(endTime)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await _pickDateTime(endTime);
                      if (picked != null) setDialogState(() => endTime = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (isEditing) {
                    await _dataService.updateEvent(event.id, titleController.text, startTime, endTime);
                  } else {
                    await _dataService.createEvent(titleController.text, startTime, endTime);
                  }
                  _loadEvents();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Đã cập nhật sự kiện' : 'Đã thêm sự kiện thành công')));
                  }
                },
                child: Text(isEditing ? 'Lưu' : 'Thêm'),
              ),
            ],
          );
        }
      ),
    );
  }

  // Changed id type from int to String to fix error
  void _deleteEvent(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa sự kiện này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await _dataService.deleteEvent(id);
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sự kiện')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditEvent(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm Sự kiện',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('Chưa có sự kiện nào'))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.blue),
                        title: Text(event.title),
                        subtitle: Text(
                          '${DateFormat('dd/MM HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _addOrEditEvent(event: event),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEvent(event.id), // event.id is String
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
