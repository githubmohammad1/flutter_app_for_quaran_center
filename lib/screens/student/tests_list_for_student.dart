import 'package:provider/provider.dart';
import 'package:quran_center_app/providers/person_provider.dart';
import 'package:quran_center_app/providers/quran_test_provider.dart';

import '../../models/classes.dart';
import 'package:flutter/material.dart';
class TestDataHelper {
  final List<Person> students;
  final List<QuranPartTest> tests;

  TestDataHelper({
    required this.students,
    required this.tests,
  });

  /// ترتيب الطلاب حسب عدد الاختبارات (الأكثر أولاً)
  List<Person> getStudentsSortedByTests() {
    final counts = <int, int>{};
    for (final t in tests) {
      counts[t.student] = (counts[t.student] ?? 0) + 1;
    }
    final sorted = [...students];
    sorted.sort((a, b) {
      final countA = counts[a.id] ?? 0;
      final countB = counts[b.id] ?? 0;
      return countB.compareTo(countA);
    });
    return sorted;
  }

  /// آخر اختبار لكل طالب
  Map<int, QuranPartTest> getLastTestPerStudent() {
    final Map<int, QuranPartTest> lastTests = {};
    for (final t in tests) {
      if (!lastTests.containsKey(t.student) ||
          DateTime.parse(t.date).isAfter(DateTime.parse(lastTests[t.student]!.date))) {
        lastTests[t.student] = t;
      }
    }
    return lastTests;
  }

  /// اختبارات طالب معين
  List<QuranPartTest> getTestsForStudent(int studentId) {
    final studentTests = tests.where((t) => t.student == studentId).toList();
    studentTests.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    return studentTests;
  }
}



class StudentCard extends StatelessWidget {
  final Person student;
  final QuranPartTest? lastTest;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.lastTest,
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
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
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
                    if (lastTest != null)
                      Text(
                        'آخر جزء: ${lastTest!.partNumber} - ${lastTest!.date}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      )
                    else
                      const Text(
                        'لا يوجد اختبارات',
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


class StudentTestsDialog extends StatelessWidget {
  final Person student;
  final List<QuranPartTest> tests;

  const StudentTestsDialog({
    super.key,
    required this.student,
    required this.tests,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('اختبارات ${student.firstName} ${student.lastName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: tests.isEmpty
            ? const Text('لا يوجد اختبارات')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: tests.length,
                itemBuilder: (context, index) {
                  final t = tests[index];
                  return ListTile(
                    leading: const Icon(Icons.menu_book, color: Colors.blueAccent),
                    title: Text('جزء ${t.partNumber}'),
                    subtitle: Text('التاريخ: ${t.date} - التقدير: ${t.grade}'),
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








class TestsScreen extends StatefulWidget {
  const TestsScreen({super.key});

  @override
  State<TestsScreen> createState() => _TestsScreenState();
}

class _TestsScreenState extends State<TestsScreen> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        context.read<PersonProvider>().fetchAll(role: 'student'),
        context.read<QuranTestProvider>().fetchAll(force: true),
      ]);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonProvider>();
    final tp = context.watch<QuranTestProvider>();

    final isLoading = pp.isLoading || tp.isLoading;
    final error = pp.error ?? tp.error;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text(error)));
    }

    final helper = TestDataHelper(
      students: pp.items.where((p) => p.role == 'student').toList(),
      tests: tp.items,
    );

    final sortedStudents = helper.getStudentsSortedByTests()
        .where((s) => '${s.firstName} ${s.lastName}'.contains(searchQuery))
        .toList();

    final lastTests = helper.getLastTestPerStudent();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة الاختبارات')),
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
                  return StudentCard(
                    student: student,
                    lastTest: lastTests[student.id],
                    onTap: () {
                      final testsForStudent = helper.getTestsForStudent(student.id!);
                      showDialog(
                        context: context,
                        builder: (_) => StudentTestsDialog(
                          student: student,
                          tests: testsForStudent,
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
