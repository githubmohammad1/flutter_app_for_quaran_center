import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/person_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../models/classes.dart';

class AttendanceTakeScreen extends StatefulWidget {
  const AttendanceTakeScreen({super.key});

  @override
  State<AttendanceTakeScreen> createState() => _AttendanceTakeScreenState();
}

class _AttendanceTakeScreenState extends State<AttendanceTakeScreen> {
  late DateTime _date;
  String _sessionTime = 'صباح';
  final sessionTimes = const ['صباح', 'مساء'];

  /// خريطة لحالة كل طالب (حاضر / غائب)
  final Map<int, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    Future.microtask(() async {
      await context.read<PersonProvider>().fetchAll(role: 'student');
      await _loadAttendanceForSession();
    });
  }

  Future<void> _loadAttendanceForSession() async {
    final pp = context.read<PersonProvider>();
    final attendancePvd = context.read<AttendanceProvider>();

    await attendancePvd.fetchAll(force: true);
    _attendanceStatus.clear();

    final students = pp.items.where((p) => p.role == 'student').toList();
    for (var s in students) {
      final record = attendancePvd.items.firstWhere(
        (a) =>
            a.student == s.id &&
            a.date == _date.toIso8601String().split('T').first &&
            a.sessionTime == _sessionTime,
        orElse: () => Attendance(
          student: s.id!,
          date: '',
          sessionTime: '',
          status: 'غائب',
        ),
      );
      _attendanceStatus[s.id!] = record.status;
    }

    setState(() {});
  }

  Future<void> _toggleAttendance(int studentId) async {
    final current = _attendanceStatus[studentId] ?? 'غائب';
    final newStatus = current == 'حاضر' ? 'غائب' : 'حاضر';

    // استدعاء البروفايدر للحفظ أو التعديل
    final saved = await context.read<AttendanceProvider>().createOrUpdate(
          Attendance(
            student: studentId,
            date: _date.toIso8601String().split('T').first,
            sessionTime: _sessionTime,
            status: newStatus,
          ),
        );

    if (saved != null) {
      await _loadAttendanceForSession();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AttendanceProvider>().error ??
                'تعذر حفظ الحضور',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context
        .watch<PersonProvider>()
        .items
        .where((p) => p.role == 'student')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الحضور اليومي'),
        actions: [
          IconButton(
            tooltip: 'تغيير التاريخ',
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _date = picked);
                await _loadAttendanceForSession();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // اختيار فترة الجلسة
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _sessionTime,
              decoration: const InputDecoration(labelText: 'فترة الجلسة'),
              items: sessionTimes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) async {
                setState(() => _sessionTime = v ?? _sessionTime);
                await _loadAttendanceForSession();
              },
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(child: Text('لا يوجد طلاب'))
                : ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final s = students[i];
                      final status = _attendanceStatus[s.id] ?? 'غائب';
                      final isPresent = status == 'حاضر';

                      return ListTile(
                        title: Text('${s.firstName} ${s.lastName}'),
                        subtitle: Text(
                          '${_date.toIso8601String().split('T').first} • $status',
                        ),
                        trailing: ElevatedButton.icon(
                          icon: Icon(
                            isPresent ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                          label: Text(isPresent ? 'حاضر' : 'غائب'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isPresent ? Colors.green : Colors.red,
                          ),
                          onPressed: () => _toggleAttendance(s.id!),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
