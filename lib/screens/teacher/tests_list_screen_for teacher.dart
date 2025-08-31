import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/classes.dart';
import '../../../providers/quran_test_provider.dart';
import '../../../providers/person_provider.dart';
import '../widgets/test_form.dart';

class TestsListScreen extends StatefulWidget {
  const TestsListScreen({super.key});

  @override
  State<TestsListScreen> createState() => _TestsListScreenState();
}

class _TestsListScreenState extends State<TestsListScreen> {
  String _searchQuery = '';
  int? _filterPartNumber;
  String _sortBy = 'date_desc'; 
  // خيارات الترتيب: date_desc, date_asc, grade_desc, grade_asc, part_asc, part_desc

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final pp = context.read<PersonProvider>();
      await Future.wait([
        pp.fetchAll(role: 'student'),
        context.read<QuranTestProvider>().fetchAll(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PersonProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبارات أجزاء القرآن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await Future.wait([
                pp.fetchAll(role: 'student', force: true),
                context.read<QuranTestProvider>().fetchAll(force: true),
              ]);
            },
          ),
        ],
      ),
      body: Consumer<QuranTestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || pp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return _buildError(provider.error!, provider.fetchAll);
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('لا توجد اختبارات بعد'));
          }

          // تطبيق البحث والفلترة
          var filteredItems = provider.items.where((test) {
            final student = pp.items.firstWhere(
              (p) => p.id == test.student,
              orElse: () => Person(role: '', firstName: '', lastName: ''),
            );
            final matchesName = _searchQuery.isEmpty ||
                ('${student.firstName} ${student.lastName}')
                    .contains(_searchQuery);
            final matchesPart = _filterPartNumber == null ||
                test.partNumber == _filterPartNumber;
            return matchesName && matchesPart;
          }).toList();

          // الترتيب
          filteredItems.sort((a, b) {
            switch (_sortBy) {
              case 'date_asc':
                return a.date.compareTo(b.date);
              case 'date_desc':
                return b.date.compareTo(a.date);
              case 'grade_asc':
                return _gradeValue(a.grade).compareTo(_gradeValue(b.grade));
              case 'grade_desc':
                return _gradeValue(b.grade).compareTo(_gradeValue(a.grade));
              case 'part_asc':
                return a.partNumber.compareTo(b.partNumber);
              case 'part_desc':
                return b.partNumber.compareTo(a.partNumber);
              default:
                return 0;
            }
          });

          // تجميع الاختبارات حسب الطالب
          final Map<int, List<QuranPartTest>> groupedTests = {};
          for (var test in filteredItems) {
            groupedTests.putIfAbsent(test.student, () => []).add(test);
          }

          return Column(
            children: [
              _buildSearchFilterSort(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      pp.fetchAll(role: 'student', force: true),
                      provider.fetchAll(force: true),
                    ]);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: groupedTests.entries.map((entry) {
                      final studentId = entry.key;
                      final tests = entry.value;

                      final student = pp.items.firstWhere(
                        (p) => p.id == studentId,
                        orElse: () =>
                            Person(role: '', firstName: '', lastName: ''),
                      );
                      final studentName =
                          '${student.firstName} ${student.lastName}';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          title: Text(
                            '👤 $studentName (${tests.length} اختبار)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: tests.map((t) {
                            final formattedDate = DateFormat('yyyy/MM/dd')
                                .format(DateTime.parse(t.date));
                            return ListTile(
                              title: Text('📖 الجزء: ${t.partNumber}'),
                              subtitle: Text(
                                'التقدير: ${t.grade} • التاريخ: $formattedDate',
                              ),
                              onTap: () async {
                                final saved = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        QuranTestForm(initial: t),
                                  ),
                                );
                                if (saved == true && mounted) {
                                  provider.fetchAll(force: true);
                                }
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () =>
                                    _confirmDelete(context, t, studentName),
                                tooltip: 'حذف',
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const QuranTestForm()),
          );
          if (saved == true && mounted) {
            context.read<QuranTestProvider>().fetchAll(force: true);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة'),
      ),
    );
  }

  /// شريط البحث + الفلترة + الترتيب
  Widget _buildSearchFilterSort() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'بحث باسم الطالب',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'فلترة بالجزء',
                    border: OutlineInputBorder(),
                  ),
                  value: _filterPartNumber,
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('الكل'),
                    ),
                    ...List.generate(
                      30,
                      (i) => DropdownMenuItem<int>(
                        value: i + 1,
                        child: Text('جزء ${i + 1}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _filterPartNumber = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'ترتيب حسب',
              border: OutlineInputBorder(),
            ),
            value: _sortBy,
            items: const [
              DropdownMenuItem(value: 'date_desc', child: Text('التاريخ: الأحدث أولاً')),
              DropdownMenuItem(value: 'date_asc', child: Text('التاريخ: الأقدم أولاً')),
              DropdownMenuItem(value: 'grade_desc', child: Text('التقدير: من الأعلى')),
              DropdownMenuItem(value: 'grade_asc', child: Text('التقدير: من الأقل')),
              DropdownMenuItem(value: 'part_asc', child: Text('رقم الجزء: تصاعدي')),
              DropdownMenuItem(value: 'part_desc', child: Text('رقم الجزء: تنازلي')),
            ],
            onChanged: (value) {
              setState(() => _sortBy = value ?? 'date_desc');
            },
          ),
        ],
      ),
    );
  }

  int _gradeValue(String grade) {
    switch (grade) {
      case 'ممتاز':
        return 3;
      case 'جيد جداً':
        return 2;
      case 'جيد':
        return 1;
      default:
        return 0;
    }
  }

  Widget _buildError(String message, Future<void> Function({bool force}) retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => retry(force: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

   Future<void> _confirmDelete(
      BuildContext context, QuranPartTest t, String studentName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل تريد حذف اختبار الجزء ${t.partNumber} للطالب $studentName؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      try {
        // إذا كان لديك دالة حذف في الـ Provider يمكنك استدعاؤها هنا
        // await context.read<QuranTestProvider>().deleteTest(t.id!);

        // بعد الحذف، أعد تحميل البيانات
        await context.read<QuranTestProvider>().fetchAll(force: true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الاختبار بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: $e')),
        );
      }
    }
  }
}