import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class PerformanceState extends ChangeNotifier {
  PerformanceState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> indicators = [];
  List<Map<String, dynamic>> reviews = [];
  List<Map<String, dynamic>> appraisals = [];
  List<Map<String, dynamic>> goals = [];
  List<Map<String, dynamic>> goalTypes = [];
  List<Map<String, dynamic>> cycles = [];
  Map<String, dynamic> options = {};
  int tab = 0; // 0 reviews, 1 indicators, 2 appraisals, 3 goals, 4 goal types, 5 cycles

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.dio.get('/performance/meta'),
        _api.dio.get('/performance/indicators'),
        _api.dio.get('/performance/reviews'),
        _api.dio.get('/performance/appraisals'),
        _api.dio.get('/performance/goals'),
        _api.dio.get('/performance/goal-types'),
        _api.dio.get('/performance/cycles'),
      ]);
      final meta = results[0].data;
      if (meta is Map && meta['success'] == true) {
        options = asStringKeyedMap(meta['options']);
      }
      final ind = results[1].data;
      if (ind is Map && ind['success'] == true) {
        indicators = ((ind['indicators'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final rev = results[2].data;
      if (rev is Map && rev['success'] == true) {
        reviews = ((rev['reviews'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final app = results[3].data;
      if (app is Map && app['success'] == true) {
        appraisals = ((app['appraisals'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final g = results[4].data;
      if (g is Map && g['success'] == true) {
        goals = ((g['goals'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final gt = results[5].data;
      if (gt is Map && gt['success'] == true) {
        goalTypes = ((gt['types'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final cy = results[6].data;
      if (cy is Map && cy['success'] == true) {
        cycles = ((cy['cycles'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> saveReview(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/performance/reviews', data: body)
          : await _api.dio.post('/performance/reviews/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveIndicator(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/performance/indicators', data: body)
          : await _api.dio.post('/performance/indicators/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveAppraisal(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/performance/appraisals', data: body)
          : await _api.dio.post('/performance/appraisals/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> advanceAppraisal(int id) async {
    try {
      final res = await _api.dio.post('/performance/appraisals/$id/advance');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Advance failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveGoal(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/performance/goals', data: body)
          : await _api.dio.post('/performance/goals/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteGoal(int id) async {
    try {
      await _api.dio.post('/performance/goals/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveGoalType(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/performance/goal-types', data: body)
          : await _api.dio.post('/performance/goal-types/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteGoalType(int id) async {
    try {
      await _api.dio.post('/performance/goal-types/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveCycle(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/performance/cycles', data: body)
          : await _api.dio.post('/performance/cycles/$id', data: body);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteCycle(int id) async {
    try {
      await _api.dio.post('/performance/cycles/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  String _msg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    return e.message ?? 'Network error';
  }
}
