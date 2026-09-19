import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/app_state.dart';
import 'core/auth/auth_state.dart';
import 'core/leave/leave_state.dart';
import 'core/self_service/self_service_state.dart';
import 'theme/app_theme.dart';
import 'theme/hr_theme.dart';
import 'views/login_view.dart';
import 'views/master_crud_view.dart';
import 'views/my_dashboard_view.dart';
import 'views/module_hub_views.dart';
import 'views/dashboard_view.dart';
import 'views/employees_view.dart';
import 'views/employee_roles_view.dart';
import 'views/performance_view.dart';
import 'views/leave_view.dart';
import 'views/recruitment_view.dart';
import 'views/payroll_phase3_view.dart';
import 'views/payroll_setup_view.dart';
import 'views/payroll_reports_view.dart';
import 'views/employee_pay_view.dart';
import 'views/payroll_view.dart';
import 'views/attendance_view.dart';
import 'views/travel_view.dart';
import 'views/timesheet_view.dart';
import 'views/approvals_inbox_view.dart';
import 'views/profile_view.dart';
import 'views/account_settings_view.dart';
import 'widgets/webhr_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AuthState, LeaveState>(
          create: (ctx) => LeaveState(ctx.read<AuthState>()),
          update: (_, auth, prev) => prev ?? LeaveState(auth),
        ),
        ChangeNotifierProxyProvider<AuthState, SelfServiceState>(
          create: (ctx) => SelfServiceState(ctx.read<AuthState>()),
          update: (_, auth, prev) => prev ?? SelfServiceState(auth),
        ),
      ],
      child: const HR360App(),
    ),
  );
}

class HR360App extends StatelessWidget {
  const HR360App({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthState>();

    return MaterialApp(
      title: 'HR360 TechX — 360° Workforce & Talent Cloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeFor(appState.brandColor),
      darkTheme: AppTheme.darkThemeFor(appState.brandColor),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: switch (auth.status) {
        AuthStatus.unknown => const _SplashGate(),
        AuthStatus.unauthenticated => const LoginView(),
        AuthStatus.authenticated => const MainShell(),
      },
    );
  }
}

class _SplashGate extends StatelessWidget {
  const _SplashGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(child: CircularProgressIndicator(color: HrTheme.brand(context))),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _notifsBootstrapped = false;

  bool _isAdminShell(AuthState auth) {
    if (auth.permissions.all || auth.user?.isAdmin == true) return true;
    return auth.canViewModule('AdminSetup') ||
        auth.canViewModule('Payroll') ||
        auth.canViewModule('HiringProcess') ||
        auth.canView('Dashboard', 'AdminDashboard');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notifsBootstrapped) return;
    final auth = context.read<AuthState>();
    if (auth.isDemo || auth.status != AuthStatus.authenticated) return;
    _notifsBootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SelfServiceState>().loadNotifications();
    });
  }

  Widget _resolveScreen(String screen, String title, IconData icon, {String? entity}) {
    switch (screen) {
      case 'my_dashboard':
        return const MyDashboardView();
      case 'hr_dashboard':
        return const DashboardView();
      case 'profile':
        return const ProfileView();
      case 'settings':
        return const AccountSettingsView();
      case 'approvals':
        return const ApprovalsInboxView();
      case 'employees':
        return const EmployeesView();
      case 'employee_roles':
        return const EmployeeRolesView();
      case 'employees_dashboard':
        return const EmployeesDashboardView();
      case 'performance':
        return const PerformanceView();
      case 'recruitment':
        return const RecruitmentView();
      case 'leave':
        return const LeaveView();
      case 'payroll':
        return const PayrollView();
      case 'payroll_process':
        return const PayrollProcessView();
      case 'payroll_define':
        return const PayrollDefineView();
      case 'employee_pay':
        return const EmployeePayView();
      case 'payroll_setup':
        return const PayrollSetupView();
      case 'payroll_reports':
        return const PayrollReportsView();
      case 'attendance':
        return const AttendanceView();
      case 'travel':
        return const TravelView();
      case 'timesheet':
        return const TimesheetView();
      case 'timesheet_dashboard':
        return const TimesheetDashboardView();
      case 'companies':
      case 'master':
        return MasterCrudView(entityKey: entity ?? 'companies');
      case 'placeholder':
      default:
        return ModulePlaceholderView(title: title, icon: icon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final isDark = appState.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final adminShell = _isAdminShell(auth);
    appState.adminShell = adminShell;

    final screen = appState.activeScreen;
    final sub = appState.activeSub;
    final body = _resolveScreen(
      screen,
      sub.label,
      sub.icon,
      entity: sub.entity,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      drawer: isMobile
          ? const Drawer(
              width: 290,
              child: SafeArea(child: WebHrNavRail()),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) const WebHrNavRail(),
          Expanded(
            child: Column(
              children: [
                WebHrTopBar(
                  onMenu: isMobile
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey('${appState.moduleId}-${appState.subId}'),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
