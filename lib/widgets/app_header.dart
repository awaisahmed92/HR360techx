import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../theme/app_theme.dart';
import 'action_dialogs.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final String? shellLabel;

  const AppHeader({super.key, this.onMenuPressed, this.shellLabel});

  String _getTabTitle(int index, {bool employeeShell = false}) {
    if (employeeShell) {
      switch (index) {
        case 0:
          return 'My Overview';
        case 1:
          return 'Leave & Attendance';
        case 2:
          return '360° Performance';
        default:
          return 'Overview';
      }
    }
    switch (index) {
      case 0:
        return 'Executive Overview';
      case 1:
        return 'Workforce Directory';
      case 2:
        return '360° Performance & Feedback';
      case 3:
        return 'Leave & Attendance Tracking';
      case 4:
        return 'Talent Pipeline & Kanban';
      case 5:
        return 'Payroll & Workforce Analytics';
      default:
        return 'Overview';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 900;

    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final todayFormatted = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile && onMenuPressed != null)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: textPrimary),
              onPressed: onMenuPressed,
            ),

          // Title & Date
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTabTitle(
                    appState.currentTab,
                    employeeShell: shellLabel == 'Employee',
                  ),
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      todayFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    if (shellLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shellLabel!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Clock-In/Out Status Pill
          if (!isMobile) ...[
            InkWell(
              onTap: () => appState.toggleClock(),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: appState.isClockedIn
                      ? AppTheme.success.withOpacity(0.12)
                      : AppTheme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: appState.isClockedIn
                        ? AppTheme.success.withOpacity(0.4)
                        : AppTheme.warning.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: appState.isClockedIn ? AppTheme.success : AppTheme.warning,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (appState.isClockedIn ? AppTheme.success : AppTheme.warning)
                                .withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appState.isClockedIn ? 'Clocked In (Active)' : 'Clocked Out',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: appState.isClockedIn ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Quick Action Add Button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'employee') {
                ActionDialogs.showAddEmployeeDialog(context);
              } else if (value == 'leave') {
                ActionDialogs.showApplyLeaveDialog(context);
              } else if (value == 'review') {
                ActionDialogs.showAddReviewDialog(context);
              } else if (value == 'candidate') {
                ActionDialogs.showAddCandidateDialog(context);
              }
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderColor),
            ),
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'employee',
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded, size: 18, color: AppTheme.primaryLight),
                    SizedBox(width: 10),
                    Text('Onboard New Employee'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.beach_access_rounded, size: 18, color: AppTheme.success),
                    SizedBox(width: 10),
                    Text('Apply for Leave'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'review',
                child: Row(
                  children: [
                    Icon(Icons.star_rate_rounded, size: 18, color: AppTheme.warning),
                    SizedBox(width: 10),
                    Text('Submit 360 Feedback'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'candidate',
                child: Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 18, color: AppTheme.cyan),
                    SizedBox(width: 10),
                    Text('Add Pipeline Candidate'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Quick Action',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Notification Bell
          PopupMenuButton<void>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            itemBuilder: (context) {
              return [
                PopupMenuItem<void>(
                  enabled: false,
                  child: SizedBox(
                    width: 320,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                appState.markAllNotificationsRead();
                                Navigator.pop(context);
                              },
                              child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const Divider(),
                        ...appState.notifications.map((n) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (n['color'] as Color).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n['title'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: textPrimary,
                                        ),
                                      ),
                                      Text(
                                        n['desc'] as String,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        n['time'] as String,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textSecondary.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ];
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCardHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 20, color: textPrimary),
                  if (appState.unreadNotificationsCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Dark/Light Theme Toggle
          InkWell(
            onTap: () => appState.toggleTheme(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCardHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 19,
                color: isDark ? const Color(0xFFFBBF24) : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Account / Logout
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderColor),
            ),
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            onSelected: (value) async {
              if (value == 'logout') {
                await context.read<AuthState>().logout();
              }
            },
            itemBuilder: (context) {
              final auth = context.read<AuthState>();
              final name = auth.user?.name ?? 'Signed in';
              final org = auth.company?.subdomain ?? '';
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      if (org.isNotEmpty)
                        Text(
                          auth.isDemo ? 'Demo session' : '@$org',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppTheme.danger),
                      SizedBox(width: 10),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCardHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Icons.person_outline_rounded, size: 20, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
