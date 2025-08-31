import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/classes.dart';


class MemorizationSessionProvider extends ChangeNotifier {
  final ApiService _api;
  MemorizationSessionProvider(this._api);

  List<MemorizationSession> _items = [];
  bool _isLoading = false;
  String? _error;

  List<MemorizationSession> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({bool force = true}) async {
    if (_items.isNotEmpty && !force) return;
    _setLoading(true);
    try {
      _items = await _api.fetchMemorizationSessions();
      _error = null;
    } on DioException catch (e) {
      _error = _msg(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<MemorizationSession?> create(MemorizationSession m) async {
    try {
      final created = await _api.createMemorizationSession(m);
      _items.insert(0, created);
      notifyListeners();
      return created;
    } on DioException catch (e) {
      _error = _msg(e);
      notifyListeners();
      return null;
    }
  }

  MemorizationSession? getById(int id) {
    try {
      return _items.firstWhere((m) => m.id == id);
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
