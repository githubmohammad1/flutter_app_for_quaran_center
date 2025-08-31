import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../api/api.dart';
import '../models/announcement.dart';

class AnnouncementProvider extends ChangeNotifier {
  final ApiService _api;
  AnnouncementProvider(this._api);

  List<Announcement> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Announcement> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({bool force = true}) async {
    if (_items.isNotEmpty && !force) return;
    _setLoading(true);
    try {
      _items = await _api.fetchAnnouncements();
      _error = null;
    } on DioException catch (e) {
      _error = _msg(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Announcement? getById(int id) {
    try {
      return _items.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Announcement?> create(Announcement a) async {
    try {
      final created = await _api.createAnnouncement(a);
      _items.insert(0, created);
      notifyListeners();
      return created;
    } on DioException catch (e) {
      _error = _msg(e);
      notifyListeners();
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
