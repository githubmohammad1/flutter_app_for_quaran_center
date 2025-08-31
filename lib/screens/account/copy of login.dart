import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  bool isTeacher = false;

  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController(); // للطالب
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController(); // للمعلم

  final String _defaultTeacherPassword = "12345654321"; // كلمة مرور المعلم المبدئية

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();

    if (isTeacher) {
      // تحقق من الحقول
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _passwordController.text.isEmpty) {
        _showMessage('يرجى ملء جميع الحقول');
        return;
      }

      // تحقق من كلمة المرور
      if (_passwordController.text != _defaultTeacherPassword) {
        _showMessage('كلمة المرور غير صحيحة');
        return;
      }

      // حفظ بيانات المعلم
      await prefs.setString('teacher_first_name', _firstNameController.text);
      await prefs.setString('teacher_last_name', _lastNameController.text);
      await prefs.setString('teacher_password', _passwordController.text);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/teacherDashboard');
      }
    } else {
      // تحقق من الحقول
      if (_firstNameController.text.isEmpty ||
          _fatherNameController.text.isEmpty ||
          _lastNameController.text.isEmpty) {
        _showMessage('يرجى ملء جميع الحقول');
        return;
      }

      // حفظ بيانات الطالب
      await prefs.setString('student_first_name', _firstNameController.text);
      await prefs.setString('student_father_name', _fatherNameController.text);
      await prefs.setString('student_last_name', _lastNameController.text);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/student_dashbord');
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    isTeacher ? 'تسجيل دخول المعلم' : 'تسجيل دخول الطالب',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // الاسم الأول
                  TextField(
                    controller: _firstNameController,
                    decoration: _inputDecoration('الاسم الأول'),
                  ),
                  const SizedBox(height: 15),

                  // اسم الأب (للطلاب فقط)
                  if (!isTeacher) ...[
                    TextField(
                      controller: _fatherNameController,
                      decoration: _inputDecoration('اسم الأب'),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // الكنية
                  TextField(
                    controller: _lastNameController,
                    decoration: _inputDecoration('الكنية'),
                  ),
                  const SizedBox(height: 15),

                  // كلمة المرور (للمعلمين فقط)
                  if (isTeacher) ...[
                    TextField(
                      controller: _passwordController,
                      decoration: _inputDecoration('كلمة المرور'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                  ],

                  // زر تسجيل الدخول
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                      onPressed: _login,
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // التبديل بين الطالب والمعلم
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isTeacher = !isTeacher;
                      });
                    },
                    child: Text(
                      isTeacher
                          ? 'تسجيل الدخول كطالب'
                          : 'تسجيل الدخول كمعلم',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
