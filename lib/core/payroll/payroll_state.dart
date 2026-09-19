import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class PayrollState extends ChangeNotifier {
  PayrollState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;

  Map<String, dynamic> stats = {};
  Map<String, dynamic> meta = {};
  List<Map<String, dynamic>> defines = [];
  List<Map<String, dynamic>> runs = [];
  Map<String, dynamic>? payslip;

  ApiClient get _api =>
      ApiClient(tokenProvider: () async => _auth.session?.token);

  Future<void> loadDashboard() async {
    if (_auth.isDemo) {
      stats = {
        'defined_structures': 0,
        'processed_this_month': 0,
        'month_gross': 0,
        'month_net': 0,
        'month_tax': 0,
        'currency': 'PKR',
      };
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/payroll/dashboard');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        stats = asStringKeyedMap(d['stats']);
        error = null;
      } else {
        error = (d is Map ? d['message'] : null)?.toString() ?? 'Failed';
      }
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  Future<void> loadMeta() async {
    if (_auth.isDemo) return;
    try {
      final res = await _api.dio.get('/payroll/meta');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        meta = asStringKeyedMap(d['meta']);
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadDefines() async {
    if (_auth.isDemo) {
      defines = [];
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/payroll/define');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        defines = ((d['salaries'] as List?) ?? [])
            .map((e) => asStringKeyedMap(e))
            .toList();
        error = null;
      }
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  Future<void> loadRuns({String? date, int? projectId}) async {
    if (_auth.isDemo) {
      runs = [];
      notifyListeners();
      return;
    }
    busy = true;
    notifyListeners();
    try {
      final res = await _api.dio.get('/payroll/process', queryParameters: {
        if (date != null) 'date': date,
        if (projectId != null) 'project_id': projectId,
      });
      final d = res.data;
      if (d is Map && d['success'] == true) {
        runs = ((d['runs'] as List?) ?? [])
            .map((e) => asStringKeyedMap(e))
            .toList();
      }
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> saveDefine(Map<String, dynamic> body, {int? id}) async {
    if (_auth.isDemo) return 'Not available in demo mode';
    try {
      final path = id == null ? '/payroll/define' : '/payroll/define/$id';
      final res = await _api.dio.post(path, data: body);
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
      }
      await loadDefines();
      await loadDashboard();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteDefine(int id) async {
    try {
      final res = await _api.dio.post('/payroll/define/$id/delete');
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Delete failed';
      }
      await loadDefines();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> processRun({
    required int projectId,
    required String date,
    int days = 30,
  }) async {
    if (_auth.isDemo) return 'Not available in demo mode';
    try {
      final res = await _api.dio.post('/payroll/process', data: {
        'project_id': projectId,
        'date': date,
        'days': days,
      });
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Process failed';
      }
      await loadRuns(date: date, projectId: projectId);
      await loadDashboard();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> loadPayslip(int id) async {
    try {
      final res = await _api.dio.get('/payroll/payslip/$id');
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Not found';
      }
      payslip = asStringKeyedMap(d['payslip']);
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  List<Map<String, dynamic>> get employees =>
      ((meta['employees'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
  List<Map<String, dynamic>> get projects =>
      ((meta['projects'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
  List<Map<String, dynamic>> get stations =>
      ((meta['stations'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
  List<Map<String, dynamic>> get items =>
      ((meta['items'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();

  Map<String, dynamic> setup = {};
  Map<String, dynamic> payslipOptions = {};
  List<Map<String, dynamic>> calendars = [];
  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> setupItems = [];

  Future<void> loadSetupBundle() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/payroll/setup');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        setup = asStringKeyedMap(d['setup']);
        payslipOptions = asStringKeyedMap(d['payslip_options']);
        calendars = ((d['calendars'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        banks = ((d['banks'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        setupItems = ((d['items'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      } else {
        error = (d is Map ? d['message'] : null)?.toString() ?? 'Setup load failed';
      }
    } on DioException catch (e) {
      error = _msg(e);
    }
    busy = false;
    notifyListeners();
  }

  Future<String?> saveSetup(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/payroll/setup', data: body);
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
      }
      setup = asStringKeyedMap(d['setup']);
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> savePayslipOptions(Map<String, dynamic> body) async {
    try {
      final res = await _api.dio.post('/payroll/payslip-options', data: body);
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
      }
      payslipOptions = asStringKeyedMap(d['payslip_options']);
      notifyListeners();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveCalendar(Map<String, dynamic> body, {int? id}) async {
    try {
      final path = id == null ? '/payroll/calendars' : '/payroll/calendars/$id';
      final res = await _api.dio.post(path, data: body);
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
      }
      await loadSetupBundle();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteCalendar(int id) async {
    try {
      await _api.dio.post('/payroll/calendars/$id/delete');
      await loadSetupBundle();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> saveBank(Map<String, dynamic> body, {int? id}) async {
    try {
      final path = id == null ? '/payroll/banks' : '/payroll/banks/$id';
      final res = await _api.dio.post(path, data: body);
      final d = res.data;
      if (d is! Map || d['success'] != true) {
        return (d is Map ? d['message'] : null)?.toString() ?? 'Save failed';
      }
      await loadSetupBundle();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Future<String?> deleteBank(int id) async {
    try {
      await _api.dio.post('/payroll/banks/$id/delete');
      await loadSetupBundle();
      return null;
    } on DioException catch (e) {
      return _msg(e);
    }
  }

  Map<String, dynamic>? salarySheet;

  Future<Map<String, dynamic>?> loadSalarySheet({String? date, int? projectId}) async {
    try {
      final res = await _api.dio.get('/payroll/salary-sheet', queryParameters: {
        if (date != null) 'date': date,
        if (projectId != null) 'project_id': projectId,
      });
      final d = res.data;
      if (d is Map && d['success'] == true) {
        salarySheet = asStringKeyedMap(d['sheet']);
        notifyListeners();
        return salarySheet;
      }
      error = (d is Map ? d['message'] : null)?.toString();
      return null;
    } on DioException catch (e) {
      error = _msg(e);
      return null;
    }
  }

  String _msg(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) return body['message'].toString();
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach API at ${AppConfig.apiBaseUrl}';
    }
    return e.message ?? 'Network error';
  }
}
