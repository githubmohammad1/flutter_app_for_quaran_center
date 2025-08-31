import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/classes.dart';

class AttendanceDataHelper {
  final List<Person> students;
  final List<Attendance> attendance;
  final int year;
  final int month;

  AttendanceDataHelper({
    required this.students,
    required this.attendance,
    required this.year,
    required this.month,
  });

  /// تصفية الحضور للشهر والسنة المحددين
  List<Attendance> get filteredAttendance {
    return attendance.where((a) {
      final date = DateTime.tryParse(a.date);
      return date != null && date.year == year && date.month == month;
    }).toList();
  }

  /// إرجاع قائمة الأيام التي فيها حضور (صباح أو مساء)
  List<int> get daysWithAttendance {
  final daysSet = <int>{};

  // نحدد عدد الأيام في الشهر أو حتى اليوم الحالي
  final totalDays = DateTime.now().year == year && DateTime.now().month == month
      ? DateTime.now().day
      : DateUtils.getDaysInMonth(year, month);

  for (int day = 1; day <= totalDays; day++) {
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));

    // نتحقق إذا فيه أي سجل حضور "حاضر" في هذا اليوم لأي طالب
    final hasAnyAttendance = filteredAttendance.any(
      (a) => a.date == dateStr && a.status == 'حاضر',
    );

    if (hasAnyAttendance) {
      daysSet.add(day);
    }
  }

  final daysList = daysSet.toList()..sort();
  return daysList;
}

  /// تجهيز بيانات الجدول
  List<Map<String, dynamic>> buildTableData() {
    final List<Map<String, dynamic>> tableData = [];
    final daysList = daysWithAttendance;

    for (final student in students) {
      final Map<int, Map<String, String>> daysMap = {};

      for (final day in daysList) {
        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, day));

        // سجل الفترة الصباحية
        final morning = filteredAttendance.firstWhere(
          (a) => a.student == student.id && a.date == dateStr && a.sessionTime == 'صباح',
          orElse: () => Attendance(
            student: student.id!,
            date: '',
            sessionTime: '',
            status: 'غائب',
          ),
        );

        // سجل الفترة المسائية
        final evening = filteredAttendance.firstWhere(
          (a) => a.student == student.id && a.date == dateStr && a.sessionTime == 'مساء',
          orElse: () => Attendance(
            student: student.id!,
            date: '',
            sessionTime: '',
            status: 'غائب',
          ),
        );

        daysMap[day] = {
          'morning': morning.status,
          'evening': evening.status,
        };
      }

      tableData.add({
        'name': '${student.firstName} ${student.lastName}',
        'days': daysMap,
      });
    }

    return tableData;
  }
}
