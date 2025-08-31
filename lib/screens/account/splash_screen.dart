import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final teacherPassword = prefs.getString('teacher_password');

    await Future.delayed(const Duration(seconds: 2)); // وقت عرض الشعار

    if (teacherPassword != null && teacherPassword.isNotEmpty) {
      // ✅ كلمة مرور المعلم موجودة → ننتقل لواجهة المعلم
      Navigator.pushReplacementNamed(context, '/teacherDashboard');
    } else {
      // ❌ لا يوجد كلمة مرور → ننتقل لواجهة تسجيل الطالب
      Navigator.pushReplacementNamed(context, '/student_dashbord');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.menu_book, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Quran Progress App',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
