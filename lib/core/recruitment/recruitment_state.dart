import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class RecruitmentState extends ChangeNotifier {
  RecruitmentState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> candidates = [];
  Map<String, dynamic> options = {};
  int tab = 0; // 0 pipeline, 1 jobs, 2 long list, 3 short list
  String filterQ = '';
  int? filterJobId;
  int? filterGender;
  String filterExp = '';
  String filterQualification = '';
  String filterDistrict = '';

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  void setFilters({
    String? q,
    int? jobId,
    bool clearJob = false,
    int? gender,
    bool clearGender = false,
    String? exp,
    String? qualification,
    String? district,
  }) {
    if (q != null) filterQ = q;
    if (clearJob) {
      filterJobId = null;
    } else if (jobId != null) {
      filterJobId = jobId;
    }
    if (clearGender) {
      filterGender = null;
    } else if (gender != null) {
      filterGender = gender;
    }
    if (exp != null) filterExp = exp;
    if (qualification != null) filterQualification = qualification;
    if (district != null) filterDistrict = district;
    load();
  }

  List<Map<String, dynamic>> get longList =>
      candidates.where((c) => ((c['status'] as num?)?.toInt() ?? 0) >= 0).toList();

  /// Short list = Interview / Offer / Hired (status >= 2).
  List<Map<String, dynamic>> get shortList =>
      candidates.where((c) {
        final s = (c['status'] as num?)?.toInt() ?? 0;
        return s >= 2;
      }).toList();

  List<Map<String, dynamic>> get rejectedList =>
      candidates.where((c) => ((c['status'] as num?)?.toInt() ?? 0) == -1).toList();

  Future<String?> deleteCandidate(int id) async {
    try {
      await _api.dio.post('/recruitment/candidates/$id/delete');
      await load();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final query = <String, dynamic>{
        if (filterQ.trim().isNotEmpty) 'q': filterQ.trim(),
        if (filterJobId != null) 'job_id': filterJobId,
        if (filterGender != null) 'gender': filterGender,
        if (filterExp.trim().isNotEmpty) 'min_exp': filterExp.trim(),
        if (filterQualification.trim().isNotEmpty) 'qualification': filterQualification.trim(),
        if (filterDistrict.trim().isNotEmpty) 'district': filterDistrict.trim(),
      };
      final results = await Future.wait([
        _api.dio.get('/recruitment/meta'),
        _api.dio.get('/recruitment/jobs'),
        _api.dio.get('/recruitment/candidates', queryParameters: query),
      ]);
      final meta = results[0].data;
      if (meta is Map && meta['success'] == true) {
        options = asStringKeyedMap(meta['options']);
      }
      final j = results[1].data;
      if (j is Map && j['success'] == true) {
        jobs = ((j['jobs'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      final c = results[2].data;
      if (c is Map && c['success'] == true) {
        candidates = ((c['candidates'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> byStage(String stage) =>
      candidates.where((c) => '${c['stage']}' == stage).toList();

  Future<String?> saveCandidate(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/recruitment/candidates', data: body)
          : await _api.dio.post('/recruitment/candidates/$id', data: body);
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

  Future<String?> moveStatus(int id, int status, {String? remarks, String? refRemarks}) async {
    try {
      final res = await _api.dio.post('/recruitment/candidates/$id/status', data: {
        'status': status,
        if (remarks != null) 'remarks': remarks,
        if (refRemarks != null) 'ref_remarks': refRemarks,
      });
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

  Future<Map<String, dynamic>?> loadCandidateProfile(int id) async {
    try {
      final res = await _api.dio.get('/recruitment/candidates/$id');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        return asStringKeyedMap(d);
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<String?> saveCandidateProfile(int id, Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/recruitment/candidates/$id/profile', data: body);
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

  Future<String?> hireCandidate(int id, {Map<String, dynamic>? body}) async {
    try {
      final res = await _api.dio.post('/recruitment/candidates/$id/hire', data: body ?? {});
      final d = res.data;
      if (d is Map && d['success'] == true) {
        await load();
        final user = d['user_name'];
        final pass = d['temp_password'];
        if (user != null && pass != null) {
          return 'HIRED_OK|$user|$pass|${d['employee_id']}';
        }
        return null;
      }
      return (d is Map ? d['message'] : null)?.toString() ?? 'Hire failed';
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveJob(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _api.dio.post('/recruitment/jobs', data: body)
          : await _api.dio.post('/recruitment/jobs/$id', data: body);
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

  Future<String?> deleteJob(int id) async {
    try {
      await _api.dio.post('/recruitment/jobs/$id/delete');
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
