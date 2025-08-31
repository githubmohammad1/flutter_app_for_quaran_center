import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers
import '../../providers/announcement_provider.dart';
import '../../providers/person_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/memorization_session_provider.dart';
import '../widgets/app_drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<Map<String, dynamic>> _topMemorization = [];
  List<Map<String, dynamic>> _topAttendance = [];
  List<String> _announcements = [];

  bool _loading = true;
  String? _error;
  String studentName = '';
  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    final first = prefs.getString('student_first_name') ?? '';
    final father = prefs.getString('student_father_name') ?? '';
    final last = prefs.getString('student_last_name') ?? '';
    setState(() {
      studentName = '$first $father $last'.trim();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadStudentName();

    Future.microtask(() async {
      try {
        await Future.wait([
          context.read<PersonProvider>().fetchAll(role: 'student'),
          context.read<AttendanceProvider>().fetchAll(force: true),
          context.read<MemorizationSessionProvider>().fetchAll(force: true),
          context.read<AnnouncementProvider>().fetchAll(force: true),
        ]);
        _computeTops();
        if (mounted) setState(() => _loading = false);
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.toString();
          });
        }
      }
    });
  }

  void _computeTops() {
    final students = context
        .read<PersonProvider>()
        .items
        .where((p) => p.role == 'student')
        .toList();
    final attendance = context.read<AttendanceProvider>().items;
    final memorization = context.read<MemorizationSessionProvider>().items;
    final announcements = context.read<AnnouncementProvider>().items;
    final currentYear = DateTime.now().year;

    // ✅ تجهيز آخر 3 إعلانات
    final sortedAnnouncements = [...announcements]
      ..sort((a, b) => b.date.compareTo(a.date)); // الأحدث أولاً
    final latestThree = sortedAnnouncements.take(3).toList();

    _announcements = latestThree.isEmpty
        ? ['لا توجد إعلانات']
        : latestThree.map((a) {
            final dateStr =
                '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}';
            return '${a.content}  📅 $dateStr';
          }).toList();

    // الأكثر تسميعًا
    final memCount = <int, int>{};
    for (final m in memorization) {
      final d = DateTime.tryParse(m.date);
      if (d == null || d.year != currentYear) continue;
      memCount[m.student] = (memCount[m.student] ?? 0) + 1;
    }
    final memList =
        students
            .map(
              (s) => {
                'name': '${s.firstName} ${s.lastName}'.trim().isEmpty
                    ? 'طالب ${s.id}'
                    : '${s.firstName} ${s.lastName}',
                'count': memCount[s.id ?? -1] ?? 0,
              },
            )
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    _topMemorization = memList.take(3).toList();

    // الأكثر التزامًا
    final attInYear = attendance.where((a) {
      final d = DateTime.tryParse(a.date);
      return d != null && d.year == currentYear;
    }).toList();
    final totalEvents = attInYear.length;
    final presentCount = <int, int>{};
    for (final a in attInYear) {
      if (a.status == 'حاضر') {
        presentCount[a.student] = (presentCount[a.student] ?? 0) + 1;
      }
    }
    final attList =
        students.map((s) {
          final present = presentCount[s.id ?? -1] ?? 0;
          final pct = totalEvents == 0 ? 0.0 : (present / totalEvents) * 100.0;
          return {
            'name': '${s.firstName} ${s.lastName}'.trim().isEmpty
                ? 'طالب ${s.id}'
                : '${s.firstName} ${s.lastName}',
            'pct': pct,
          };
        }).toList()..sort(
          (a, b) => (b['pct'] as double).compareTo(a['pct'] as double),
        );
    _topAttendance = attList.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonProvider>();
    final attP = context.watch<AttendanceProvider>();
    final memP = context.watch<MemorizationSessionProvider>();

    final isLoading =
        _loading || pp.isLoading || attP.isLoading || memP.isLoading;
    final providerError = pp.error ?? attP.error ?? memP.error;
    final errorText = _error ?? providerError;

    final actions = [
      {'label': '📋 سجل الحضور', 'route': '/attendanceHistory'},
      {'label': '📖 سجل التسميع', 'route': '/recitationHistory'},
      {'label': '📝 الاختبارات', 'route': '/testsView'},
      // {'label': '🏅 لوحة الشرف', 'route': '/honorBoard'},
      // {'label': '📢 الإعلانات', 'route': '/announcements'},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
         title: Text(studentName.isEmpty ? 'لوحة الطالب' : studentName),
        centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : errorText != null
                ? Center(
                    child: Text(
                      errorText,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        context.read<PersonProvider>().fetchAll(
                          role: 'student',
                          force: true,
                        ),
                        context.read<AttendanceProvider>().fetchAll(
                          force: true,
                        ),
                        context.read<MemorizationSessionProvider>().fetchAll(
                          force: true,
                        ),
                      ]);
                      _computeTops();
                      if (mounted) setState(() {});
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      
                          _buildStatsSection(),
                          const SizedBox(height: 20),
                          _buildActionsGrid(actions),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // ✅ بطاقة الإعلانات
          _StatsCard(
            title: '📢 الإعلانات',
            lines: _announcements,
            gradient: const LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _StatsCard(
            title: '🏆 الأكثر تسميعًا',
            lines: _topMemorization.isEmpty
                ? const ['لا توجد بيانات']
                : _topMemorization
                      .map((e) => '${e['name']} - ${e['count']} صفحة')
                      .toList(),
            gradient: const LinearGradient(
              colors: [Color(0xFFff9966), Color(0xFFff5e62)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          _StatsCard(
            title: '📅 الأكثر التزامًا',
            lines: _topAttendance.isEmpty
                ? const ['لا توجد بيانات']
                : _topAttendance
                      .map(
                        (e) => '${e['name']} - ${e['pct'].toStringAsFixed(1)}%',
                      )
                      .toList(),
            gradient: const LinearGradient(
              colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(List<Map<String, String>> actions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, item['route']!),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                item['label']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Gradient gradient;

  const _StatsCard({
    required this.title,
    required this.lines,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in lines.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                s,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
