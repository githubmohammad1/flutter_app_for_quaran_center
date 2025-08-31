import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_first_name');
    await prefs.remove('student_father_name');
    await prefs.remove('student_last_name');
    await prefs.remove('teacher_first_name');
    await prefs.remove('teacher_last_name');
    await prefs.remove('teacher_password');

    // الانتقال لشاشة تسجيل الدخول
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text(
                'الإعدادات العامة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),

            // الثيم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'الثيم',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('اتّباع النظام'),
              value: AppThemeMode.system,
              // ignore: deprecated_member_use
              groupValue: settings.themeMode,
              // ignore: deprecated_member_use
              onChanged: (v) => settings.setThemeMode(v!),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('فاتح'),
              value: AppThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (v) => settings.setThemeMode(v!),
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('داكن'),
              value: AppThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (v) => settings.setThemeMode(v!),
            ),

            const Divider(),

            // اللغة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'اللغة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioListTile<AppLocale>(
              title: const Text('افتراضي النظام'),
              value: AppLocale.system,
              groupValue: settings.locale,
              onChanged: (v) => settings.setLocale(v!),
            ),
            RadioListTile<AppLocale>(
              title: const Text('العربية'),
              value: AppLocale.ar,
              groupValue: settings.locale,
              onChanged: (v) => settings.setLocale(v!),
            ),
            RadioListTile<AppLocale>(
              title: const Text('English'),
              value: AppLocale.en,
              groupValue: settings.locale,
              onChanged: (v) => settings.setLocale(v!),
            ),

            const Divider(),

            // تحسينات تجربة المستخدم
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('اتجاه الكتابة (RTL/LTR)'),
              subtitle: const Text('يُحدّد تلقائيًا حسب اللغة المختارة'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الاتجاه يضبط تلقائيًا حسب اللغة'),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('عن التطبيق'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'مسجد عثمان ',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025',
              ),
            ),

            const Divider(),

            // ✅ زر تسجيل الخروج
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}
