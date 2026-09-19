import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class TrainingState extends ChangeNotifier {
  TrainingState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  int tab = 0; // 0 list, 1 calendar, 2 trainers, 3 types
  Map<String, dynamic> options = {};
  List<Map<String, dynamic>> trainings = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> trainers = [];
  List<Map<String, dynamic>> types = [];
  DateTime calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
    load();
  }

  void touch() => notifyListeners();

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final meta = await _api.dio.get('/training/meta');
      final md = meta.data;
      if (md is Map && md['success'] == true) {
        options = asStringKeyedMap(md['options']);
      }

      if (tab == 0) {
        final res = await _api.dio.get('/training');
        final d = res.data;
        if (d is Map && d['success'] == true) {
          trainings = ((d['trainings'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        }
      } else if (tab == 1) {
        final start = DateTime(calendarMonth.year, calendarMonth.month, 1);
        final end = DateTime(calendarMonth.year, calendarMonth.month + 1, 0);
        final res = await _api.dio.get('/training/calendar', queryParameters: {
          'from': _ymd(start),
          'to': _ymd(end),
        });
        final d = res.data;
        if (d is Map && d['success'] == true) {
          events = ((d['events'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        }
      } else if (tab == 2) {
        final res = await _api.dio.get('/training/trainers');
        final d = res.data;
        if (d is Map && d['success'] == true) {
          trainers = ((d['trainers'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        }
      } else {
        final res = await _api.dio.get('/training/types');
        final d = res.data;
        if (d is Map && d['success'] == true) {
          types = ((d['types'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        }
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> loadTrainingDetail(int id) async {
    try {
      final res = await _api.dio.get('/training/$id');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        return asStringKeyedMap(d['training']);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> saveTraining(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/training', data: body)
          : await _api.dio.post('/training/$id', data: body);
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

  Future<String?> deleteTraining(int id) async {
    try {
      await _api.dio.post('/training/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveTrainer(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/training/trainers', data: body)
          : await _api.dio.post('/training/trainers/$id', data: body);
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

  Future<String?> deleteTrainer(int id) async {
    try {
      await _api.dio.post('/training/trainers/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveType(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/training/types', data: body)
          : await _api.dio.post('/training/types/$id', data: body);
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

  Future<String?> deleteType(int id) async {
    try {
      await _api.dio.post('/training/types/$id/delete');
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
