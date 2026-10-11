import '../auth/auth_state.dart';
import '../../navigation/module_catalog.dart';

class NavTarget {
  const NavTarget(this.moduleId, this.subId);

  final String moduleId;
  final String subId;
}

/// Which menu items a signed-in person may open.
/// Admin (status 2) sees every module. Everyone else sees self-service,
/// plus any module turned on in Employee Roles.
class NavAccess {
  NavAccess._();

  static const selfService = {
    'home',
    'my_info',
    'notifications',
    'account_settings',
    'attendance',
    'leaves',
    'employee_hours',
    'salary_payslips',
  };

  /// Submenu id → role-catalog module/screen, when the id differs.
  static const _alias = {
    'hr_dashboard': ('dashboard', 'hr_dashboard'),
    'approvals': ('other', 'approvals'),
    'leaves': ('timesheet', 'leave'),
    'employee_hours': ('timesheet', 'timesheet'),
    'worksheet': ('timesheet', 'timesheet'),
    'define_salary': ('payroll', 'payroll_define'),
    'process_salary': ('payroll', 'payroll_process'),
    'pay_dashboard': ('payroll', 'payroll_process'),
    'payroll_options': ('payroll', 'payroll_setup'),
    'salary_payslips': ('payroll', 'payroll_process'),
    'travels': ('other', 'travel'),
    'payroll_reports_nav': ('reports', 'reports'),
    'att_register_rpt': ('timesheet', 'attendance'),
  };

  static bool unrestricted(AuthState auth) =>
      auth.permissions.all || auth.user?.isAdmin == true;

  static bool canSee(AuthState auth, String moduleId, String subId) {
    if (unrestricted(auth)) return true;
    if (selfService.contains(subId)) return true;
    if (auth.canView(moduleId, subId) || auth.canViewModule(moduleId)) {
      return true;
    }
    final alias = _alias[subId];
    if (alias == null) return false;
    return auth.canView(alias.$1, alias.$2) || auth.canViewModule(alias.$1);
  }

  static List<HrModuleNav> visibleModules(AuthState auth) {
    final out = <HrModuleNav>[];
    for (final module in ModuleCatalog.modules) {
      final children = module.children
          .where((s) => canSee(auth, module.id, s.id))
          .toList();
      if (children.isEmpty) continue;
      out.add(HrModuleNav(
        id: module.id,
        label: module.label,
        icon: module.icon,
        children: children,
      ));
    }
    return out;
  }

  static NavTarget? firstScreen(AuthState auth) {
    final modules = visibleModules(auth);
    if (modules.isEmpty || modules.first.children.isEmpty) return null;
    return NavTarget(modules.first.id, modules.first.children.first.id);
  }
}
