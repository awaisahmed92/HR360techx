import 'package:flutter/material.dart';

/// WebHR-style primary modules + secondary submenu items.
class HrSubNav {
  const HrSubNav({
    required this.id,
    required this.label,
    required this.icon,
    this.screen = 'placeholder',
    this.entity,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Maps to a concrete Flutter screen key (or `placeholder` / `master`).
  final String screen;

  /// When [screen] is `master`, this is the MasterRegistry entity key.
  final String? entity;
}

class HrModuleNav {
  const HrModuleNav({
    required this.id,
    required this.label,
    required this.icon,
    required this.children,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<HrSubNav> children;
}

class ModuleCatalog {
  ModuleCatalog._();

  static const List<HrModuleNav> modules = [
    HrModuleNav(
      id: 'dashboard',
      label: 'Dashboard',
      icon: Icons.home_outlined,
      children: [
        HrSubNav(id: 'home', label: 'Home', icon: Icons.dashboard_outlined, screen: 'my_dashboard'),
        HrSubNav(id: 'my_info', label: 'My Info', icon: Icons.person_outline, screen: 'profile'),
        HrSubNav(id: 'hr_dashboard', label: 'HR Dashboard', icon: Icons.analytics_outlined, screen: 'hr_dashboard'),
        HrSubNav(id: 'approvals', label: 'Approvals', icon: Icons.inbox_outlined, screen: 'approvals'),
        HrSubNav(id: 'notifications', label: 'Notifications', icon: Icons.notifications_outlined, screen: 'notifications'),
        HrSubNav(id: 'account_settings', label: 'Account Settings', icon: Icons.settings_outlined, screen: 'settings'),
      ],
    ),
    HrModuleNav(
      id: 'organization',
      label: 'Organization',
      icon: Icons.apartment_outlined,
      children: [
        HrSubNav(id: 'companies', label: 'Companies', icon: Icons.business_outlined, screen: 'master', entity: 'companies'),
        HrSubNav(id: 'divisions', label: 'Divisions', icon: Icons.account_tree_outlined, screen: 'master', entity: 'divisions'),
        HrSubNav(id: 'cost_centers', label: 'Cost Centers', icon: Icons.attach_money_outlined, screen: 'master', entity: 'cost_centers'),
        HrSubNav(id: 'stations', label: 'Stations', icon: Icons.place_outlined, screen: 'master', entity: 'stations'),
        HrSubNav(id: 'parent_departments', label: 'Parent Departments', icon: Icons.schema_outlined, screen: 'master', entity: 'parent_departments'),
        HrSubNav(id: 'departments', label: 'Departments', icon: Icons.groups_outlined, screen: 'master', entity: 'departments'),
        HrSubNav(id: 'designations', label: 'Designations', icon: Icons.work_outline, screen: 'master', entity: 'designations'),
        HrSubNav(id: 'projects', label: 'Projects', icon: Icons.folder_special_outlined, screen: 'master', entity: 'projects'),
        HrSubNav(id: 'teams', label: 'Teams', icon: Icons.group_work_outlined, screen: 'master', entity: 'teams'),
        HrSubNav(id: 'policies', label: 'Policies', icon: Icons.policy_outlined, screen: 'master', entity: 'policies'),
        HrSubNav(id: 'announcements', label: 'Announcements', icon: Icons.campaign_outlined, screen: 'master', entity: 'announcements'),
        HrSubNav(id: 'letters', label: 'HR Letters', icon: Icons.mail_outline, screen: 'letters'),
        HrSubNav(id: 'system_settings', label: 'System Settings', icon: Icons.tune_outlined, screen: 'settings'),
        HrSubNav(id: 'system_logs', label: 'System Logs', icon: Icons.receipt_long_outlined, screen: 'master', entity: 'system_logs'),
      ],
    ),
    HrModuleNav(
      id: 'employees',
      label: 'Employees',
      icon: Icons.people_outline,
      children: [
        HrSubNav(id: 'emp_dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined, screen: 'employees_dashboard'),
        HrSubNav(id: 'employees', label: 'Employees', icon: Icons.badge_outlined, screen: 'employees'),
        HrSubNav(id: 'employee_roles', label: 'Employee Roles', icon: Icons.security_outlined, screen: 'employee_roles'),
        HrSubNav(id: 'onboarding', label: 'Onboarding', icon: Icons.person_add_alt_1_outlined, screen: 'employees'),
        HrSubNav(id: 'employment_change', label: 'Employment Change', icon: Icons.swap_horiz_outlined, screen: 'master', entity: 'employment_changes'),
        HrSubNav(id: 'contracts', label: 'Contracts', icon: Icons.description_outlined, screen: 'master', entity: 'contracts'),
        HrSubNav(id: 'assignments', label: 'Assignments', icon: Icons.assignment_ind_outlined, screen: 'master', entity: 'assignments'),
        HrSubNav(id: 'transfers', label: 'Transfers', icon: Icons.sync_alt_outlined, screen: 'master', entity: 'transfers'),
        HrSubNav(id: 'resignations', label: 'Resignations', icon: Icons.logout_outlined, screen: 'master', entity: 'resignations'),
        HrSubNav(id: 'termination', label: 'Termination', icon: Icons.person_off_outlined, screen: 'termination'),
        HrSubNav(id: 'loan_applications', label: 'Loan Applications', icon: Icons.request_page_outlined, screen: 'loan_applications'),
        HrSubNav(id: 'letters_emp', label: 'HR Letters', icon: Icons.mail_outline, screen: 'letters'),
        HrSubNav(id: 'achievements', label: 'Achievements', icon: Icons.emoji_events_outlined, screen: 'master', entity: 'achievements'),
        HrSubNav(id: 'travels', label: 'Travels', icon: Icons.flight_takeoff_outlined, screen: 'travel'),
        HrSubNav(id: 'promotions', label: 'Promotions', icon: Icons.trending_up_outlined, screen: 'master', entity: 'promotions'),
        HrSubNav(id: 'complaints', label: 'Complaints', icon: Icons.report_outlined, screen: 'master', entity: 'complaints'),
        HrSubNav(id: 'discipline', label: 'Discipline', icon: Icons.gavel_outlined, screen: 'master', entity: 'discipline'),
        HrSubNav(id: 'performance', label: '360° Performance', icon: Icons.radar_outlined, screen: 'performance'),
        HrSubNav(id: 'recruitment', label: 'Talent Pipeline', icon: Icons.view_kanban_outlined, screen: 'recruitment'),
        HrSubNav(id: 'training', label: 'Training', icon: Icons.school_outlined, screen: 'training'),
      ],
    ),
    HrModuleNav(
      id: 'training_mod',
      label: 'Training',
      icon: Icons.school_outlined,
      children: [
        HrSubNav(id: 'training_list', label: 'Training List', icon: Icons.list_alt_outlined, screen: 'training'),
        HrSubNav(id: 'training_calendar', label: 'Calendar', icon: Icons.calendar_month_outlined, screen: 'training_calendar'),
        HrSubNav(id: 'trainers', label: 'Trainers', icon: Icons.person_outline, screen: 'training_trainers'),
        HrSubNav(id: 'training_types', label: 'Training Types', icon: Icons.category_outlined, screen: 'training_types'),
      ],
    ),
    HrModuleNav(
      id: 'timesheet',
      label: 'Timesheet',
      icon: Icons.access_time_outlined,
      children: [
        HrSubNav(id: 'ts_dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined, screen: 'timesheet_dashboard'),
        HrSubNav(id: 'attendance', label: 'Attendance', icon: Icons.fingerprint_outlined, screen: 'attendance'),
        HrSubNav(id: 'admin_attendance', label: 'Admin Attendance', icon: Icons.fact_check_outlined, screen: 'admin_attendance'),
        HrSubNav(id: 'schedule', label: 'Schedule', icon: Icons.view_week_outlined, screen: 'schedule'),
        HrSubNav(id: 'att_register', label: 'Attendance Register', icon: Icons.assignment_outlined, screen: 'attendance_register'),
        HrSubNav(id: 'devices', label: 'Devices', icon: Icons.devices_other_outlined, screen: 'devices'),
        HrSubNav(id: 'employee_hours', label: 'Employee Hours', icon: Icons.hourglass_bottom_outlined, screen: 'timesheet'),
        HrSubNav(id: 'worksheet', label: 'Worksheet', icon: Icons.table_chart_outlined, screen: 'timesheet'),
        HrSubNav(id: 'leaves', label: 'Leaves', icon: Icons.event_available_outlined, screen: 'leave'),
        HrSubNav(id: 'work_shifts', label: 'Work Shifts', icon: Icons.schedule_outlined, screen: 'master', entity: 'work_shifts'),
        HrSubNav(id: 'holidays', label: 'Holidays', icon: Icons.celebration_outlined, screen: 'master', entity: 'holidays'),
        HrSubNav(id: 'wfh', label: 'Work From Home', icon: Icons.home_work_outlined, screen: 'master', entity: 'wfh'),
        HrSubNav(id: 'flex_hours', label: 'Flex Hours', icon: Icons.timelapse_outlined, screen: 'master', entity: 'flex_hours'),
      ],
    ),
    HrModuleNav(
      id: 'payroll',
      label: 'Payroll',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        // PHP sidebar order: Define → Process → Items → Setup → EOBI → PF → SESSI → Tax → Reports
        HrSubNav(id: 'define_salary', label: 'Define Salary', icon: Icons.payments_outlined, screen: 'payroll_define'),
        HrSubNav(id: 'process_salary', label: 'Process Salary', icon: Icons.play_circle_outline, screen: 'payroll_process'),
        HrSubNav(id: 'payroll_items', label: 'Payroll Items', icon: Icons.list_alt_outlined, screen: 'master', entity: 'payroll_items'),
        HrSubNav(id: 'payroll_formulas', label: 'Payroll Setup', icon: Icons.rule_outlined, screen: 'master', entity: 'payroll_formulas'),
        HrSubNav(id: 'eobi_setup', label: 'EOBI', icon: Icons.health_and_safety_outlined, screen: 'master', entity: 'eobi_setup'),
        HrSubNav(id: 'pf_setup', label: 'Provident Fund', icon: Icons.savings_outlined, screen: 'master', entity: 'pf_setup'),
        HrSubNav(id: 'sessi_setup', label: 'SESSI', icon: Icons.medical_services_outlined, screen: 'master', entity: 'sessi_setup'),
        HrSubNav(id: 'tax_slabs', label: 'Tax', icon: Icons.receipt_long_outlined, screen: 'master', entity: 'tax_slabs'),
        HrSubNav(id: 'payroll_reports', label: 'Reports', icon: Icons.assessment_outlined, screen: 'payroll_reports'),
        HrSubNav(id: 'pay_dashboard', label: 'Dashboard', icon: Icons.show_chart_outlined, screen: 'payroll_process'),
        HrSubNav(id: 'payroll_options', label: 'Payroll Options', icon: Icons.storage_outlined, screen: 'payroll_setup'),
        HrSubNav(id: 'employee_salary', label: 'Employee Salary', icon: Icons.person_outline, screen: 'employee_pay'),
        HrSubNav(id: 'eobi_rates', label: 'EOBI Rates', icon: Icons.percent_outlined, screen: 'master', entity: 'eobi_rates'),
        HrSubNav(id: 'sessi_rates', label: 'SESSI Rates', icon: Icons.percent_outlined, screen: 'master', entity: 'sessi_rates'),
        HrSubNav(id: 'pf_rates', label: 'PF Rates', icon: Icons.percent_outlined, screen: 'master', entity: 'pf_rates'),
        HrSubNav(id: 'salary_scales', label: 'Salary Scales', icon: Icons.bar_chart_outlined, screen: 'master', entity: 'salary_scales'),
        HrSubNav(id: 'hourly_wages', label: 'Hourly Wages', icon: Icons.hourglass_empty_outlined, screen: 'master', entity: 'hourly_wages'),
        HrSubNav(id: 'bonuses', label: 'Bonuses', icon: Icons.add_circle_outline, screen: 'master', entity: 'bonuses'),
        HrSubNav(id: 'commissions', label: 'Commissions', icon: Icons.thumb_up_outlined, screen: 'master', entity: 'commissions'),
        HrSubNav(id: 'deductions', label: 'Deductions', icon: Icons.trending_down_outlined, screen: 'master', entity: 'deductions'),
        HrSubNav(id: 'allowances', label: 'Allowances', icon: Icons.savings_outlined, screen: 'master', entity: 'allowances'),
        HrSubNav(id: 'earnings', label: 'Earnings', icon: Icons.monetization_on_outlined, screen: 'master', entity: 'earnings'),
        HrSubNav(id: 'adjustments', label: 'Adjustments', icon: Icons.credit_card_outlined, screen: 'master', entity: 'adjustments'),
        HrSubNav(id: 'ctc', label: 'Cost To Company', icon: Icons.edit_outlined, screen: 'master', entity: 'ctc'),
        HrSubNav(id: 'overtime', label: 'Overtime', icon: Icons.alarm_outlined, screen: 'master', entity: 'overtime'),
        HrSubNav(id: 'advance', label: 'Advance', icon: Icons.money_outlined, screen: 'master', entity: 'advance'),
        HrSubNav(id: 'loans', label: 'Loans (Recovery)', icon: Icons.account_balance_outlined, screen: 'master', entity: 'loans'),
        HrSubNav(id: 'loan_apps_pay', label: 'Loan Applications', icon: Icons.request_page_outlined, screen: 'loan_applications'),
        HrSubNav(id: 'arrears', label: 'Arrears', icon: Icons.restore_outlined, screen: 'master', entity: 'arrears'),
        HrSubNav(id: 'final_settlements', label: 'Final Settlement', icon: Icons.handshake_outlined, screen: 'master', entity: 'final_settlements'),
      ],
    ),
    HrModuleNav(
      id: 'directory',
      label: 'Directory',
      icon: Icons.contact_page_outlined,
      children: [
        HrSubNav(id: 'directory', label: 'Employee Directory', icon: Icons.menu_book_outlined, screen: 'employees'),
      ],
    ),
    HrModuleNav(
      id: 'calendar',
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      children: [
        HrSubNav(id: 'calendar', label: 'Company Calendar', icon: Icons.event_outlined, screen: 'master', entity: 'holidays'),
      ],
    ),
    HrModuleNav(
      id: 'files',
      label: 'Files',
      icon: Icons.folder_outlined,
      children: [
        HrSubNav(id: 'files', label: 'Documents', icon: Icons.insert_drive_file_outlined, screen: 'master', entity: 'policies'),
      ],
    ),
    HrModuleNav(
      id: 'reports',
      label: 'Reports',
      icon: Icons.description_outlined,
      children: [
        HrSubNav(id: 'att_register_rpt', label: 'Attendance Register', icon: Icons.assignment_outlined, screen: 'attendance_register'),
        HrSubNav(id: 'payroll_reports_nav', label: 'Payroll Reports', icon: Icons.payments_outlined, screen: 'payroll_reports'),
        HrSubNav(id: 'reports', label: 'HR Reports', icon: Icons.assessment_outlined, screen: 'hr_reports'),
      ],
    ),
  ];

  static HrModuleNav byId(String id) =>
      modules.firstWhere((m) => m.id == id, orElse: () => modules.first);

  static HrSubNav subById(HrModuleNav module, String subId) =>
      module.children.firstWhere((c) => c.id == subId, orElse: () => module.children.first);
}
