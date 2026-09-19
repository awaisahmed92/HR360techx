import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class AttendanceAdminState extends ChangeNotifier {
  AttendanceAdminState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  String date = DateTime.now().toIso8601String().substring(0, 10);
  bool isOffDay = false;
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> schedule = [];
  Map<String, dynamic> registerSummary = {};
  List<Map<String, dynamic>> registerRows = [];

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> loadGrid({String? d}) async {
    if (d != null) date = d;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/attendance/admin', queryParameters: {'date': date});
      final data = res.data;
      if (data is Map && data['success'] == true) {
        rows = ((data['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        isOffDay = data['is_off_day'] == true;
      } else {
        error = (data is Map ? data['message'] : null)?.toString() ?? 'Load failed';
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> mark(int employeeId, int status) async {
    try {
      final res = await _api.dio.post('/attendance/admin/mark', data: {
        'employee_id': employeeId,
        'date': date,
        'status': status,
      });
      final data = res.data;
      if (data is Map && data['success'] == true) {
        await loadGrid();
        return null;
      }
      return (data is Map ? data['message'] : null)?.toString() ?? 'Mark failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<void> loadSchedule() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/schedule');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        schedule = ((data['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      } else {
        error = (data is Map ? data['message'] : null)?.toString() ?? 'Load failed';
      }
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> saveSchedule(List<Map<String, dynamic>> rows) async {
    try {
      final res = await _api.dio.post('/schedule', data: {'rows': rows});
      final data = res.data;
      if (data is Map && data['success'] == true) {
        schedule = ((data['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        notifyListeners();
        return null;
      }
      return (data is Map ? data['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<void> loadRegister({String? d, String status = 'all'}) async {
    if (d != null) date = d;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/reports/attendance/register', queryParameters: {
        'date': date,
        'status': status,
      });
      final data = res.data;
      if (data is Map && data['success'] == true) {
        registerRows = ((data['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        registerSummary = asStringKeyedMap(data['summary']);
        isOffDay = data['is_off_day'] == true;
      } else {
        error = (data is Map ? data['message'] : null)?.toString() ?? 'Load failed';
      }
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  String _msg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    return e.message ?? 'Network error';
  }
}
