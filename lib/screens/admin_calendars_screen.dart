import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class AdminCalendarsScreen extends StatefulWidget {
  const AdminCalendarsScreen({super.key});

  @override
  State<AdminCalendarsScreen> createState() => _AdminCalendarsScreenState();
}

class _AdminCalendarsScreenState extends State<AdminCalendarsScreen> {
  final _dataService = DataService();
  List<Calendar> _calendars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  void _loadCalendars() async {
    try {
      final calendars = await _dataService.getCalendars();
      if (mounted) {
        setState(() {
          _calendars = calendars;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addOrEditCalendar({Calendar? calendar}) {
    final titleController = TextEditingController(text: calendar?.title ?? '');
    final descController = TextEditingController(text: calendar?.description ?? '');
    final isEditing = calendar != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Sửa Lịch' : 'Thêm Lịch mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isEditing) {
                await _dataService.updateCalendar(calendar.id, titleController.text, descController.text);
              } else {
                await _dataService.createCalendar(titleController.text, descController.text);
              }
              _loadCalendars();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Đã cập nhật lịch' : 'Đã thêm lịch thành công')));
              }
            },
            child: Text(isEditing ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  // Đã sửa kiểu dữ liệu id từ int sang String
  void _deleteCalendar(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa lịch này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await _dataService.deleteCalendar(id);
      _loadCalendars();
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa lịch')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCalendar(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm Lịch',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calendars.isEmpty 
            ? const Center(child: Text('Chưa có lịch nào'))
            : ListView.builder(
              itemCount: _calendars.length,
              itemBuilder: (context, index) {
                final calendar = _calendars[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: Text(calendar.title),
                    subtitle: Text(calendar.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _addOrEditCalendar(calendar: calendar),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCalendar(calendar.id),
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
