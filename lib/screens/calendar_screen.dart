import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  bool _isLoading = true;
  
  String _userRole = '';
  List<Calendar> _myCalendars = [];

  final Color _primaryColor = const Color(0xFF5C59E3); 

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _notificationService.init();
    _initData();
  }
  
  Future<void> _initData() async {
    await _checkUserRole();
    _fetchCalendars(); // Gọi tải danh sách lịch ngay
    _loadEvents();
  }
  
  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'User';
    if (mounted) {
      setState(() => _userRole = role);
    }
  }
  
  Future<void> _fetchCalendars() async {
    // Thử tải danh sách lịch cho tất cả user, backend sẽ lọc quyền
    try {
      final calendars = await _dataService.getCalendars();
      if (mounted) {
        setState(() => _myCalendars = calendars);
      }
    } catch (e) {
      print("Error loading calendars: $e");
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _fetchCalendars(); // Refresh calendars khi tải events
      
      final eventsList = await _dataService.getEvents();
      final Map<DateTime, List<Event>> eventsMap = {};

      for (var event in eventsList) {
        final date = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        if (eventsMap[date] == null) {
          eventsMap[date] = [];
        }
        eventsMap[date]!.add(event);
      }

      if (mounted) {
        setState(() {
          _events = eventsMap;
          _selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  Future<void> _addOrEditEvent({Event? event}) async {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    
    // Controller cho tạo nhóm mới và thêm thành viên (chỉ dùng cho Staff khi tạo mới)
    final groupNameController = TextEditingController();
    final memberEmailController = TextEditingController();

    DateTime startTime = event?.startTime ?? _selectedDay ?? DateTime.now();
    DateTime endTime = event?.endTime ?? startTime.add(const Duration(hours: 1));
    bool hasReminder = true;
    String? selectedCalId = event?.calendarId;
    bool remindGroup = false;

    // Refresh danh sách nhóm
    await _fetchCalendars();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      isEditing ? 'Cập nhật sự kiện' : 'Tạo Sự Kiện Mới',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // LOGIC UI CHO STAFF
                  if (_userRole == 'Staff') ...[
                     // Nếu đang tạo mới (không phải edit), hiển thị input Tên nhóm và Email thành viên
                     if (!isEditing) ...[
                        TextField(
                          controller: groupNameController,
                          decoration: InputDecoration(
                            labelText: 'Tên Nhóm (Tự đặt)',
                            hintText: 'Nhập tên nhóm mới...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.group_add),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: memberEmailController,
                          decoration: InputDecoration(
                            labelText: 'Thêm thành viên',
                            hintText: 'Nhập email thành viên...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person_add),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        CheckboxListTile(
                           title: const Text("Nhắc nhở cả nhóm"),
                           value: remindGroup, 
                           onChanged: (val) => setModalState(() => remindGroup = val ?? false),
                           controlAffinity: ListTileControlAffinity.leading,
                           contentPadding: EdgeInsets.zero,
                        ),
                     ] else ...[
                        // Nếu là Edit, giữ nguyên logic hiển thị thông tin nhóm cũ (nếu có)
                        if (selectedCalId != null) 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text("Đang sửa sự kiện của nhóm", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                          )
                     ]
                  ] else ...[
                     // Logic cũ cho User/Admin (Dropdown chọn nhóm hoặc Cá nhân)
                     if (_myCalendars.isNotEmpty) ...[
                        DropdownButtonFormField<String?>(
                            value: selectedCalId,
                            decoration: InputDecoration(
                              labelText: 'Nhóm',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("Cá nhân")),
                              ..._myCalendars.map((cal) => DropdownMenuItem(
                                value: cal.id, 
                                child: Text(cal.title)
                              ))
                            ],
                            onChanged: (val) {
                               setModalState(() => selectedCalId = val);
                            }
                        ),
                        const SizedBox(height: 10),
                     ] else ...[
                        if (_userRole != 'Staff')
                           const Padding(
                             padding: EdgeInsets.only(bottom: 10),
                             child: Text("Cá nhân", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                           ),
                     ]
                  ],

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề sự kiện',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final newStart = await _pickDateTime(startTime);
                            if (newStart != null) setModalState(() => startTime = newStart);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Bắt đầu',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final newEnd = await _pickDateTime(endTime);
                            if (newEnd != null) setModalState(() => endTime = newEnd);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Kết thúc',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy HH:mm').format(endTime)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Nhắc nhở", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (hasReminder)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_none, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text("Thông báo", style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 16),
                          const Text("Tại thời điểm", style: TextStyle(fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text("(${DateFormat('HH:mm').format(startTime)})", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setModalState(() => hasReminder = false),
                            child: const Icon(Icons.close, color: Colors.grey, size: 20),
                          )
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => setModalState(() => hasReminder = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: const [
                            Icon(Icons.add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("Thêm nhắc nhở", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (titleController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề sự kiện')));
                           return;
                        }
                        
                        Navigator.pop(context);

                        // LOGIC XỬ LÝ TẠO NHÓM MỚI (CHỈ STAFF)
                        String? newGroupId;
                        if (_userRole == 'Staff' && !isEditing) {
                           if (groupNameController.text.isNotEmpty) {
                              try {
                                 // 1. Tạo nhóm mới
                                 final newCal = await _dataService.createCalendar(groupNameController.text, "Nhóm sự kiện");
                                 if (newCal != null) {
                                    newGroupId = newCal.id;
                                    // 2. Thêm thành viên (Fake logic hoặc TODO API)
                                    if (memberEmailController.text.isNotEmpty) {
                                       print("Adding member ${memberEmailController.text} to group ${newCal.title}");
                                    }
                                 }
                              } catch (e) {
                                 print("Error creating group inline: $e");
                              }
                           }
                        } else {
                           newGroupId = selectedCalId; // Dùng nhóm đã chọn nếu không phải Staff tạo mới
                        }

                        final tempEvent = Event(
                          id: event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          startTime: startTime,
                          endTime: endTime,
                          isHidden: false,
                          calendarId: newGroupId // Gán ID nhóm mới hoặc nhóm đã chọn
                        );

                        // Optimistic UI update
                        setState(() {
                           final date = DateTime(startTime.year, startTime.month, startTime.day);
                           if (_events[date] == null) _events[date] = [];
                           if (isEditing) _events[date]!.removeWhere((e) => e.id == event!.id);
                           _events[date]!.add(tempEvent);
                           if (isSameDay(_selectedDay, date)) _selectedEvents = _getEventsForDay(_selectedDay!);
                        });
                        
                        // Handle API call
                        if (isEditing) {
                            await _dataService.updateEvent(tempEvent.id, tempEvent.title, tempEvent.startTime, tempEvent.endTime);
                        } else {
                            await _dataService.createEvent(
                              tempEvent.title, 
                              tempEvent.startTime, 
                              tempEvent.endTime, 
                              calendarId: newGroupId,
                              notifyGroup: remindGroup
                            );
                        }
                        
                        // Handle Local Notifications
                        if (hasReminder) {
                           await _notificationService.scheduleNotification(
                            id: tempEvent.id.hashCode,
                            title: '🔔 Nhắc nhở sự kiện',
                            body: '"${tempEvent.title}" đang diễn ra!',
                            scheduledTime: tempEvent.startTime,
                          );
                        } else if (isEditing) {
                           await _notificationService.cancelNotification(tempEvent.id.hashCode);
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(newGroupId != null && _userRole == 'Staff' && !isEditing 
                              ? 'Đã tạo nhóm và sự kiện thành công' 
                              : 'Đã lưu sự kiện'))
                        );
                        
                        // Refresh data để cập nhật danh sách nhóm nếu vừa tạo
                        if (newGroupId != null) _fetchCalendars();
                      },
                      child: Text(isEditing ? 'CẬP NHẬT' : 'TẠO SỰ KIỆN'),
                    ),
                  ),
                   if (isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Xóa sự kiện"),
                        onPressed: () async {
                           final confirm = await showDialog(
                             context: context,
                             builder: (ctx) => AlertDialog(
                               title: const Text('Xác nhận xóa'),
                               content: const Text('Bạn có chắc chắn muốn xóa sự kiện này?'),
                               actions: [
                                 TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text('Hủy')),
                                 TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                               ],
                             )
                           );
                           if (confirm == true) {
                             if (mounted) Navigator.pop(context);
                             setState(() {
                                final date = DateTime(startTime.year, startTime.month, startTime.day);
                                _events[date]?.removeWhere((e) => e.id == event!.id);
                                if (isSameDay(_selectedDay, date)) _selectedEvents = _getEventsForDay(_selectedDay!);
                             });
                             await _notificationService.cancelNotification(event!.id.hashCode);
                             await _dataService.deleteEvent(event.id);
                           }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100)
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial)
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _addOrEditEvent(event: event),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 50,
                  decoration: BoxDecoration(
                    color: event.calendarId != null ? Colors.orangeAccent : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.watch_later_outlined, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                      if (event.calendarId != null) ...[
                        const SizedBox(height: 4),
                        Text("Nhóm", style: TextStyle(fontSize: 12, color: Colors.orange[700], fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Lịch của tôi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black87), onPressed: () {}),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87), 
            onPressed: _loadEvents
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 10),
            child: TableCalendar<Event>(
              locale: 'vi_VN',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Colors.blueAccent, 
                  shape: BoxShape.circle
                ),
                selectedDecoration: BoxDecoration(
                  color: _primaryColor, 
                  shape: BoxShape.circle
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.redAccent, 
                  shape: BoxShape.circle
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('Không có sự kiện nào'))
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(_selectedEvents[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditEvent(),
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
