import 'package:dio/dio.dart';

// استيراد النماذج الجديدة
import '../models/announcement.dart';
import '../models/classes.dart'; // يحوي Person و QuranPartTest و MemorizationSession و Attendance

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService({required String baseUrl}) => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBase,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  static const String baseHost =
      'https://mohammadpythonanywher1.pythonanywhere.com/';
  //
  // static const String baseHost = 'http://10.182.7.191:8000';  مثال IP من نفس الشبكة
  // https://mohammadpythonanywher1.pythonanywhere.com/

  static const String apiBase = '$baseHost/api/';

  late final Dio _dio;

  // -------------------------
  // Persons
  // -------------------------
  Future<List<Person>> fetchPersons({String? role}) async {
    String endpoint = 'persons/';
    if (role != null) endpoint += '?role=$role';
    final res = await _dio.get(endpoint);
    return (res.data as List).map((e) => Person.fromJson(e)).toList();
  }

  Future<Person> fetchPerson(int id) async {
    final res = await _dio.get('persons/$id/');
    return Person.fromJson(res.data);
  }

  Future<Person> createPerson(Person person) async {
    final data = Map<String, dynamic>.from(person.toJson());
    data.remove('id');
    final res = await _dio.post('persons/', data: data);
    return Person.fromJson(res.data);
  }

  Future<Person> updatePerson(Person person) async {
    final data = Map<String, dynamic>.from(person.toJson());
    data.remove('id');
    final res = await _dio.put('persons/${person.id}/', data: data);
    return Person.fromJson(res.data);
  }

  Future<bool> deletePerson(int id) async {
    final res = await _dio.delete('persons/$id/');
    return res.statusCode == 204 || res.statusCode == 200;
  }
///////////////////////////////////////////////////////////////////////////////////////////
  // -------------------------
  // Quran Tests
  // -------------------------
  Future<List<QuranPartTest>> fetchQuranTests() async {
    final res = await _dio.get('quran-tests/');
    return (res.data as List).map((e) => QuranPartTest.fromJson(e)).toList();
  }

  Future<QuranPartTest> createQuranTest(QuranPartTest test) async {
    final data = Map<String, dynamic>.from(test.toJson());
    print(data);
    data.remove('id');
    final res = await _dio.post('quran-tests/', data: data);
    return QuranPartTest.fromJson(res.data);
  }
//////////////////////////////////////////////////////////////////////////////////////////
  // -------------------------
  // Memorization Sessions
  // -------------------------
  Future<List<MemorizationSession>> fetchMemorizationSessions() async {
    final res = await _dio.get('memorization-sessions/');
    return (res.data as List)
        .map((e) => MemorizationSession.fromJson(e))
        .toList();
  }

  Future<MemorizationSession> createMemorizationSession(
    MemorizationSession session,
  ) async {
    final data = Map<String, dynamic>.from(session.toJson());
    data.remove('id');
    final res = await _dio.post('memorization-sessions/', data: data);
    return MemorizationSession.fromJson(res.data);
  }

  // -------------------------
  // Attendance
  // -------------------------
  Future<List<Attendance>> fetchAttendance() async {
    final res = await _dio.get('attendance/');
    return (res.data as List).map((e) => Attendance.fromJson(e)).toList();
  }

  Future<Attendance> createAttendance(Attendance att) async {
    final data = Map<String, dynamic>.from(att.toJson());
    data.remove('id');
    final res = await _dio.post('attendance/', data: data);
    return Attendance.fromJson(res.data);
  }

  Future<Attendance> updateAttendance(int id, Attendance a) async {
    final res = await _dio.put(
      'attendance/$id/', // غيّر المسار إذا كان API مختلف (مثلاً بدون السلاش الأخيرة)
      data: a.toJson(),
    );
    return Attendance.fromJson(res.data);
  }

  // ✅ حذف سجل حضور (اختياري لإلغاء الحضور بالحذف)
  Future<void> deleteAttendance(int id) async {
    await _dio.delete('attendance/$id/');
  }

  Future<List<MemorizedPage>> fetchMemorizedPages() async {
    final res = await _dio.get('memorized-pages/');
    return (res.data as List).map((e) => MemorizedPage.fromJson(e)).toList();
  }

  Future<MemorizedPage> createMemorizedPage(MemorizedPage page) async {
    final data = Map<String, dynamic>.from(page.toJson());
    data.remove('id');
    final res = await _dio.post('memorized-pages/', data: data);
    return MemorizedPage.fromJson(res.data);
  }

  // جلب كل الإعلانات
  Future<List<Announcement>> fetchAnnouncements() async {
    const endpoint = 'announcements/';
    final res = await _dio.get(endpoint);
    return (res.data as List).map((e) => Announcement.fromJson(e)).toList();
  }

  // جلب إعلان واحد بالـ ID
  Future<Announcement> fetchAnnouncement(int id) async {
    final res = await _dio.get('announcements/$id/');
    return Announcement.fromJson(res.data);
  }

  // إنشاء إعلان جديد
  Future<Announcement> createAnnouncement(Announcement announcement) async {
    final data = Map<String, dynamic>.from(announcement.toJson());
    data.remove('id'); // لا نرسل الـ id عند الإنشاء
    final res = await _dio.post('announcements/', data: data);
    return Announcement.fromJson(res.data);
  }

  // تعديل إعلان موجود
  Future<Announcement> updateAnnouncement(Announcement announcement) async {
    final data = Map<String, dynamic>.from(announcement.toJson());
    data.remove('id');
    final res = await _dio.put('announcements/${announcement.id}/', data: data);
    return Announcement.fromJson(res.data);
  }

  // حذف إعلان
  Future<bool> deleteAnnouncement(int id) async {
    final res = await _dio.delete('announcements/$id/');
    return res.statusCode == 204 || res.statusCode == 200;
  }
}
