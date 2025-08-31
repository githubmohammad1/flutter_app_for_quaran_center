import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/person_provider.dart';
import '../../providers/attendance_provider.dart';

import '../widgets/attendance_data_helper.dart';
import '../widgets/attendance_table_widget.dart';

class AttendanceTableScreen extends StatefulWidget {
  const AttendanceTableScreen({super.key});

  @override
  State<AttendanceTableScreen> createState() => _AttendanceTableScreenState();
}

class _AttendanceTableScreenState extends State<AttendanceTableScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        context.read<PersonProvider>().fetchAll(role: 'student'),
        context.read<AttendanceProvider>().fetchAll(force: true),
      ]);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonProvider>();
    final attP = context.watch<AttendanceProvider>();

    final isLoading = pp.isLoading || attP.isLoading;
    final error = pp.error ?? attP.error;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text(error)));
    }

    final helper = AttendanceDataHelper(
      students: pp.items.where((p) => p.role == 'student').toList(),
      attendance: attP.items,
      year: selectedYear,
      month: selectedMonth,
    );

    final daysList = helper.daysWithAttendance;
    final tableData = helper.buildTableData();

    return Scaffold(
        appBar: AppBar(title: const Text('سجل الحضور')),
        body: Column(
          children: [
            _buildFilters(),
            const SizedBox(height: 10),
            Expanded(
              child: daysList.isEmpty
                  ? const Center(child: Text('لا توجد بيانات حضور'))
                  : AttendanceTableWidget(
                      tableData: tableData,
                      daysList: daysList,
                      year: selectedYear,
                      month: selectedMonth,
                    ),
            ),
          ],
        ),
      
    );
  }

  Widget _buildFilters() {
    final years = List.generate(5, (i) => DateTime.now().year - i);
    final months = List.generate(12, (i) => i + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<int>(
          value: selectedYear,
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
              .toList(),
          onChanged: (v) => setState(() => selectedYear = v!),
        ),
        const SizedBox(width: 20),
        DropdownButton<int>(
          value: selectedMonth,
          items: months
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat.MMMM('ar').format(DateTime(0, m))),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedMonth = v!),
        ),
      ],
    );
  }
}
