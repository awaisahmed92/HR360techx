import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/app_state.dart';
import 'core/auth/auth_state.dart';
import 'core/leave/leave_state.dart';
import 'core/permissions/permission_gate.dart';
import 'core/permissions/tab_access.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/app_header.dart';
import 'views/dashboard_view.dart';
import 'views/employees_view.dart';
import 'views/performance_view.dart';
import 'views/leave_view.dart';
import 'views/recruitment_view.dart';
import 'views/payroll_view.dart';

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
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

  bool _isAdminShell(AuthState auth) {
    if (auth.permissions.all || auth.user?.isAdmin == true) return true;
    return auth.canViewModule('AdminSetup') ||
        auth.canViewModule('Payroll') ||
        auth.canViewModule('HiringProcess') ||
        auth.canView('Dashboard', 'AdminDashboard');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final isDark = appState.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final adminShell = _isAdminShell(auth);

    final views = adminShell
        ? const [
            DashboardView(),
            EmployeesView(),
            PerformanceView(),
            LeaveView(),
            RecruitmentView(),
            PayrollView(),
          ]
        : const [
            DashboardView(),
            LeaveView(),
            PerformanceView(),
          ];

    final employeeModules = ['Dashboard', 'Leave', 'Performance'];
    final tab = appState.currentTab.clamp(0, views.length - 1);
    final module = adminShell
        ? TabAccess.moduleFor(tab)
        : employeeModules[tab.clamp(0, employeeModules.length - 1)];
    final allowed = auth.permissions.all || auth.canViewModule(module);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      drawer: isMobile
          ? Drawer(
              child: AppSidebar(employeeShell: !adminShell),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) AppSidebar(employeeShell: !adminShell),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  onMenuPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  shellLabel: adminShell ? 'Admin' : 'Employee',
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>('$tab-$allowed-$adminShell'),
                      child: allowed
                          ? views[tab]
                          : AccessDeniedView(
                              message:
                                  'No access to "$module". Your designation rolls do not include this module.',
                            ),
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
