import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/self_service/self_service_state.dart';
import '../core/util/person_name.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import 'action_dialogs.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final String? shellLabel;

  const AppHeader({super.key, this.onMenuPressed, this.shellLabel});

  String _getTabTitle(int index, {bool employeeShell = false}) {
    if (employeeShell) {
      const titles = [
        'My Overview',
        'Attendance',
        'Leave',
        'Travel',
        'Timesheet',
        'Approvals',
        'My Profile',
        'Performance',
        'Settings',
      ];
      return titles[index.clamp(0, titles.length - 1)];
    }
    const titles = [
      'Executive Overview',
      'Workforce Directory',
      '360° Performance',
      'Leave',
      'Talent Pipeline',
      'Payroll',
      'Attendance',
      'Travel',
      'Timesheet',
      'Approvals',
      'My Profile',
      'Settings',
    ];
    return titles[index.clamp(0, titles.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final brand = appState.brandColor;
    final onBrand =
        brand.computeLuminance() > 0.55 ? const Color(0xFF1F2937) : Colors.white;

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
                          color: brand.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shellLabel!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: brand,
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
              // Defer past PopupMenu disposal to avoid mouse_tracker assertions.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                final app = context.read<AppState>();
                if (value == 'employee') {
                  app.requestOpenEmployeeForm();
                } else if (value == 'leave') {
                  ActionDialogs.showApplyLeaveDialog(context);
                } else if (value == 'review') {
                  ActionDialogs.showAddReviewDialog(context);
                } else if (value == 'candidate') {
                  ActionDialogs.showAddCandidateDialog(context);
                }
              });
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderColor),
            ),
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'employee',
                child: Row(
                  children: [
                    Icon(Icons.person_add_rounded, size: 18, color: HrTheme.brandLight(context)),
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
                gradient: AppTheme.brandGradient(brand),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: brand.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 18, color: onBrand),
                  const SizedBox(width: 6),
                  Text(
                    'Quick Action',
                    style: TextStyle(
                      color: onBrand,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Themes shortcut
          InkWell(
            onTap: () => appState.setTab(appState.themesTabIndex),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCardHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.palette_outlined, size: 20, color: brand),
            ),
          ),
          const SizedBox(width: 8),

          // Notification Bell (API-backed approvals cascade)
          Builder(
            builder: (context) {
              final ss = context.watch<SelfServiceState>();
              final live = ss.inboxNotifications;
              final unread = ss.unreadNotifications;
              final useLive = !context.watch<AuthState>().isDemo;
              final items = useLive
                  ? live
                  : appState.notifications
                      .map((n) => {
                            'title': n['title'],
                            'body': n['desc'],
                            'created_at': n['time'],
                            'is_read': n['read'] == true,
                          })
                      .toList();
              final unreadShow = useLive ? unread : appState.unreadNotificationsCount;

              return PopupMenuButton<void>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                onOpened: () {
                  if (useLive) ss.loadNotifications();
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<void>(
                      enabled: false,
                      child: SizedBox(
                        width: 340,
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
                                    if (useLive) {
                                      ss.markNotificationsRead();
                                    } else {
                                      appState.markAllNotificationsRead();
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Mark all read',
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const Divider(),
                            if (items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text('No notifications',
                                    style: TextStyle(color: textSecondary)),
                              )
                            else
                              ...items.take(8).map((n) {
                                final title = (n['title'] ?? '').toString();
                                final body =
                                    (n['body'] ?? n['desc'] ?? '').toString();
                                final time =
                                    (n['created_at'] ?? n['time'] ?? '').toString();
                                final unreadItem = n['is_read'] != true && n['read'] != true;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: HrTheme.brandSoft(context),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.notifications_active_outlined,
                                            color: HrTheme.brand(context), size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontWeight: unreadItem
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                fontSize: 13,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Text(
                                              body,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              time,
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
                      Icon(Icons.notifications_none_rounded,
                          size: 20, color: textPrimary),
                      if (unreadShow > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              unreadShow > 9 ? '9+' : '$unreadShow',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
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
                color: isDark ? const Color(0xFFFBBF24) : brand,
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
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!context.mounted) return;
                if (value == 'logout') {
                  await context.read<AuthState>().logout();
                } else if (value == 'profile') {
                  context.read<AppState>().openScreen(moduleId: 'dashboard', subId: 'my_info');
                } else if (value == 'settings') {
                  context.read<AppState>().openScreen(moduleId: 'dashboard', subId: 'account_settings');
                }
              });
            },
            itemBuilder: (context) {
              final auth = context.read<AuthState>();
                  final name = cleanDisplayName(auth.user?.name);
              final role = auth.user?.designationName ?? '';
              final org = auth.company?.subdomain ?? '';
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Signed in' : name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      if (role.isNotEmpty)
                        Text(role, style: TextStyle(fontSize: 12, color: textSecondary)),
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
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 10),
                      Text('My Info'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Account Settings'),
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
