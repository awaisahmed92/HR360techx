import 'package:flutter/foundation.dart';

import '../auth/auth_state.dart';
import 'leave_repository.dart';

class LeaveState extends ChangeNotifier {
  LeaveState(this._auth) {
    _repo = LeaveRepository(getSession: () => _auth.session);
  }

  final AuthState _auth;
  late final LeaveRepository _repo;

  List<LeaveDto> _leaves = [];
  List<LeaveTypeDto> _types = [];
  List<LeaveBalanceDto> _balances = [];
  bool _loading = false;
  String? _error;

  List<LeaveDto> get leaves => _leaves;
  List<LeaveTypeDto> get types => _types;
  List<LeaveBalanceDto> get balances => _balances;
  bool get loading => _loading;
  String? get error => _error;

  List<LeaveDto> get pendingApprovals =>
      _leaves.where((l) => l.canApprove).toList();

  Future<void> load() async {
    if (_auth.isDemo) {
      _leaves = [];
      _types = const [
        LeaveTypeDto(id: 1, name: 'Annual Leave', days: 24),
        LeaveTypeDto(id: 2, name: 'Sick Leave', days: 12),
        LeaveTypeDto(id: 3, name: 'Casual Leave', days: 6),
      ];
      _balances = const [
        LeaveBalanceDto(name: 'Annual Leave', totalDays: 24, usedLeaves: 6),
        LeaveBalanceDto(name: 'Sick Leave', totalDays: 12, usedLeaves: 2),
        LeaveBalanceDto(name: 'Casual Leave', totalDays: 6, usedLeaves: 1),
      ];
      _error = null;
      notifyListeners();
      return;
    }

    if (!_auth.isAuthenticated) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final meta = await _repo.fetchTypes();
      final list = await _repo.fetchLeaves();
      _types = meta.types;
      _balances = meta.balances;
      _leaves = list;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> applyLeave({
    required int leaveTypeId,
    required String from,
    required String to,
    required int days,
    required String reason,
  }) async {
    if (_auth.isDemo) {
      return 'Demo mode uses mock leave data only. Sign in with a real tenant to apply.';
    }
    try {
      await _repo.apply(
        leaveTypeId: leaveTypeId,
        from: from,
        to: to,
        days: days,
        reason: reason,
      );
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> approve(int id, {String remarks = ''}) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.approve(id, remarks: remarks);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> reject(int id, {String remarks = ''}) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.reject(id, remarks: remarks);
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  List<Map<String, dynamic>> thresholds = [];

  Future<void> loadThresholds() async {
    if (_auth.isDemo) {
      thresholds = [];
      notifyListeners();
      return;
    }
    try {
      thresholds = await _repo.fetchThresholds();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> saveThreshold(Map<String, dynamic> body, {int? id}) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.saveThreshold(body, id: id);
      await loadThresholds();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteThreshold(int id) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.deleteThreshold(id);
      await loadThresholds();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  List<LeaveTypeDto> managedTypes = [];
  Map<String, dynamic> moduleOptions = {};

  Future<void> loadManagedTypes() async {
    if (_auth.isDemo) {
      managedTypes = List.from(_types);
      notifyListeners();
      return;
    }
    try {
      managedTypes = await _repo.manageTypes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<String?> saveLeaveType(Map<String, dynamic> body, {int? id}) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      if (id == null) {
        await _repo.createType(body);
      } else {
        await _repo.updateType(id, body);
      }
      await loadManagedTypes();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteLeaveType(int id) async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.deleteType(id);
      await loadManagedTypes();
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> loadModuleOptions() async {
    if (_auth.isDemo) {
      moduleOptions = {};
      notifyListeners();
      return;
    }
    try {
      moduleOptions = await _repo.moduleOptions();
    } catch (_) {}
    notifyListeners();
  }

  Future<String?> saveModuleOptions() async {
    if (_auth.isDemo) return 'Not available in demo mode.';
    try {
      await _repo.saveModuleOptions(moduleOptions);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void patchModuleOption(String key, bool value) {
    moduleOptions = {...moduleOptions, key: value};
    notifyListeners();
  }
}
