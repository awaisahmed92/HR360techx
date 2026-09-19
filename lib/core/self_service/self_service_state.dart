import 'package:flutter/foundation.dart';

import '../auth/auth_models.dart';
import '../auth/auth_state.dart';
import '../util/json_maps.dart';
import 'self_service_repository.dart';

class SelfServiceState extends ChangeNotifier {
  SelfServiceState(this._auth) {
    _repo = SelfServiceRepository(getSession: () => _auth.session);
  }

  final AuthState _auth;
  late final SelfServiceRepository _repo;

  AuthSession? get sessionOrNull => _auth.session;

  Map<String, dynamic>? profile;
  Map<String, dynamic>? attendanceToday;
  List<Map<String, dynamic>> attendanceMonth = [];
  List<Map<String, dynamic>> travels = [];
  List<Map<String, dynamic>> timesheets = [];
  List<Map<String, dynamic>> approvals = [];
  bool loading = false;
  String? error;

  Future<void> loadProfile() async {
    if (_auth.isDemo) {
      profile = {
        'name': _auth.user?.name ?? 'Demo Admin',
        'email': _auth.user?.email ?? 'admin@demo.local',
        'phone': '',
        'designation_name': _auth.user?.designationName ?? 'HR Manager',
        'department_name': 'Human Resources',
        'employee_code': 'EMP-001',
      };
      notifyListeners();
      return;
    }
    try {
      final d = await _repo.profile();
      profile = Map<String, dynamic>.from(d['profile'] as Map);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> saveProfile({required String email, required String phone, Map<String, dynamic>? extra}) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.updateProfile(email: email, phone: phone, extra: extra);
      await loadProfile();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadAttendance() async {
    if (_auth.isDemo) {
      attendanceToday = {
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'can_punch_in': true,
        'can_punch_out': false,
        'record': null,
      };
      attendanceMonth = [];
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      attendanceToday = await _repo.attendanceToday();
      final month = DateTime.now().toIso8601String().substring(0, 7);
      final m = await _repo.attendanceMonth(month);
      attendanceMonth = (m['records'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<String?> punch(String action) async {
    if (_auth.isDemo) return 'Sign in with live API to punch.';
    try {
      await _repo.punch(action);
      await loadAttendance();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadTravel() async {
    if (_auth.isDemo) {
      travels = [];
      notifyListeners();
      return;
    }
    try {
      travels = await _repo.travels();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> applyTravel(Map<String, dynamic> body) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.applyTravel(body);
      await loadTravel();
      await loadNotifications();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> travelAct(String action, int id) async {
    try {
      await _repo.travelAct(action, id);
      await loadTravel();
      await loadApprovals();
      await loadNotifications();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadTimesheet() async {
    if (_auth.isDemo) {
      timesheets = [];
      notifyListeners();
      return;
    }
    try {
      timesheets = await _repo.timesheets();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> applyTimesheet(Map<String, dynamic> body) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.applyTimesheet(body);
      await loadTimesheet();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> timesheetAct(String action, int id) async {
    try {
      await _repo.timesheetAct(action, id);
      await loadTimesheet();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadApprovals() async {
    if (_auth.isDemo) {
      approvals = [];
      notifyListeners();
      return;
    }
    try {
      approvals = await _repo.approvalsInbox();
      error = null;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  // ── Workflow settings (approvals + notifications) ──
  Map<String, dynamic> approvalSettings = {};
  Map<String, dynamic> notificationSettings = {};
  List<Map<String, dynamic>> workflowEmployees = [];
  List<Map<String, dynamic>> inboxNotifications = [];
  int unreadNotifications = 0;
  String? workflowError;

  void patchApprovalLocal(Map<String, dynamic> patch) {
    approvalSettings = {...approvalSettings, ...patch};
    notifyListeners();
  }

  void patchNotificationLocal(Map<String, dynamic> patch) {
    notificationSettings = {...notificationSettings, ...patch};
    notifyListeners();
  }

  Future<void> loadWorkflowSettings(String module) async {
    if (_auth.isDemo) {
      workflowError = 'Sign in with live API to edit workflow settings.';
      notifyListeners();
      return;
    }
    try {
      final a = await _repo.approvalSettings(module);
      approvalSettings = Map<String, dynamic>.from(a['settings'] as Map? ?? {});
      workflowEmployees = (a['employees'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final n = await _repo.notificationSettings(module);
      notificationSettings =
          Map<String, dynamic>.from(n['settings'] as Map? ?? {});
      workflowError = null;
    } catch (e) {
      workflowError = e.toString();
    }
    notifyListeners();
  }

  Future<String?> saveApprovalSettings(String module) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      final assigneesRaw = asStringKeyedMap(approvalSettings['level_assignees']);
      final assignees = <String, int>{};
      assigneesRaw.forEach((k, v) {
        if (v is Map && v['employee_id'] != null) {
          assignees[k] = (v['employee_id'] as num).toInt();
        } else if (v is num) {
          assignees[k] = v.toInt();
        }
      });
      final res = await _repo.saveApprovalSettings(module, {
        'approval_method': approvalSettings['approval_method'] ?? 'multi_level',
        'approval_levels': approvalSettings['approval_levels'] ?? 1,
        'restart_on_edit': approvalSettings['restart_on_edit'] == true,
        'skip_specific': approvalSettings['skip_specific'] == true,
        'hide_rejected': approvalSettings['hide_rejected'] == true,
        'do_not_notify_employee':
            approvalSettings['do_not_notify_employee'] == true,
        'sms_on_submission': approvalSettings['sms_on_submission'] == true,
        'level_assignees': assignees,
      });
      approvalSettings =
          Map<String, dynamic>.from(res['settings'] as Map? ?? {});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> saveNotificationSettings(String module) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      final res = await _repo.saveNotificationSettings(module, {
        'do_not_notify_employee':
            notificationSettings['do_not_notify_employee'] == true,
        'sms_on_submission': notificationSettings['sms_on_submission'] == true,
        'notify_on_submission': notificationSettings['notify_on_submission'] ?? [],
        'notify_on_approval': notificationSettings['notify_on_approval'] ?? [],
        'notify_on_reassignment':
            notificationSettings['notify_on_reassignment'] ?? [],
      });
      notificationSettings =
          Map<String, dynamic>.from(res['settings'] as Map? ?? {});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadNotifications() async {
    if (_auth.isDemo) {
      inboxNotifications = [];
      unreadNotifications = 0;
      notifyListeners();
      return;
    }
    try {
      final d = await _repo.notifications();
      inboxNotifications = (d['notifications'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      unreadNotifications = (d['unread_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // keep previous
    }
    notifyListeners();
  }

  Future<void> markNotificationsRead({int? id}) async {
    try {
      await _repo.markNotificationsRead(id: id);
      await loadNotifications();
    } catch (_) {}
  }
}
