import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'controllers/app_state.dart';
import 'core/auth/auth_state.dart';
import 'core/leave/leave_state.dart';
import 'core/self_service/self_service_state.dart';
import 'core/settings/ui_prefs_repository.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/master_crud_view.dart';
import 'views/my_dashboard_view.dart';
import 'views/module_hub_views.dart';
import 'views/dashboard_view.dart';
import 'views/employees_dashboard_view.dart';
import 'views/employee_directory_view.dart';
import 'views/employees_view.dart';
import 'views/employee_roles_view.dart';
import 'views/performance_view.dart';
import 'views/leave_view.dart';
import 'views/recruitment_view.dart';
import 'views/training_view.dart';
import 'views/lifecycle_views.dart';
import 'views/letters_notifications_view.dart';
import 'views/payroll_phase3_view.dart';
import 'views/payroll_setup_view.dart';
import 'views/payroll_reports_view.dart';
import 'views/hr_reports_view.dart';
import 'views/employee_pay_view.dart';
import 'views/payroll_view.dart';
import 'views/attendance_view.dart';
import 'views/admin_attendance_view.dart';
import 'views/schedule_view.dart';
import 'views/devices_view.dart';
import 'views/attendance_register_view.dart';
import 'views/travel_view.dart';
import 'views/timesheet_view.dart';
import 'views/approvals_inbox_view.dart';
import 'views/profile_view.dart';
import 'views/sign_up_view.dart';
import 'core/config/browser_path_stub.dart'
    if (dart.library.html) 'core/config/browser_path_web.dart';
import 'views/account_settings_view.dart';
import 'views/system_settings_view.dart';
import 'widgets/webhr_nav.dart';

/// Read once, before Flutter rewrites the address bar to `/`.
bool _launchOnSignUp = false;

bool _locationWantsSignUp() {
  final url = Uri.base;
  final target = '${url.path} ${url.fragment}'.toLowerCase();
  return target.contains('sign-up') || target.contains('signup');
}

void main() {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  _launchOnSignUp = _locationWantsSignUp();
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

    return MaterialApp(
      title: 'HR360 TechX — 360° Workforce & Talent Cloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeFor(appState.brandColor),
      darkTheme: AppTheme.darkThemeFor(appState.brandColor),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: (settings) {
        final name = (settings.name ?? '').toLowerCase();
        final signUp = _launchOnSignUp ||
            name.contains('sign-up') ||
            name.contains('signup');
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: signUp ? '/sign-up' : '/'),
          builder: (_) => _Root(startOnSignUp: signUp),
        );
      },
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({required this.startOnSignUp});

  final bool startOnSignUp;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return switch (auth.status) {
      AuthStatus.unknown => const _SessionRestoreHold(),
      AuthStatus.unauthenticated => _PublicEntry(startOnSignUp: startOnSignUp),
      AuthStatus.authenticated => const MainShell(),
    };
  }
}

/// Login, or the public sign-up form when the browser is on /sign-up.
class _PublicEntry extends StatefulWidget {
  const _PublicEntry({required this.startOnSignUp});

  final bool startOnSignUp;

  @override
  State<_PublicEntry> createState() => _PublicEntryState();
}

class _PublicEntryState extends State<_PublicEntry> {
  late bool _signUp = widget.startOnSignUp || _locationWantsSignUp();

  @override
  void initState() {
    super.initState();
    if (_signUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setBrowserPath('/sign-up');
      });
    }
  }

  void _openLogin() {
    _launchOnSignUp = false;
    setState(() => _signUp = false);
    setBrowserPath('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_signUp) {
      return SignUpView(onBackToLogin: _openLogin);
    }

    return const LoginView();
  }
}

/// Hold while SharedPreferences restores the token. Never show Login here —
/// that is what caused the refresh flash (login → dashboard).
class _SessionRestoreHold extends StatelessWidget {
  const _SessionRestoreHold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1E),
      body: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF2A72B5),
          ),
        ),
      ),
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
  bool _themeBootstrapped = false;
  UiPrefsRepository? _uiPrefs;

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
    final auth = context.read<AuthState>();
    final app = context.read<AppState>();

    _uiPrefs ??= UiPrefsRepository(getSession: () => auth.session);
    app.uiPrefsLoader = () => _uiPrefs!.fetch();
    app.uiPrefsSaver = (prefs) => _uiPrefs!.save(prefs);

    if (auth.status != AuthStatus.authenticated) {
      _themeBootstrapped = false;
      _notifsBootstrapped = false;
      return;
    }

    if (!_themeBootstrapped) {
      _themeBootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AppState>().bindAuth(auth);
        final prefs = auth.session?.uiPrefs;
        if (prefs != null) {
          app.applyUiPrefs(prefs);
        } else if (!auth.isDemo) {
          app.loadUiPrefsFromServer();
        }
      });
    }

    if (_notifsBootstrapped) return;
    if (auth.isDemo) return;
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
      case 'system_settings':
        return const SystemSettingsView();
      case 'approvals':
        return const ApprovalsInboxView();
      case 'employees':
        return const EmployeesView();
      case 'employee_roles':
        return const EmployeeRolesView();
      case 'employees_dashboard':
        return const EmployeesDashboardView();
      case 'employee_directory':
        return const EmployeeDirectoryView();
      case 'performance':
        return const PerformanceView();
      case 'recruitment':
        return const RecruitmentView();
      case 'training':
        return const TrainingView();
      case 'training_calendar':
        return const TrainingView(initialTab: 1);
      case 'training_trainers':
        return const TrainingView(initialTab: 2);
      case 'training_types':
        return const TrainingView(initialTab: 3);
      case 'termination':
        return const TerminationView();
      case 'loan_applications':
        return const LoanApplicationView();
      case 'letters':
        return const LettersView();
      case 'notifications':
        return const NotificationsView();
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
      case 'hr_reports':
        return const HrReportsView();
      case 'attendance':
        return const AttendanceView();
      case 'admin_attendance':
        return const AdminAttendanceView();
      case 'schedule':
        return const ScheduleView();
      case 'attendance_register':
        return const AttendanceRegisterView();
      case 'devices':
        return const DevicesView();
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
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          ...previousChildren,
                          if (currentChild != null)
                            Positioned.fill(child: currentChild),
                        ],
                      );
                    },
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
