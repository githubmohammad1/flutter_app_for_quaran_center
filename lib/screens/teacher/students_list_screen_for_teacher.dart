import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/person_provider.dart';
import '../../providers/memorization_session_provider.dart';
import '../../providers/quran_test_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/classes.dart';
import '../widgets/person_form.dart';

/// شاشة عرض قائمة الطلاب
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    final ctx = context;
    await ctx.read<PersonProvider>().fetchAll(role: 'student', force: true);
    await ctx.read<MemorizationSessionProvider>().fetchAll();
    await ctx.read<QuranTestProvider>().fetchAll();
    await ctx.read<AttendanceProvider>().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final personProv = context.watch<PersonProvider>();
    final memProv = context.watch<MemorizationSessionProvider>();
    final testProv = context.watch<QuranTestProvider>();
    final attProv = context.watch<AttendanceProvider>();

    if (personProv.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (personProv.error != null) {
      return Scaffold(body: Center(child: Text('خطأ: ${personProv.error}')));
    }

    final students = personProv.items.where((x) => x.role == 'student').toList();
    if (students.isEmpty) {
      return const Scaffold(body: Center(child: Text('لا يوجد طلاب')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الطلاب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];

            // آخر صفحة مسموعة من جلسات التسميع
            final pagesForStudent = memProv.items
                .where((p) => p.student == s.id)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
            final lastPage = pagesForStudent.isNotEmpty
                ? pagesForStudent.first.pageNumber
                : null;

            return StudentCard(
              student: s,
              lastPage: lastPage,
              phone: s.phone,
              onTap: () => _showStudentDetails(
                context,
                s,
                pagesForStudent,
                testProv.items,
                attProv.items,
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PersonForm(role: 'student')),
          );
          if (saved == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت الإضافة')),
            );
            await _fetchAllData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة طالب'),
      ),
    );
  }

  void _showStudentDetails(
    BuildContext context,
    Person student,
    List<MemorizationSession> pages,
    List<QuranPartTest> tests,
    List<Attendance> attendance,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StudentDetailsSheet(
        student: student,
        pages: pages,
        tests: tests,
        attendance: attendance,
      ),
    );
  }
}

/// بطاقة الطالب في القائمة
class StudentCard extends StatelessWidget {
  final Person student;
  final int? lastPage;
  final String? phone;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.student,
    required this.lastPage,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.firstName.isNotEmpty ? student.firstName[0] : '?'),
        ),
        title: Text('${student.firstName} ${student.lastName}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastPage != null)
              Text('📖 آخر صفحة: $lastPage', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (phone != null && phone!.isNotEmpty)
              SelectableText(phone!, style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// نافذة تفاصيل الطالب
class StudentDetailsSheet extends StatelessWidget {
  final Person student;
  final List<MemorizationSession> pages;
  final List<QuranPartTest> tests;
  final List<Attendance> attendance;

  const StudentDetailsSheet({
    super.key,
    required this.student,
    required this.pages,
    required this.tests,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = pages.length;
    final studentTests = tests.where((t) => t.student == student.id).toList();
    final Map<int, double> attendancePercentages =
        _calculateAttendancePercentages(attendance);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text('${student.firstName} ${student.lastName}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (student.phone != null && student.phone!.isNotEmpty)
            SelectableText('📞 ${student.phone!}'),
          const Divider(),
          Text('📖 عدد الصفحات المسمعة: $totalPages'),
          const SizedBox(height: 8),
          Text('📝 الأجزاء المختبرة: ${studentTests.map((t) => t.partNumber).join(', ')}'),
          const SizedBox(height: 8),
          const Text('📊 نسبة الدوام لكل سنة:'),
          ...attendancePercentages.entries.map(
            (e) => Text('${e.key}: ${e.value.toStringAsFixed(1)}%'),
          ),
        ],
      ),
    );
  }

  Map<int, double> _calculateAttendancePercentages(List<Attendance> attendance) {
    final Map<int, double> percentages = {};
    final allAttendanceByYear = <int, int>{};
    final studentAttendanceByYear = <int, int>{};

    for (var a in attendance) {
      final year = DateTime.parse(a.date).year;
      allAttendanceByYear[year] = (allAttendanceByYear[year] ?? 0) + 1;
      if (a.student == student.id) {
        studentAttendanceByYear[year] =
            (studentAttendanceByYear[year] ?? 0) + 1;
      }
    }

    for (var year in allAttendanceByYear.keys) {
      final total = allAttendanceByYear[year]!;
      final studentCount = studentAttendanceByYear[year] ?? 0;
      percentages[year] =
          total > 0 ? (studentCount / total) * 100 : 0;
    }

    return percentages;
  }
}
