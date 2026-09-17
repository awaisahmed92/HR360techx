class LeaveRequest {
  final String id;
  final String employeeName;
  final String employeeRole;
  final String employeeAvatar;
  final String type; // 'Annual Leave', 'Sick Leave', 'Casual Leave', 'Work From Home'
  final String startDate;
  final String endDate;
  final int days;
  final String reason;
  String status; // 'Approved', 'Pending', 'Rejected'
  final String submittedDate;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.employeeRole,
    required this.employeeAvatar,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.reason,
    required this.status,
    required this.submittedDate,
  });
}
