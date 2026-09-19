import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../network/api_client.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SelfServiceRepository {
  SelfServiceRepository({required this.getSession});
  final AuthSession? Function() getSession;

  ApiClient _c() => ApiClient(tokenProvider: () async => getSession()?.token);

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final d = await _get('/travel/projects');
    return (d['projects'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final d = await _get('/travel/employees');
    return (d['employees'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> fetchTravelMeta() async {
    return _get('/travel/meta');
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await _c().dio.get(path);
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw ApiException((data is Map ? data['message'] : null)?.toString() ?? 'Request failed');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw ApiException(_dio(e));
    }
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await _c().dio.post(path, data: body ?? {});
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw ApiException((data is Map ? data['message'] : null)?.toString() ?? 'Request failed');
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw ApiException(_dio(e));
    }
  }

  String _dio(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    return e.message ?? 'Network error';
  }

  Future<Map<String, dynamic>> profile() => _get('/profile');
  Future<void> updateProfile({
    required String email,
    required String phone,
    Map<String, dynamic>? extra,
  }) =>
      _post('/profile', {
        'email': email,
        'phone': phone,
        ...?extra,
      }).then((_) {});

  Future<Map<String, dynamic>> attendanceToday() => _get('/attendance/today');
  Future<Map<String, dynamic>> attendanceMonth(String month) =>
      _get('/attendance?month=$month');
  Future<void> punch(String action) =>
      _post('/attendance/punch', {'action': action}).then((_) {});

  Future<List<Map<String, dynamic>>> travels() async {
    final d = await _get('/travel');
    return (d['travels'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> applyTravel(Map<String, dynamic> body) =>
      _post('/travel/apply', body).then((_) {});
  Future<void> travelAct(String action, int id) =>
      _post('/travel/$action', {'id': id}).then((_) {});

  Future<List<Map<String, dynamic>>> timesheets() async {
    final d = await _get('/timesheet');
    return (d['timesheets'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> applyTimesheet(Map<String, dynamic> body) =>
      _post('/timesheet/apply', body).then((_) {});
  Future<void> timesheetAct(String action, int id) =>
      _post('/timesheet/$action', {'id': id}).then((_) {});

  Future<List<Map<String, dynamic>>> approvalsInbox() async {
    final d = await _get('/approvals/inbox');
    return (d['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> approvalSettings(String module) =>
      _get('/settings/approvals?module=$module');

  Future<Map<String, dynamic>> saveApprovalSettings(
          String module, Map<String, dynamic> body) =>
      _post('/settings/approvals', {...body, 'module': module});

  Future<Map<String, dynamic>> notificationSettings(String module) =>
      _get('/settings/notifications?module=$module');

  Future<Map<String, dynamic>> saveNotificationSettings(
          String module, Map<String, dynamic> body) =>
      _post('/settings/notifications', {...body, 'module': module});

  Future<Map<String, dynamic>> notifications() => _get('/notifications');

  Future<void> markNotificationsRead({int? id}) =>
      _post('/notifications/read', id == null ? {} : {'id': id}).then((_) {});
}
