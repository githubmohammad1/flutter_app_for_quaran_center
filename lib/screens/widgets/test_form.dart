import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/classes.dart';
import '../../../providers/quran_test_provider.dart';
import '../../../providers/person_provider.dart';

class QuranTestForm extends StatefulWidget {
  final QuranPartTest? initial;
  const QuranTestForm({super.key, this.initial});

  @override
  State<QuranTestForm> createState() => _QuranTestFormState();
}

class _QuranTestFormState extends State<QuranTestForm> {
  final _formKey = GlobalKey<FormState>();

  int? _studentId;
  int? _teacherId;
  String _teacherName = '';
  late int _partNumber;
  String _grade = 'جيد';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<PersonProvider>().fetchAll(role: 'student');
      await _loadTeacherData();
    });

    if (widget.initial != null) {
      final t = widget.initial!;
      _studentId = t.student;
      _partNumber = t.partNumber;
      _grade = t.grade;
      _date = DateTime.tryParse(t.date) ?? DateTime.now();
    } else {
      _partNumber = 1;
    }
  }

  Future<void> _loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _teacherId = prefs.getInt('teacher_id');
      final first = prefs.getString('teacher_first_name') ?? '';
      final last = prefs.getString('teacher_last_name') ?? '';
      _teacherName = '$first $last'.trim();
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20), // ✅ حواف دائرية
        borderSide: const BorderSide(color: Colors.grey),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grades = const ['جيد', 'جيد جداً', 'ممتاز'];
    final isEdit = widget.initial != null;

    final pp = context.watch<PersonProvider>();
    final students = pp.items.where((p) => p.role == 'student').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل اختبار' : 'إضافة اختبار'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: pp.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (_teacherName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'المعلم: $_teacherName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      // اختيار الطالب
                      DropdownButtonFormField<int>(
                        value: _studentId,
                        decoration: _inputDecoration('الطالب'),
                        borderRadius: BorderRadius.circular(20), // ✅ حواف دائرية
                        items: students
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text('${s.firstName} ${s.lastName}'),
                                ))
                            .toList(),
                        validator: (v) => v == null ? 'اختر الطالب' : null,
                        onChanged: (v) => setState(() => _studentId = v),
                      ),
                      const SizedBox(height: 12),

                      // رقم الجزء
                      TextFormField(
                        initialValue: _partNumber.toString(),
                        decoration: _inputDecoration('رقم الجزء'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'أدخل رقم الجزء';
                          final n = int.tryParse(v);
                          if (n == null || n <= 0 || n > 30) return 'رقم غير صالح';
                          return null;
                        },
                        onSaved: (v) => _partNumber = int.parse(v!),
                      ),
                      const SizedBox(height: 12),

                      // التقدير
                      DropdownButtonFormField<String>(
                        value: _grade,
                        decoration: _inputDecoration('التقدير'),
                        borderRadius: BorderRadius.circular(20), // ✅ حواف دائرية
                        items: grades
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _grade = v ?? _grade),
                      ),
                      const SizedBox(height: 12),

                      // التاريخ
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // ✅ حواف دائرية
                          side: const BorderSide(color: Colors.grey),
                        ),
                        title: const Text('التاريخ'),
                        subtitle: Text(_date.toIso8601String().split('T').first),
                        trailing: const Icon(Icons.date_range),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // ✅ حواف دائرية
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(isEdit ? 'حفظ' : 'إضافة'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_teacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على رقم المعلم')),
      );
      return;
    }

    // ✅ عرض رسالة بالمعلومات المدخلة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '📌 البيانات:\nالمعلم: $_teacherName\nالطالب ID: $_studentId\nرقم الجزء: $_partNumber\nالتقدير: $_grade\nالتاريخ: ${_date.toIso8601String().split('T').first}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    final provider = context.read<QuranTestProvider>();
    final test = QuranPartTest(
      id: widget.initial?.id,
      student: _studentId!,
      teacher: _teacherId!,
      partNumber: _partNumber,
      date: _date.toIso8601String().split('T').first,
      grade: _grade,
    );

    try {
      if (widget.initial == null) {
        await provider.create(test);
      } else {
        // دعم التعديل إذا رغبت
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e')),
      );
    }
  }
}
