import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import '../network/api_client.dart';
import '../util/json_maps.dart';

class HrReportsState extends ChangeNotifier {
  HrReportsState(this._auth);

  final AuthState _auth;
  bool busy = false;
  String? error;
  int tab = 0;
  Map<String, dynamic> options = {};
  List<Map<String, dynamic>> rows = [];

  // Shared filters
  int? employeeId;
  int? departmentId;
  int? leaveTypeId;
  int? leaveStatus;
  String employeeReportType = 'active';
  String usageGroupBy = 'employee';
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime to = DateTime.now();

  ApiClient get _api => ApiClient(tokenProvider: () async => _auth.session?.token);

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    rows = [];
    notifyListeners();
    load();
  }

  void touch() => notifyListeners();

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadMeta() async {
    try {
      final res = await _api.dio.get('/reports/hr/meta');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        options = asStringKeyedMap(d['options']);
      }
    } catch (_) {}
  }

  Future<void> load() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (options.isEmpty) await loadMeta();
      final Map<String, dynamic> q = {};
      String path;
      switch (tab) {
        case 0: // Leave report
          path = '/reports/hr/leave';
          q['month'] = month.month;
          q['year'] = month.year;
          if (employeeId != null) q['employee_id'] = employeeId;
          if (leaveStatus != null) q['status'] = leaveStatus;
          if (leaveTypeId != null) q['leave_type_id'] = leaveTypeId;
          if (departmentId != null) q['department_id'] = departmentId;
          break;
        case 1: // Leave balance
          path = '/reports/hr/leave/balance';
          if (employeeId != null) q['employee_id'] = employeeId;
          if (leaveTypeId != null) q['leave_type_id'] = leaveTypeId;
          if (departmentId != null) q['department_id'] = departmentId;
          break;
        case 2: // Leave usage
          path = '/reports/hr/leave/usage';
          q['from'] = _ymd(from);
          q['to'] = _ymd(to);
          q['group_by'] = usageGroupBy;
          break;
        case 3: // Employee list
          path = '/reports/hr/employees';
          q['report_type'] = employeeReportType;
          q['from'] = _ymd(from);
          q['to'] = _ymd(to);
          if (departmentId != null) q['department_id'] = departmentId;
          break;
        case 4: // Monthly attendance
          path = '/reports/hr/attendance/monthly';
          q['month'] = month.month;
          q['year'] = month.year;
          if (employeeId != null) q['employee_id'] = employeeId;
          if (departmentId != null) q['department_id'] = departmentId;
          break;
        default: // Attendance log
          path = '/reports/hr/attendance/log';
          q['from'] = _ymd(from);
          q['to'] = _ymd(to);
          if (employeeId != null) q['employee_id'] = employeeId;
          if (departmentId != null) q['department_id'] = departmentId;
          break;
      }
      final res = await _api.dio.get(path, queryParameters: q);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        rows = ((d['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      } else {
        error = (d is Map ? d['message'] : null)?.toString() ?? 'Failed to load report';
        rows = [];
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      error = body is Map && body['message'] != null
          ? body['message'].toString()
          : (e.message ?? 'Network error');
      rows = [];
    } catch (e) {
      error = e.toString();
      rows = [];
    }
    busy = false;
    notifyListeners();
  }
}
