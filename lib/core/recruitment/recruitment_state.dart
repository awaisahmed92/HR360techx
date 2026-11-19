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
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> requisitions = [];
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> applications = [];
  List<Map<String, dynamic>> interviews = [];
  List<Map<String, dynamic>> tests = [];
  List<Map<String, dynamic>> evaluations = [];
  List<Map<String, dynamic>> evaluationResults = [];
  List<Map<String, dynamic>> referrals = [];
  List<Map<String, dynamic>> tasks = [];
  Map<String, dynamic> reports = {};
  Map<String, dynamic> portalSettings = {};
  List<Map<String, dynamic>> atsLog = [];
  int tab = 0;
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
    loadParity();
  }

  /// Pipeline sub-tabs inside Screening (0–3) without reloading parity lists.
  void setPipelineTab(int value) {
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
      await loadParity(silent: true);
    } on DioException catch (e) {
      error = _msg(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  Future<void> loadParity({bool silent = false}) async {
    if (!silent) {
      busy = true;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _api.dio.get('/recruitment/dashboard'),
        _api.dio.get('/recruitment/requisitions'),
        _api.dio.get('/recruitment/posts'),
        _api.dio.get('/recruitment/applications'),
        _api.dio.get('/recruitment/interviews'),
        _api.dio.get('/recruitment/tests'),
        _api.dio.get('/recruitment/evaluations'),
        _api.dio.get('/recruitment/referrals'),
        _api.dio.get('/recruitment/tasks'),
        _api.dio.get('/recruitment/reports'),
        _api.dio.get('/recruitment/portal-settings'),
        _api.dio.get('/recruitment/ats/log'),
      ]);
      void takeList(dynamic data, String key, void Function(List<Map<String, dynamic>>) set) {
        if (data is Map && data['success'] == true) {
          set(((data[key] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList());
        }
      }
      final dash = results[0].data;
      if (dash is Map && dash['success'] == true) {
        dashboard = asStringKeyedMap(dash['dashboard']);
      }
      takeList(results[1].data, 'requisitions', (v) => requisitions = v);
      takeList(results[2].data, 'posts', (v) => posts = v);
      takeList(results[3].data, 'applications', (v) => applications = v);
      takeList(results[4].data, 'interviews', (v) => interviews = v);
      takeList(results[5].data, 'tests', (v) => tests = v);
      final ev = results[6].data;
      if (ev is Map && ev['success'] == true) {
        evaluations = ((ev['evaluations'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        evaluationResults = ((ev['results'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
      takeList(results[7].data, 'referrals', (v) => referrals = v);
      takeList(results[8].data, 'tasks', (v) => tasks = v);
      final rp = results[9].data;
      if (rp is Map && rp['success'] == true) {
        reports = asStringKeyedMap(rp['reports']);
      }
      final ps = results[10].data;
      if (ps is Map && ps['success'] == true) {
        portalSettings = asStringKeyedMap(ps['settings']);
      }
      takeList(results[11].data, 'log', (v) => atsLog = v);
    } on DioException catch (e) {
      if (!silent) error = _msg(e);
    } catch (e) {
      if (!silent) error = e.toString();
    }
    if (!silent) {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> postJson(String path, Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post(path, data: body);
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
