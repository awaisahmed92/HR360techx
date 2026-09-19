import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class MasterState extends ChangeNotifier {
  MasterState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  Map<String, dynamic> meta = {};
  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> fields = [];
  List<Map<String, dynamic>> columns = [];
  String title = '';
  bool readOnly = false;
  String? note;
  String? _entity;

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> load(String entity) async {
    if (_auth.isDemo) {
      _entity = entity;
      title = entity.replaceAll('_', ' ');
      meta = {};
      fields = [];
      columns = [
        {'key': 'name', 'label': 'Name'},
        {'key': 'status', 'label': 'Status', 'type': 'status'},
      ];
      rows = [
        {'id': 1, 'name': 'Demo $entity record', 'status': 1},
      ];
      readOnly = false;
      note = 'Demo mode — connect API for live CRUD.';
      notifyListeners();
      return;
    }

    _entity = entity;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final metaRes = await _api.dio.get('/masters/$entity/meta');
      final metaData = metaRes.data;
      if (metaData is! Map || metaData['success'] != true) {
        throw Exception((metaData is Map ? metaData['message'] : null) ?? 'Meta failed');
      }
      meta = Map<String, dynamic>.from(metaData);
      title = (meta['title'] ?? entity).toString();
      readOnly = meta['read_only'] == true;
      note = meta['note']?.toString();
      fields = ((meta['fields'] as List?) ?? [])
          .map((e) => asStringKeyedMap(e))
          .toList();
      columns = ((meta['columns'] as List?) ?? [])
          .map((e) => asStringKeyedMap(e))
          .toList();

      final listRes = await _api.dio.get('/masters/$entity');
      final listData = listRes.data;
      if (listData is! Map || listData['success'] != true) {
        throw Exception((listData is Map ? listData['message'] : null) ?? 'List failed');
      }
      rows = ((listData['rows'] as List?) ?? [])
          .map((e) => asStringKeyedMap(e))
          .toList();
    } on DioException catch (e) {
      error = _dioMsg(e);
      rows = [];
    } catch (e) {
      error = e.toString();
      rows = [];
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> save(Map<String, dynamic> data, {int? id}) async {
    if (_entity == null) return 'No entity';
    if (_auth.isDemo) return 'Not available in demo mode';
    try {
      final path = id == null ? '/masters/$_entity' : '/masters/$_entity/$id';
      final res = await _api.dio.post(path, data: data);
      final body = res.data;
      if (body is! Map || body['success'] != true) {
        return (body is Map ? body['message'] : null)?.toString() ?? 'Save failed';
      }
      await load(_entity!);
      return null;
    } on DioException catch (e) {
      return _dioMsg(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> remove(int id) async {
    if (_entity == null) return 'No entity';
    if (_auth.isDemo) return 'Not available in demo mode';
    try {
      final res = await _api.dio.post('/masters/$_entity/$id/delete');
      final body = res.data;
      if (body is! Map || body['success'] != true) {
        return (body is Map ? body['message'] : null)?.toString() ?? 'Delete failed';
      }
      await load(_entity!);
      return null;
    } on DioException catch (e) {
      return _dioMsg(e);
    } catch (e) {
      return e.toString();
    }
  }

  String _dioMsg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach API at ${AppConfig.apiBaseUrl}';
    }
    return e.message ?? 'Network error';
  }
}
