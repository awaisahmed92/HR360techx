import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class DevicesState extends ChangeNotifier {
  DevicesState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  Map<String, dynamic> stats = {};
  Map<String, dynamic> tables = {};
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> punches = [];
  int tab = 0; // 0 devices, 1 punches
  int? punchFilter; // null all, 0 unprocessed, 1 processed

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.dio.get('/devices/overview'),
        _api.dio.get('/devices'),
        _api.dio.get('/devices/punches', queryParameters: {
          if (punchFilter != null) 'processed': punchFilter,
          'limit': 100,
        }),
      ]);
      final ov = results[0].data;
      if (ov is Map && ov['success'] == true) {
        stats = asStringKeyedMap(ov['stats']);
        tables = asStringKeyedMap(ov['tables']);
      }
      final d = results[1].data;
      if (d is Map && d['success'] == true) {
        devices = ((d['devices'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final p = results[2].data;
      if (p is Map && p['success'] == true) {
        punches = ((p['punches'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> setPunchFilter(int? value) async {
    punchFilter = value;
    notifyListeners();
    await load();
  }

  Future<String?> saveDevice(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/devices', data: body)
          : await _api.dio.post('/devices/$id', data: body);
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

  Future<String?> deleteDevice(int id) async {
    try {
      await _api.dio.post('/devices/$id/delete');
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
