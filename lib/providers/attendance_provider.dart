import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/classes.dart';

class AttendanceProvider extends ChangeNotifier {
  final ApiService _api;
  AttendanceProvider(this._api);

  List<Attendance> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Attendance> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({bool force = true}) async {
    if (_items.isNotEmpty && !force) return;
    _setLoading(true);
    try {
      _items = await _api.fetchAttendance();
      _error = null;
    } on DioException catch (e) {
      _error = _msg(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// تسجيل أو تعديل الحضور
  Future<Attendance?> createOrUpdate(Attendance a) async {
    try {
      // نبحث عن سجل موجود
      final existing = _items.firstWhere(
        (x) =>
            x.student == a.student &&
            x.date == a.date &&
            x.sessionTime == a.sessionTime,
        orElse: () => Attendance(student: 0, date: '', sessionTime: '', status: ''),
      );

      Attendance createdOrUpdated;

      if (existing.id != null) {
        // تعديل سجل موجود
        createdOrUpdated = await _api.updateAttendance(existing.id!, a);
        // استبدال السجل في القائمة
        final idx = _items.indexWhere((x) => x.id == existing.id);
        if (idx != -1) _items[idx] = createdOrUpdated;
      } else {
        // إنشاء سجل جديد
        createdOrUpdated = await _api.createAttendance(a);
        _items.insert(0, createdOrUpdated);
      }

      notifyListeners();
      return createdOrUpdated;
    } on DioException catch (e) {
      _error = _msg(e);
      notifyListeners();
      return null;
    }
  }

  Attendance? getById(int id) {
    try {
      return _items.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _msg(DioException e) {
    final sc = e.response?.statusCode;
    final detail = e.response?.data?.toString() ?? '';
    return 'خطأ${sc != null ? ' ($sc)' : ''}: ${e.message ?? ''} $detail';
  }
}
