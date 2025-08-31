import 'package:flutter/material.dart';
import '../../models/classes.dart';

class StudentMemorizationDialog extends StatelessWidget {
  final Person student;
  final List<MemorizationSession> sessions;

  const StudentMemorizationDialog({
    super.key,
    required this.student,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تسميع ${student.firstName} ${student.lastName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: sessions.isEmpty
            ? const Text('لا يوجد تسميع')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  return ListTile(
                    leading: const Icon(Icons.bookmark, color: Colors.green),
                    title: Text('صفحة ${s.pageNumber}'),
                    subtitle: Text('التاريخ: ${s.date} - التقدير: ${s.grade}'),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
