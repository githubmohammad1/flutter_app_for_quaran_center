import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quran_center_app/screens/account/splash_screen.dart';
import 'package:quran_center_app/screens/student/MemorizationScreen.dart';
import 'package:quran_center_app/screens/student/attendanceTableScreen.dart';
import 'package:quran_center_app/screens/student/students_dash_board.dart' show StudentDashboard;
import 'package:quran_center_app/screens/student/tests_list_for_student.dart';
import 'api/api.dart';
import 'providers/announcement_provider.dart';
import 'providers/person_provider.dart';
import 'providers/quran_test_provider.dart';
import 'providers/memorization_session_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/account/login_screen.dart';
import 'screens/teacher/progress_take_screen.dart';
import 'screens/widgets/settings_controller.dart';
import 'screens/teacher/students_list_screen_for_teacher.dart';
import 'screens/teacher/teacher_dashboard.dart';
import 'screens/teacher/tests_list_screen_for teacher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsController = SettingsController();
  await settingsController.init();

  final api = ApiService(baseUrl: 'https://mohammadpythonanywher1.pythonanywhere.com/api/');

  runApp(
    MultiProvider(
      providers: [

        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<SettingsController>.value(value: settingsController),

        

        ChangeNotifierProvider<PersonProvider>(
          create: (ctx) => PersonProvider(ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider<QuranTestProvider>(
          create: (ctx) => QuranTestProvider(ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider<MemorizationSessionProvider>(
          create: (ctx) => MemorizationSessionProvider(ctx.read<ApiService>()),
        ),
        ChangeNotifierProvider<AttendanceProvider>(
          create: (ctx) => AttendanceProvider(ctx.read<ApiService>()),
        ),

     ChangeNotifierProvider<AnnouncementProvider>(create:(ctx) =>AnnouncementProvider(ctx.read<ApiService>()))
     
     
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مسجدي',
      themeMode: settings.materialThemeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      locale: settings.materialLocale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      home: const SplashScreen(),


      routes: {
        
        '/spalsh)screen': (_) => const SplashScreen(),
        '/login': (_) => const UnifiedLoginScreen(),
        
        '/recitationHistory': (_) => const MemorizationScreen(),
        '/testsView': (_) => const TestsScreen(),
        '/attendanceHistory': (_) => const AttendanceTableScreen(),
        '/student_dashbord': (_) => const StudentDashboard(),
      
        '/addStudent': (_) => const StudentListScreen(),
        '/recordRecitation': (_) => AttendanceMemorizationScreen(),
        '/viewStudent': (_) => const StudentListScreen(),
        '/ViewStudent': (_) => const StudentListScreen(), // alias لحالة الحروف الكبيرة
        '/teacherDashboard': (_) => const TeacherDashboard(),
        
        '/tests': (_) => const TestsListScreen(),
      },
    );
  }
}
