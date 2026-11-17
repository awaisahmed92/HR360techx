import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

/// HR Letters module state: dashboard, designer, categories, issue, instances, reports.
class LetterState extends ChangeNotifier {
  LetterState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  int tab = 0;

  Map<String, dynamic> stats = {};
  Map<String, dynamic> options = {};
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> types = [];
  List<Map<String, dynamic>> instances = [];
  List<Map<String, dynamic>> reportRows = [];

  /// Legacy compatibility for any old callers.
  List<Map<String, dynamic>> get letters => types;
  Map<String, dynamic>? preview;

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
    loadTab();
  }

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final meta = await _api.dio.get('/hr-letters/meta');
      final m = meta.data;
      if (m is Map && m['success'] == true) {
        options = asStringKeyedMap(m['options']);
      }
      await loadTab(silent: true);
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> loadTab({bool silent = false}) async {
    if (!silent) {
      busy = true;
      error = null;
      notifyListeners();
    }
    try {
      switch (tab) {
        case 0:
          await _loadDashboard();
          break;
        case 1:
          await _loadTypes();
          break;
        case 2:
          await _loadCategories();
          break;
        case 3:
          await _loadTypes(activeOnly: true);
          break;
        case 4:
          await _loadInstances(kind: 'employee');
          break;
        case 5:
          await _loadInstances(kind: 'candidate');
          break;
        case 6:
          await _loadReport('employee-letters');
          break;
        default:
          await _loadDashboard();
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    if (!silent) {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _loadDashboard() async {
    final res = await _api.dio.get('/hr-letters/dashboard');
    final d = res.data;
    if (d is Map && d['success'] == true) {
      stats = asStringKeyedMap(d['stats']);
    }
  }

  Future<void> _loadCategories() async {
    final res = await _api.dio.get('/hr-letters/categories');
    final d = res.data;
    if (d is Map && d['success'] == true) {
      categories = ((d['categories'] as List?) ?? []).map(asStringKeyedMap).toList();
    }
  }

  Future<void> _loadTypes({bool activeOnly = false}) async {
    final res = await _api.dio.get('/hr-letters/types', queryParameters: {
      if (activeOnly) 'active_only': 1,
    });
    final d = res.data;
    if (d is Map && d['success'] == true) {
      types = ((d['types'] as List?) ?? []).map(asStringKeyedMap).toList();
    }
  }

  Future<void> _loadInstances({required String kind}) async {
    final res = await _api.dio.get('/hr-letters/instances', queryParameters: {'kind': kind});
    final d = res.data;
    if (d is Map && d['success'] == true) {
      instances = ((d['instances'] as List?) ?? []).map(asStringKeyedMap).toList();
    }
  }

  Future<void> _loadReport(String which) async {
    final res = await _api.dio.get('/hr-letters/reports/$which');
    final d = res.data;
    if (d is Map && d['success'] == true) {
      if (d['instances'] is List) {
        reportRows = (d['instances'] as List).map(asStringKeyedMap).toList();
      } else {
        reportRows = ((d['rows'] as List?) ?? []).map(asStringKeyedMap).toList();
      }
    }
  }

  Future<String?> saveCategory(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/hr-letters/categories', data: body)
          : await _api.dio.post('/hr-letters/categories/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await _loadCategories();
        notifyListeners();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteCategory(int id) async {
    try {
      await _api.dio.post('/hr-letters/categories/$id/delete');
      await _loadCategories();
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveType(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/hr-letters/types', data: body)
          : await _api.dio.post('/hr-letters/types/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await _loadTypes();
        notifyListeners();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteType(int id) async {
    try {
      await _api.dio.post('/hr-letters/types/$id/delete');
      await _loadTypes();
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> issueLetter(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/hr-letters/issue', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Issue failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<Map<String, dynamic>?> loadInstance(int id) async {
    try {
      final res = await _api.dio.get('/hr-letters/instances/$id');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        return asStringKeyedMap(d['instance']);
      }
    } on DioException {
      // ignore
    }
    return null;
  }

  Future<String?> updateInstance(int id, Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/hr-letters/instances/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await loadTab(silent: true);
        notifyListeners();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Update failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> acknowledge(int id, {String note = ''}) async {
    try {
      final res = await _api.dio.post('/hr-letters/instances/$id/acknowledge', data: {
        'ack_note': note,
      });
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await loadTab(silent: true);
        notifyListeners();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Acknowledge failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> approve(int id) async {
    try {
      final res = await _api.dio.post('/hr-letters/instances/$id/approve');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await loadTab(silent: true);
        notifyListeners();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Approve failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> reject(int id) async {
    try {
      final res = await _api.dio.post('/hr-letters/instances/$id/reject');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await loadTab(silent: true);
        notifyListeners();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Reject failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<void> loadCustomVariablesReport() async {
    busy = true;
    notifyListeners();
    try {
      await _loadReport('custom-variables');
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  // Legacy methods kept so old LettersView code paths don't hard-crash if referenced.
  Future<String?> save(Map<String, dynamic> body, {int? id}) async {
    return saveType({
      'name': body['name'],
      'contents': body['content'] ?? body['contents'],
      'options': {
        'page_size': body['page_size'] ?? 'A4',
        'margin_top': body['margin_top'] ?? 20,
        'margin_right': body['margin_right'] ?? 20,
        'margin_bottom': body['margin_bottom'] ?? 20,
        'margin_left': body['margin_left'] ?? 20,
        'skip_approval': false,
      },
      'status': body['status'] ?? 1,
      'letter_kind': 0,
      'custom_variables': <Map<String, dynamic>>[],
    }, id: id);
  }

  Future<String?> delete(int id) => deleteType(id);

  Future<String?> loadPreview(int letterId, int? employeeId) async {
    preview = null;
    notifyListeners();
    return 'Use Send Letter to issue a snapshot, then open Print.';
  }

  String _msg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    return e.message ?? 'Network error';
  }
}
