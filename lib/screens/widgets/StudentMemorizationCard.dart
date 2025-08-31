import 'package:flutter/material.dart';
import '../../models/classes.dart';

class StudentMemorizationCard extends StatelessWidget {
  final Person student;
  final MemorizationSession? lastSession;
  final VoidCallback onTap;

  const StudentMemorizationCard({
    super.key,
    required this.student,
    required this.lastSession,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green,
                child: Icon(Icons.menu_book, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.firstName} ${student.lastName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (lastSession != null)
                      Text(
                        'آخر صفحة: ${lastSession!.pageNumber} - ${lastSession!.date}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    else
                      const Text(
                        'لا يوجد تسميع',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
