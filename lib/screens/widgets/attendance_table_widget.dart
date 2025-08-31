import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tableData;
  final List<int> daysList;
  final int year;
  final int month;

  const AttendanceTableWidget({
    super.key,
    required this.tableData,
    required this.daysList,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // تمرير أفقي
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical, // تمرير عمودي
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),

          border: TableBorder.all(color: Colors.grey.shade300),
          columns: [
            const DataColumn(label: Text('الطالب')),
            for (final day in daysList) ...[
              DataColumn(
                label: Text(
                  '${_getDayName(DateTime(year, month, day))}\n${DateFormat('dd/MM').format(DateTime(year, month, day))} ص',
                  textAlign: TextAlign.center,
                ),
              ),
              DataColumn(
                label: Text(
                  '${_getDayName(DateTime(year, month, day))}\n${DateFormat('dd/MM').format(DateTime(year, month, day))} م',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
          rows: tableData.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(row['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                for (final day in daysList) ...[
                  DataCell(_buildCell(row['days'][day]?['morning'] ?? 'غائب')),
                  DataCell(_buildCell(row['days'][day]?['evening'] ?? 'غائب')),
                ],
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = [
      'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'
    ];
    return days[date.weekday - 1];
  }

  Widget _buildCell(String status) {
    final isPresent = status == 'حاضر';
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        isPresent ? Icons.check : Icons.close,
        color: isPresent ? Colors.green : Colors.red,
        size: 18,
      ),
    );
  }
}
