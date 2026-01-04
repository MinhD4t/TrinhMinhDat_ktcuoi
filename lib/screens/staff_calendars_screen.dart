import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';

class StaffCalendarsScreen extends StatefulWidget {
  const StaffCalendarsScreen({super.key});

  @override
  State<StaffCalendarsScreen> createState() => _StaffCalendarsScreenState();
}

class _StaffCalendarsScreenState extends State<StaffCalendarsScreen> {
  final DataService _dataService = DataService();
  List<Calendar> _calendars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() => _isLoading = true);
    try {
      final calendars = await _dataService.getCalendars();
      setState(() {
        _calendars = calendars;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fallback if load fails
          _calendars = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách nhóm. Vui lòng thử lại.'))
        );
      }
    }
  }

  Future<void> _addMember(Calendar calendar) async {
    final memberEmailController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm thành viên vào "${calendar.title}"'),
        content: TextField(
          controller: memberEmailController,
          decoration: const InputDecoration(hintText: 'user@example.com', labelText: 'Email thành viên'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (memberEmailController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã gửi lời mời đến ${memberEmailController.text}'))
                );
                // TODO: Gọi API thêm thành viên nếu có
              }
            },
            child: const Text('Thêm'),
          )
        ],
      ),
    );
  }

  Future<void> _createCalendar() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final memberController = TextEditingController(); // Thêm controller cho thành viên

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Nhóm Lịch Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController, 
                decoration: const InputDecoration(labelText: 'Tên Nhóm')
              ),
              TextField(
                controller: descController, 
                decoration: const InputDecoration(labelText: 'Mô tả')
              ),
              const SizedBox(height: 16),
              const Text("Thêm thành viên ban đầu:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              TextField(
                controller: memberController,
                decoration: const InputDecoration(
                  labelText: 'Email thành viên',
                  hintText: 'user@example.com',
                  prefixIcon: Icon(Icons.person_add_alt_1)
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context); // Đóng dialog ngay
                
                // Hiển thị loading nhẹ hoặc snackbar
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tạo nhóm...')));

                try {
                  final newCalendar = await _dataService.createCalendar(titleController.text, descController.text);
                  if (newCalendar != null) {
                    // Nếu có nhập email thành viên thì xử lý thêm (giả lập hoặc API sau này)
                    if (memberController.text.isNotEmpty) {
                       print("Simulating adding member: ${memberController.text}");
                       // TODO: Gọi API addMember(newCalendar.id, memberController.text)
                    }

                    setState(() {
                      _calendars.add(newCalendar);
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã tạo nhóm "${newCalendar.title}" ${memberController.text.isNotEmpty ? "và thêm thành viên" : ""} thành công'))
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                     ScaffoldMessenger.of(context).hideCurrentSnackBar();
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi tạo nhóm')));
                  }
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lịch Nhóm'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calendars.isEmpty
              ? const Center(child: Text('Chưa có nhóm nào. Hãy tạo nhóm mới.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = _calendars[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.group, color: Colors.white),
                        ),
                        title: Text(calendar.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(calendar.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.blueAccent),
                          tooltip: 'Thêm thành viên',
                          onPressed: () => _addMember(calendar),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCalendar,
        tooltip: 'Tạo Nhóm Lịch mới',
        child: const Icon(Icons.add),
      ),
    );
  }
}
