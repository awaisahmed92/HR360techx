import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class TerminationState extends ChangeNotifier {
  TerminationState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic> options = {};

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.dio.get('/termination/meta'),
        _api.dio.get('/termination'),
      ]);
      final meta = results[0].data;
      if (meta is Map && meta['success'] == true) {
        options = asStringKeyedMap(meta['options']);
      }
      final d = results[1].data;
      if (d is Map && d['success'] == true) {
        rows = ((d['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> save(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/termination', data: body)
          : await _api.dio.post('/termination/$id', data: body);
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

  Future<String?> delete(int id) async {
    try {
      await _api.dio.post('/termination/$id/delete');
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

class LoanApplicationState extends ChangeNotifier {
  LoanApplicationState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic> options = {};

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.dio.get('/loan-applications/meta'),
        _api.dio.get('/loan-applications'),
      ]);
      final meta = results[0].data;
      if (meta is Map && meta['success'] == true) {
        options = asStringKeyedMap(meta['options']);
      }
      final d = results[1].data;
      if (d is Map && d['success'] == true) {
        rows = ((d['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> save(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/loan-applications', data: body)
          : await _api.dio.post('/loan-applications/$id', data: body);
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

  Future<String?> setStatus(int id, String status) async {
    try {
      final res = await _api.dio.post('/loan-applications/$id/status', data: {'status': status});
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Update failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> delete(int id) async {
    try {
      await _api.dio.post('/loan-applications/$id/delete');
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
