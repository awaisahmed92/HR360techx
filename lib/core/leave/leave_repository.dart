import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../network/api_client.dart';

class LeaveTypeDto {
  final int id;
  final String name;
  final int days;
  final String calendarTitle;
  final String referenceNumber;
  final String category;
  final String durationType;
  final bool quotaReset;
  final bool isActive;

  const LeaveTypeDto({
    required this.id,
    required this.name,
    required this.days,
    this.calendarTitle = '',
    this.referenceNumber = '',
    this.category = 'Paid Leave',
    this.durationType = 'Days',
    this.quotaReset = false,
    this.isActive = true,
  });

  factory LeaveTypeDto.fromJson(Map<String, dynamic> json) => LeaveTypeDto(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] ?? json['title'] ?? '').toString(),
        days: (json['days'] as num?)?.toInt() ??
            (json['leaves_allowed_per_year'] as num?)?.toInt() ??
            0,
        calendarTitle: (json['calendar_title'] ?? '').toString(),
        referenceNumber: (json['reference_number'] ?? '').toString(),
        category: (json['category'] ?? 'Paid Leave').toString(),
        durationType: (json['duration_type'] ?? 'Days').toString(),
        quotaReset: json['quota_reset'] == true,
        isActive: json['is_active'] != false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LeaveTypeDto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class LeaveBalanceDto {
  final String name;
  final int totalDays;
  final int usedLeaves;

  const LeaveBalanceDto({
    required this.name,
    required this.totalDays,
    required this.usedLeaves,
  });

  int get available => (totalDays - usedLeaves).clamp(0, totalDays);

  factory LeaveBalanceDto.fromJson(Map<String, dynamic> json) => LeaveBalanceDto(
        name: (json['name'] ?? '').toString(),
        totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
        usedLeaves: (json['used_leaves'] as num?)?.toInt() ?? 0,
      );
}

class LeaveDto {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeCode;
  final int leaveTypeId;
  final String leaveType;
  final String from;
  final String to;
  final int days;
  final String reason;
  final int status;
  final String statusLabel;
  final String processStatus;
  final String approvalStepLabel;
  final bool canApprove;
  final String date;

  const LeaveDto({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.leaveTypeId,
    required this.leaveType,
    required this.from,
    required this.to,
    required this.days,
    required this.reason,
    required this.status,
    required this.statusLabel,
    required this.processStatus,
    required this.approvalStepLabel,
    required this.canApprove,
    required this.date,
  });

  factory LeaveDto.fromJson(Map<String, dynamic> json) => LeaveDto(
        id: (json['id'] as num?)?.toInt() ?? 0,
        employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
        employeeName: (json['employee_name'] ?? '').toString(),
        employeeCode: (json['employee_code'] ?? '').toString(),
        leaveTypeId: (json['leave_type_id'] as num?)?.toInt() ?? 0,
        leaveType: (json['leave_type'] ?? '').toString(),
        from: (json['from'] ?? '').toString(),
        to: (json['to'] ?? '').toString(),
        days: (json['days'] as num?)?.toInt() ?? 0,
        reason: (json['reason'] ?? '').toString(),
        status: (json['status'] as num?)?.toInt() ?? 0,
        statusLabel: (json['status_label'] ?? 'Pending').toString(),
        processStatus: (json['process_status'] ?? '').toString(),
        approvalStepLabel: (json['approval_step_label'] ?? '').toString(),
        canApprove: json['can_approve'] == true,
        date: (json['date'] ?? '').toString(),
      );
}

class LeaveApiException implements Exception {
  LeaveApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LeaveRepository {
  LeaveRepository({required this.getSession});

  final AuthSession? Function() getSession;

  ApiClient _client() {
    return ApiClient(tokenProvider: () async => getSession()?.token);
  }

  Future<({List<LeaveTypeDto> types, List<LeaveBalanceDto> balances})>
      fetchTypes() async {
    try {
      final res = await _client().dio.get('/leave/types');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ??
              'Failed to load leave types',
        );
      }
      final types = <LeaveTypeDto>[];
      final balances = <LeaveBalanceDto>[];
      for (final t in (data['types'] as List? ?? [])) {
        if (t is Map) {
          types.add(LeaveTypeDto.fromJson(Map<String, dynamic>.from(t)));
        }
      }
      for (final b in (data['balances'] as List? ?? [])) {
        if (b is Map) {
          balances.add(LeaveBalanceDto.fromJson(Map<String, dynamic>.from(b)));
        }
      }
      return (types: types, balances: balances);
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<List<LeaveDto>> fetchLeaves() async {
    try {
      final res = await _client().dio.get('/leave');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ??
              'Failed to load leaves',
        );
      }
      final list = <LeaveDto>[];
      for (final row in (data['leaves'] as List? ?? [])) {
        if (row is Map) {
          list.add(LeaveDto.fromJson(Map<String, dynamic>.from(row)));
        }
      }
      return list;
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> apply({
    required int leaveTypeId,
    required String from,
    required String to,
    required int days,
    required String reason,
  }) async {
    try {
      final res = await _client().dio.post('/leave/apply', data: {
        'leave_type_id': leaveTypeId,
        'from': from,
        'to': to,
        'days': days,
        'reason': reason,
      });
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Apply failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> approve(int id, {String remarks = ''}) async {
    await _act('/leave/approve', id, remarks);
  }

  Future<void> reject(int id, {String remarks = ''}) async {
    await _act('/leave/reject', id, remarks);
  }

  Future<List<LeaveTypeDto>> manageTypes() async {
    try {
      final res = await _client().dio.get('/leave-types');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException('Failed to load leave types');
      }
      return (data['types'] as List? ?? [])
          .whereType<Map>()
          .map((e) => LeaveTypeDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<LeaveTypeDto> createType(Map<String, dynamic> body) async {
    try {
      final res = await _client().dio.post('/leave-types', data: body);
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Create failed',
        );
      }
      return LeaveTypeDto.fromJson(Map<String, dynamic>.from(data['type'] as Map));
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> updateType(int id, Map<String, dynamic> body) async {
    try {
      final res = await _client().dio.post('/leave-types/$id', data: body);
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Update failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> deleteType(int id) async {
    try {
      final res = await _client().dio.post('/leave-types/$id/delete');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Delete failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<Map<String, dynamic>> moduleOptions() async {
    try {
      final res = await _client().dio.get('/leave/module-options');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        return {};
      }
      return Map<String, dynamic>.from(data['options'] as Map? ?? {});
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> saveModuleOptions(Map<String, dynamic> body) async {
    try {
      final res = await _client().dio.post('/leave/module-options', data: body);
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Save failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<List<Map<String, dynamic>>> fetchThresholds() async {
    try {
      final res = await _client().dio.get('/leave-thresholds');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Load failed',
        );
      }
      return (data['rows'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> saveThreshold(Map<String, dynamic> body, {int? id}) async {
    try {
      final res = id == null
          ? await _client().dio.post('/leave-thresholds', data: body)
          : await _client().dio.post('/leave-thresholds/$id', data: body);
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Save failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> deleteThreshold(int id) async {
    try {
      final res = await _client().dio.post('/leave-thresholds/$id/delete');
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Delete failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  Future<void> _act(String path, int id, String remarks) async {
    try {
      final res = await _client().dio.post(path, data: {
        'id': id,
        'remarks': remarks,
      });
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw LeaveApiException(
          (data is Map ? data['message'] : null)?.toString() ?? 'Action failed',
        );
      }
    } on DioException catch (e) {
      throw LeaveApiException(_dioMessage(e));
    }
  }

  String _dioMessage(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return e.message ?? 'Network error';
  }
}
