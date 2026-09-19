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
        };
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
