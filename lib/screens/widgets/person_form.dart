import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/classes.dart';
import '../../providers/person_provider.dart';

class PersonForm extends StatefulWidget {
  final Person? initial;
  final String role; // 'student' أو 'teacher'

  const PersonForm({super.key, this.initial, this.role = 'student'});

  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final _formKey = GlobalKey<FormState>();

  late String _firstName;
  late String _lastName;
  String? _fatherName;
  String? _motherName;
  DateTime? _dateOfBirth;
  String? _phone;
  String? _specialization; // للأستاذ فقط

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    if (p != null) {
      _firstName = p.firstName;
      _lastName = p.lastName;
      _fatherName = p.fatherName;
      _motherName = p.motherName;
      _dateOfBirth =
          p.dateOfBirth != null ? DateTime.tryParse(p.dateOfBirth!) : null;
      _phone = p.phone;
      _specialization = p.specialization;
    } else {
      _firstName = '';
      _lastName = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final isTeacher = widget.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? (isTeacher ? 'تعديل أستاذ' : 'تعديل طالب')
            : (isTeacher ? 'إضافة أستاذ' : 'إضافة طالب')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: _firstName,
                  decoration: const InputDecoration(labelText: 'الاسم الأول'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل الاسم الأول' : null,
                  onSaved: (v) => _firstName = v!.trim(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _lastName,
                  decoration: const InputDecoration(labelText: 'اسم العائلة'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل اسم العائلة' : null,
                  onSaved: (v) => _lastName = v!.trim(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _fatherName,
                  decoration: const InputDecoration(labelText: 'اسم الأب'),
                  onSaved: (v) => _fatherName = _nullable(v),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _motherName,
                  decoration: const InputDecoration(labelText: 'اسم الأم'),
                  onSaved: (v) => _motherName = _nullable(v),
                ),
                const SizedBox(height: 8),

                // تاريخ الميلاد
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تاريخ الميلاد'),
                  subtitle: Text(_dateOfBirth != null
                      ? _dateOfBirth!.toIso8601String().split('T').first
                      : 'لم يتم التحديد'),
                  trailing: const Icon(Icons.date_range),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateOfBirth ?? DateTime(2010, 1, 1),
                      firstDate: DateTime(1980),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _dateOfBirth = picked);
                  },
                ),
                const SizedBox(height: 8),

                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  onSaved: (v) => _phone = _nullable(v),
                ),
                const SizedBox(height: 8),

                if (isTeacher)
                  TextFormField(
                    initialValue: _specialization,
                    decoration:
                        const InputDecoration(labelText: 'التخصص'),
                    onSaved: (v) => _specialization = _nullable(v),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
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

  String? _nullable(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<PersonProvider>();
    final person = Person(
      id: widget.initial?.id,
      role: widget.role,
      firstName: _firstName,
      lastName: _lastName,
      dateOfBirth: _dateOfBirth != null
          ? _dateOfBirth!.toIso8601String().split('T').first
          : null,
      fatherName: _fatherName,
      motherName: _motherName,
      phone: _phone,
      specialization: widget.role == 'teacher' ? _specialization : null,
    );

    try {
      if (widget.initial == null) {
        final created = await provider.create(person);
        if (created == null) throw 'فشل الإضافة';
      } else {
        final updated = await provider.update(person);
        if (updated == null) throw 'فشل الحفظ';
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }
}
