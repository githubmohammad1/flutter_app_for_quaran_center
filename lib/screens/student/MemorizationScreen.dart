import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_center_app/screens/widgets/MemorizationDataHelper.dart';
import 'package:quran_center_app/screens/widgets/StudentMemorizationCard.dart';
import 'package:quran_center_app/screens/widgets/StudentMemorizationDialog.dart';

import '../../providers/person_provider.dart';
import '../../providers/memorization_session_provider.dart';


class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        context.read<PersonProvider>().fetchAll(role: 'student'),
        context.read<MemorizationSessionProvider>().fetchAll(force: true),
      ]);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonProvider>();
    final mp = context.watch<MemorizationSessionProvider>();

    final isLoading = pp.isLoading || mp.isLoading;
    final error = pp.error ?? mp.error;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text(error)));
    }

    final helper = MemorizationDataHelper(
      students: pp.items.where((p) => p.role == 'student').toList(),
      sessions: mp.items,
    );

    final sortedStudents = helper.getStudentsSortedBySessions()
        .where((s) => '${s.firstName} ${s.lastName}'.contains(searchQuery))
        .toList();

    final lastSessions = helper.getLastSessionPerStudent();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سجل التسميع')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث باسم الطالب...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sortedStudents.length,
                itemBuilder: (context, index) {
                  final student = sortedStudents[index];
                  return StudentMemorizationCard(
                    student: student,
                    lastSession: lastSessions[student.id],
                    onTap: () {
                      final sessionsForStudent = helper.getSessionsForStudent(student.id!);
                      showDialog(
                        context: context,
                        builder: (_) => StudentMemorizationDialog(
                          student: student,
                          sessions: sessionsForStudent,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
