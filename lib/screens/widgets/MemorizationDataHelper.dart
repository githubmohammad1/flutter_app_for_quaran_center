import '../../models/classes.dart';

class MemorizationDataHelper {
  final List<Person> students;
  final List<MemorizationSession> sessions;

  MemorizationDataHelper({
    required this.students,
    required this.sessions,
  });

  /// ترتيب الطلاب حسب عدد جلسات التسميع (الأكثر أولاً)
  List<Person> getStudentsSortedBySessions() {
    final counts = <int, int>{};
    for (final s in sessions) {
      counts[s.student] = (counts[s.student] ?? 0) + 1;
    }
    final sorted = [...students];
    sorted.sort((a, b) {
      final countA = counts[a.id] ?? 0;
      final countB = counts[b.id] ?? 0;
      return countB.compareTo(countA);
    });
    return sorted;
  }

  /// آخر جلسة لكل طالب
  Map<int, MemorizationSession> getLastSessionPerStudent() {
    final Map<int, MemorizationSession> lastSessions = {};
    for (final s in sessions) {
      if (!lastSessions.containsKey(s.student) ||
          DateTime.parse(s.date).isAfter(DateTime.parse(lastSessions[s.student]!.date))) {
        lastSessions[s.student] = s;
      }
    }
    return lastSessions;
  }

  /// جميع الجلسات لطالب معين
  List<MemorizationSession> getSessionsForStudent(int studentId) {
    final studentSessions = sessions.where((s) => s.student == studentId).toList();
    studentSessions.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
    return studentSessions;
  }
}
