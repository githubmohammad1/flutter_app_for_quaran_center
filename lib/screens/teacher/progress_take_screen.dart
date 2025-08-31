import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Providers
import '../../../providers/person_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/memorization_session_provider.dart';

// Models
import '../../../models/classes.dart';

class AttendanceMemorizationScreen extends StatefulWidget {
  const AttendanceMemorizationScreen({super.key});

  @override
  State<AttendanceMemorizationScreen> createState() =>
      _AttendanceMemorizationScreenState();
}

class _AttendanceMemorizationScreenState
    extends State<AttendanceMemorizationScreen> {
  DateTime _workingDate = DateTime.now();
  DateTime _periodStart = DateTime(DateTime.now().year, 1, 1);
  DateTime _periodEnd = DateTime.now();

  String _sessionTime = 'صباح';
  final List<String> _sessionTimes = const ['صباح', 'مساء'];

  String _rankMode = 'attendance'; // attendance, memorization, combined

  final Map<int, String> _attendanceToday = {};

  String get _workingDateStr => DateFormat('yyyy-MM-dd').format(_workingDate);
  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await Future.wait([
        context.read<PersonProvider>().fetchAll(role: 'student'),
        context.read<AttendanceProvider>().fetchAll(force: true),
        context.read<MemorizationSessionProvider>().fetchAll(force: true),
      ]);
      _hydrateAttendanceToday();
    });
  }

  void _hydrateAttendanceToday() {
    final att = context.read<AttendanceProvider>().items;
    final students = context.read<PersonProvider>().items.where(
      (p) => p.role == 'student',
    );
    _attendanceToday.clear();
    for (final s in students) {
      final rec = att.firstWhere(
        (a) =>
            a.student == s.id &&
            a.date == _workingDateStr &&
            a.sessionTime == _sessionTime,
        orElse: () => Attendance(
          student: s.id!,
          date: '',
          sessionTime: '',
          status: 'غائب',
        ),
      );
      _attendanceToday[s.id!] = rec.status;
    }
    setState(() {});
  }

  Future<void> _toggleAttendance(int studentId) async {
    final current = _attendanceToday[studentId] ?? 'غائب';
    final newStatus = current == 'حاضر' ? 'غائب' : 'حاضر';

    final saved = await context.read<AttendanceProvider>().createOrUpdate(
      Attendance(
        student: studentId,
        date: _workingDateStr,
        sessionTime: _sessionTime,
        status: newStatus,
      ),
    );

    if (saved != null) {
      _attendanceToday[studentId] = newStatus;
      setState(() {});
    } else {
      final err = context.read<AttendanceProvider>().error ?? 'تعذر حفظ الحضور';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Map<int, double> _computeYearAttendancePercent() {
    final att = context.read<AttendanceProvider>().items;
    final year = DateTime.now().year;
    final inYear = att
        .where((a) => DateTime.parse(a.date).year == year)
        .toList();

    final totalEvents = inYear.length;
    final perStudentCount = <int, int>{};
    for (final a in inYear) {
      perStudentCount[a.student] = (perStudentCount[a.student] ?? 0) + 1;
    }

    final result = <int, double>{};
    if (totalEvents == 0) return result;
    perStudentCount.forEach((sid, count) {
      result[sid] = (count / totalEvents) * 100.0;
    });
    return result;
  }

  Map<int, int> _computePagesInPeriod() {
    final mem = context.read<MemorizationSessionProvider>().items;
    final result = <int, int>{};
    for (final m in mem) {
      final d = DateTime.tryParse(m.date);
      if (d == null) continue;
      if (d.isBefore(_periodStart) || d.isAfter(_periodEnd)) continue;
      result[m.student] = (result[m.student] ?? 0) + 1;
    }
    return result;
  }

  int get _presentCountToday {
    final att = context.read<AttendanceProvider>().items;
    return att
        .where(
          (a) =>
              a.date == _workingDateStr &&
              a.sessionTime == _sessionTime &&
              a.status == 'حاضر',
        )
        .map((a) => a.student)
        .toSet()
        .length;
  }

  int get _totalPagesToday {
    final mem = context.read<MemorizationSessionProvider>().items;
    return mem.where((m) => m.date == _workingDateStr).length;
  }

  int get _totalPagesInPeriod {
    final mem = context.read<MemorizationSessionProvider>().items;
    return mem.where((m) {
      final d = DateTime.tryParse(m.date);
      if (d == null) return false;
      return !d.isBefore(_periodStart) && !d.isAfter(_periodEnd);
    }).length;
  }

  Future<void> _pickWorkingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _workingDate = picked);
      _hydrateAttendanceToday();
    }
  }

  Future<void> _pickPeriodStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _periodStart = picked);
  }

  Future<void> _pickPeriodEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _periodEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonProvider>();
    final attP = context.watch<AttendanceProvider>();
    final memP = context.watch<MemorizationSessionProvider>();

    final isLoading = pp.isLoading || attP.isLoading || memP.isLoading;
    final hasError = (pp.error ?? attP.error ?? memP.error) != null;

    final students = pp.items.where((x) => x.role == 'student').toList();

    final yearAttendance = _computeYearAttendancePercent();
    final pagesInPeriod = _computePagesInPeriod();

    students.sort((a, b) {
      final aAtt = yearAttendance[a.id ?? -1] ?? 0.0;
      final bAtt = yearAttendance[b.id ?? -1] ?? 0.0;
      final aPages = pagesInPeriod[a.id ?? -1] ?? 0;
      final bPages = pagesInPeriod[b.id ?? -1] ?? 0;

      switch (_rankMode) {
        case 'attendance':
          return bAtt.compareTo(aAtt);
        case 'memorization':
          return bPages.compareTo(aPages);
        case 'combined':
          final maxPages = (pagesInPeriod.isEmpty)
              ? 1
              : (pagesInPeriod.values.reduce((m, v) => v > m ? v : m));
          final aScore = (aAtt / 100.0) + (aPages / maxPages);
          final bScore = (bAtt / 100.0) + (bPages / maxPages);
          return bScore.compareTo(aScore);
        default:
          return bAtt.compareTo(aAtt);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحضور والتسميع'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Future.wait([
                pp.fetchAll(role: 'student', force: true),
                attP.fetchAll(force: true),
                memP.fetchAll(force: true),
              ]);
              _hydrateAttendanceToday();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
          ? _buildError((pp.error ?? attP.error ?? memP.error)!)
          : Column(
              children: [
                _buildStatsAndFilters(),
                const Divider(height: 0),
                Expanded(
                  child: students.isEmpty
                      ? const Center(child: Text('لا يوجد طلاب'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                          itemCount: students.length,
                          itemBuilder: (_, i) {
                            final s = students[i];
                            final isPresent =
                                (_attendanceToday[s.id ?? -1] ?? 'غائب') ==
                                'حاضر';

                            return GestureDetector(
                              onTap: () => _openMemorizationSheet(s),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  child: Text(
                                                    s.firstName.isNotEmpty
                                                        ? s.firstName[0]
                                                        : '?',
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${s.firstName} ${s.lastName}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            _TinyStatRow(
                                              leftLabel: 'الحضور السنوي',
                                              leftValue:
                                                  '${(yearAttendance[s.id ?? -1] ?? 0).toStringAsFixed(1)}%',
                                              rightLabel: 'صفحات الفترة',
                                              rightValue:
                                                  '${pagesInPeriod[s.id ?? -1] ?? 0}',
                                            ),
                                            const Spacer(),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                'حضور ${_sessionTime}: ${isPresent ? 'حاضر' : 'غائب'}',
                                                style: TextStyle(
                                                  color: isPresent
                                                      ? Colors.green
                                                      : Colors.redAccent,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 44,
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        onPressed: () =>
                                            _toggleAttendance(s.id!),
                                        icon: Icon(
                                          isPresent
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        label: Text(
                                          isPresent ? 'وضع كغائب' : 'وضع كحاضر',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: isPresent
                                              ? Colors.green
                                              : Colors.redAccent.shade100,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              bottom: Radius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // تابع عرض رسالة الخطأ
  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await Future.wait([
                  context.read<PersonProvider>().fetchAll(
                    role: 'student',
                    force: true,
                  ),
                  context.read<AttendanceProvider>().fetchAll(force: true),
                  context.read<MemorizationSessionProvider>().fetchAll(
                    force: true,
                  ),
                ]);
                _hydrateAttendanceToday();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // تابع شريط الإحصائيات والفلاتر
  Widget _buildStatsAndFilters() {
    return Container(
      color: Colors.blueGrey.withOpacity(0.04),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: 'الحاضرين ($_sessionTime)',
                value: '$_presentCountToday',
                color: Colors.green,
              ),
              _StatChip(
                label: 'صفحات اليوم',
                value: '$_totalPagesToday',
                color: Colors.blue,
              ),
              _StatChip(
                label: 'صفحات الفترة',
                value: '$_totalPagesInPeriod',
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FilterTile(
                  title: 'تاريخ اليوم',
                  value: _workingDateStr,
                  icon: Icons.today,
                  onTap: _pickWorkingDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sessionTime,
                  decoration: const InputDecoration(
                    labelText: 'فترة الجلسة للحضور',
                    border: OutlineInputBorder(),
                  ),
                  items: _sessionTimes
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _sessionTime = v ?? _sessionTime);
                    _hydrateAttendanceToday();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FilterTile(
                  title: 'بداية الفترة',
                  value: _fmtDate(_periodStart),
                  icon: Icons.date_range,
                  onTap: _pickPeriodStart,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterTile(
                  title: 'نهاية الفترة',
                  value: _fmtDate(_periodEnd),
                  icon: Icons.event_available,
                  onTap: _pickPeriodEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _rankMode,
            decoration: const InputDecoration(
              labelText: 'ترتيب الطلاب حسب',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'attendance',
                child: Text('الالتزام (الحضور السنوي)'),
              ),
              DropdownMenuItem(
                value: 'memorization',
                child: Text('التسميع (صفحات الفترة)'),
              ),
              DropdownMenuItem(value: 'combined', child: Text('كلاهما معًا')),
            ],
            onChanged: (v) => setState(() => _rankMode = v ?? _rankMode),
          ),
        ],
      ),
    );
  }

  // تابع فتح نافذة التسميع
  void _openMemorizationSheet(Person student) {
    final memAll = context
        .read<MemorizationSessionProvider>()
        .items
        .where((m) => m.student == student.id)
        .toList();
    final memorizedPages = memAll.map((m) => m.pageNumber).toSet();
    final lastByDate = memAll.isEmpty
        ? null
        : memAll
              .reduce(
                (a, b) => DateTime.parse(a.date).isAfter(DateTime.parse(b.date))
                    ? a
                    : b,
              )
              .pageNumber;
    final initialGroupIndex = ((lastByDate ?? 1) - 1) ~/ 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MemorizationSheet(
        student: student,
        workingDateStr: _workingDateStr,
        initialGroupIndex: initialGroupIndex,
        memorizedPages: memorizedPages,
      ),
    );
  }
}

class _TinyStatRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _TinyStatRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text('$leftLabel: $leftValue', style: textStyle)),
        Expanded(child: Text('$rightLabel: $rightValue', style: textStyle)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withOpacity(0.08),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _FilterTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }
}

class _MemorizationSheet extends StatefulWidget {
  final Person student;
  final String workingDateStr;
  final int initialGroupIndex;
  final Set<int> memorizedPages;

  const _MemorizationSheet({
    required this.student,
    required this.workingDateStr,
    required this.initialGroupIndex,
    required this.memorizedPages,
  });

  @override
  State<_MemorizationSheet> createState() => _MemorizationSheetState();
}

class _MemorizationSheetState extends State<_MemorizationSheet> {
  final List<String> _grades = const ['جيد', 'جيد جداً', 'ممتاز'];
  String _selectedGrade = 'ممتاز';

  final Set<int> _selectedPages = {};
  late int _expandedGroup;

  bool _isSaving = false; // مؤشر تحميل أثناء الحفظ

  @override
  void initState() {
    super.initState();
    _expandedGroup = widget.initialGroupIndex.clamp(0, 60); // 604/10 ≈ 60
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس النافذة
            Row(
              children: [
                Expanded(
                  child: Text(
                    'تسميع: ${widget.student.firstName} ${widget.student.lastName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context,true),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // اختيار التقدير + الانتقال السريع
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    decoration: const InputDecoration(
                      labelText: 'التقدير',
                      border: OutlineInputBorder(),
                    ),
                    items: _grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedGrade = v ?? _selectedGrade),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _expandedGroup,
                    decoration: const InputDecoration(
                      labelText: 'انتقال سريع (مجاميع 10 صفحات)',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      61,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${i * 10 + 1}-${(i * 10 + 10).clamp(1, 604)}',
                        ),
                      ),
                    ),
                    onChanged: (v) => setState(
                      () => _expandedGroup = (v ?? _expandedGroup).clamp(0, 60),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // قائمة المجموعات
            Expanded(
              child: ListView.builder(
                itemCount: 61,
                itemBuilder: (_, i) {
                  final start = i * 10 + 1;
                  final end = (i * 10 + 10).clamp(1, 604);
                  final pages = [for (int p = start; p <= end; p++) p];
                  final isExpanded = _expandedGroup == i;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ExpansionTile(
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (v) {
                        if (v) setState(() => _expandedGroup = i);
                      },
                      title: Text('الصفحات $start - $end'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: pages.map((p) {
                              final alreadyMem = widget.memorizedPages.contains(
                                p,
                              );
                              final selected = _selectedPages.contains(p);
                              final bgColor = selected
                                  ? Colors.blue
                                  : (alreadyMem
                                        ? Colors.green
                                        : Colors.grey.shade300);
                              final fgColor = selected || alreadyMem
                                  ? Colors.white
                                  : Colors.black87;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_selectedPages.contains(p)) {
                                      _selectedPages.remove(p);
                                    } else {
                                      _selectedPages.add(p);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'ص $p',
                                    style: TextStyle(
                                      color: fgColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // أزرار الحفظ
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectedPages.isEmpty
                        ? null
                        : () => setState(() => _selectedPages.clear()),
                    child: const Text('مسح التحديد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      'حفظ (${_selectedPages.length})',
                    ), // ← هنا التغيير
                    onPressed: _selectedPages.isEmpty || _isSaving
                        ? null
                        : _saveSelection,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSelection() async {
    final memP = context.read<MemorizationSessionProvider>();
    setState(() => _isSaving = true);

    try {
      await Future.wait(
        _selectedPages.map((p) {
          return memP.create(
            MemorizationSession(
              student: widget.student.id!,
              pageNumber: p,
              grade: _selectedGrade,
              date: widget.workingDateStr,
              teacher: null,
            ),
          );
        }),
      );

      // تحديث البيانات فورًا
      await memP.fetchAll(force: true);

      if (mounted) {
        Navigator.pop(context,true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ ${_selectedPages.length} صفحة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
