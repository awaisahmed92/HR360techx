import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class EmployeeState extends ChangeNotifier {
  EmployeeState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> rows = [];
  Map<String, int> stats = {
    'total': 0,
    'active': 0,
    'inactive': 0,
    'male': 0,
    'female': 0,
    'job_titles': 0,
    'types': 0,
    'categories': 0,
  };
  Map<String, List<Map<String, dynamic>>> charts = {
    'gender': [],
    'companies': [],
    'departments': [],
    'age_groups': [],
    'categories': [],
    'divisions': [],
  };
  Map<String, dynamic> options = {};
  List<Map<String, dynamic>> roleCatalog = [];

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> load({String q = ''}) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.dio.get('/employees', queryParameters: {if (q.isNotEmpty) 'q': q}),
        _api.dio.get('/employees/stats'),
        _api.dio.get('/employees/meta'),
      ]);

      final listData = results[0].data;
      if (listData is! Map || listData['success'] != true) {
        throw Exception((listData is Map ? listData['message'] : null) ?? 'List failed');
      }
      rows = ((listData['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();

      final statsData = results[1].data;
      if (statsData is Map && statsData['success'] == true) {
        final s = asStringKeyedMap(statsData['stats']);
        stats = {
          'total': (s['total'] as num?)?.toInt() ?? 0,
          'active': (s['active'] as num?)?.toInt() ?? 0,
          'inactive': (s['inactive'] as num?)?.toInt() ?? 0,
          'male': (s['male'] as num?)?.toInt() ?? 0,
          'female': (s['female'] as num?)?.toInt() ?? 0,
          'job_titles': (s['job_titles'] as num?)?.toInt() ??
              (s['jobTitles'] as num?)?.toInt() ??
              0,
          'types': (s['types'] as num?)?.toInt() ?? 0,
          'categories': (s['categories'] as num?)?.toInt() ?? 0,
        };
        final rawCharts = statsData['charts'];
        if (rawCharts is Map) {
          charts = {
            for (final key in [
              'gender',
              'companies',
              'departments',
              'age_groups',
              'categories',
              'divisions',
            ])
              key: ((rawCharts[key] as List?) ?? [])
                  .whereType<Map>()
                  .map((e) => asStringKeyedMap(e))
                  .toList(),
          };
        }
      }

      final metaData = results[2].data;
      if (metaData is Map && metaData['success'] == true) {
        options = asStringKeyedMap(metaData['options']);
        roleCatalog = ((metaData['role_catalog'] as List?) ?? [])
            .map((e) => asStringKeyedMap(e))
            .toList();
      }
    } on DioException catch (e) {
      error = _dioMsg(e);
      rows = [];
    } catch (e) {
      error = e.toString();
      rows = [];
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> create(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/employees', data: body);
      final data = res.data;
      if (data is Map && data['success'] == true) {
        await load();
        return null;
      }
      return (data is Map ? data['message'] : null)?.toString() ?? 'Create failed';
    } on DioException catch (e) {
      return _dioMsg(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> fetchNextEmployeeCode() async {
    try {
      final res = await _api.dio.get('/employees/next-code');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return (data['user_name'] ?? data['employee_code'])?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Returns created employee_id on success, or throws via error string pattern.
  Future<({int? id, String? code, String? error})> createReturningId(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/employees', data: body);
      final data = res.data;
      if (data is Map && data['success'] == true) {
        final id = (data['employee_id'] as num?)?.toInt();
        final code = (data['user_name'] ?? data['employee_code'])?.toString();
        await load();
        return (id: id, code: code, error: null);
      }
      return (
        id: null,
        code: null,
        error: (data is Map ? data['message'] : null)?.toString() ?? 'Create failed',
      );
    } on DioException catch (e) {
      return (id: null, code: null, error: _dioMsg(e));
    } catch (e) {
      return (id: null, code: null, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    try {
      final res = await _api.dio.get('/employees/$id');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return asStringKeyedMap(data);
      }
      error = (data is Map ? data['message'] : null)?.toString() ?? 'Load failed';
      notifyListeners();
      return null;
    } on DioException catch (e) {
      error = _dioMsg(e);
      notifyListeners();
      return null;
    }
  }

  Future<String?> update(int id, Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/employees/$id', data: body);
      final data = res.data;
      if (data is Map && data['success'] == true) {
        await load();
        return null;
      }
      return (data is Map ? data['message'] : null)?.toString() ?? 'Update failed';
    } on DioException catch (e) {
      return _dioMsg(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<Map<String, dynamic>>> loadLeaveAssignments(int employeeId) async {
    try {
      final res = await _api.dio.get('/employees/$employeeId/leave-assignments');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return ((data['assignments'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => asStringKeyedMap(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<String?> saveLeaveAssignments(int employeeId, List<Map<String, dynamic>> assignments) async {
    try {
      final res = await _api.dio.post('/employees/$employeeId/leave-assignments', data: {
        'assignments': assignments,
      });
      final data = res.data;
      if (data is Map && data['success'] == true) return null;
      return (data is Map ? data['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _dioMsg(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> loadRoles(int employeeId) async {
    try {
      final res = await _api.dio.get('/employees/$employeeId/roles');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return asStringKeyedMap(data);
      }
      error = (data is Map ? data['message'] : null)?.toString() ?? 'Roles load failed';
      notifyListeners();
      return null;
    } on DioException catch (e) {
      error = _dioMsg(e);
      notifyListeners();
      return null;
    }
  }

  Future<String?> saveRoles(int employeeId, Map<String, dynamic> permissions) async {
    try {
      final res = await _api.dio.post('/employees/$employeeId/roles', data: {
        'permissions': permissions,
      });
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return null;
      }
      return (data is Map ? data['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _dioMsg(e);
    } catch (e) {
      return e.toString();
    }
  }

  List<Map<String, dynamic>> optionList(String key) {
    final raw = options[key];
    if (raw is! List) return [];
    return raw.map((e) => asStringKeyedMap(e)).toList();
  }

  String _dioMsg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach API. Start XAMPP Apache + MySQL.';
    }
    return e.message ?? 'Network error';
  }
}
