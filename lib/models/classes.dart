// lib/models/classes.dart

class Person {
  final int? id;
  final String role;
  final String firstName;
  final String lastName;
  final String? dateOfBirth;
  final String? fatherName;
  final String? motherName;
  final String? phone;
  final String? specialization;

  Person({
    this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.fatherName,
    this.motherName,
    this.phone,
    this.specialization,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'],
        role: json['role'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        dateOfBirth: json['date_of_birth'],
        fatherName: json['father_name'],
        motherName: json['mother_name'],
        phone: json['phone'],
        specialization: json['specialization'],
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth,
        'father_name': fatherName,
        'mother_name': motherName,
        'phone': phone,
        'specialization': specialization,
      };
}
/////////////////////////////////////////////////////////////////////////////////////////////////
// اختبار جزء قرآن/
class QuranPartTest {
  final int? id;
  final int student;
  final int? teacher;
  final int partNumber;
  final String date;
  final String grade;

  QuranPartTest({
    this.id,
    required this.student,
    this.teacher,
    required this.partNumber,
    required this.date,
    required this.grade,
  });

  factory QuranPartTest.fromJson(Map<String, dynamic> json) =>
      QuranPartTest(
        id: json['id'],
        student: json['student'],
        teacher: json['teacher'],
        partNumber: json['part_number'],
        date: json['date'],
        grade: json['grade'],
      );

  Map<String, dynamic> toJson() => {
        'student': student,
        'teacher': teacher,
        'part_number': partNumber,
        'date': date,
        'grade': grade,
      };
}
/////////////////////////////////////////////////////////////////////////////////////
// جلسة تسميع
class MemorizationSession {
  final int? id;
  final int student;
  final int? teacher;
  final int pageNumber;
  final String date;
  final String grade;

  MemorizationSession({
    this.id,
    required this.student,
    this.teacher,
    required this.pageNumber,
    required this.date,
    required this.grade,
  });

  factory MemorizationSession.fromJson(Map<String, dynamic> json) =>
      MemorizationSession(
        id: json['id'],
        student: json['student'],
        teacher: json['teacher'],
        pageNumber: json['page_number'],
        date: json['date'],
        grade: json['grade'],
      );

  Map<String, dynamic> toJson() => {
        'student': student,
        'teacher': teacher,
        'page_number': pageNumber,
        'date': date,
        'grade': grade,
      };
}

// الحضور
class Attendance {
  final int? id;
  final int student;
  final String date;
  final String sessionTime;
  final String status;

  Attendance({
    this.id,
    required this.student,
    required this.date,
    required this.sessionTime,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'],
        student: json['student'],
        date: json['date'],
        sessionTime: json['session_time'],
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'student': student,
        'date': date,
        'session_time': sessionTime,
        'status': status,
      };

}
class MemorizedPage {
  final int? id;
  final int student;
  final int pageNumber;
  final String grade;
  final String date;

  MemorizedPage({
    this.id,
    required this.student,
    required this.pageNumber,
    required this.grade,
    required this.date,
  });

  factory MemorizedPage.fromJson(Map<String, dynamic> json) => MemorizedPage(
    id: json['id'],
    student: json['student'],
    pageNumber: json['page_number'],
    grade: json['grade'],
    date: json['date'],
  );

  Map<String, dynamic> toJson() => {
    'student': student,
    'page_number': pageNumber,
    'grade': grade,
    'date': date,
  };
}
