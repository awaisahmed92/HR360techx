import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/permissions/permission_gate.dart';
import '../core/permissions/tab_access.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, this.employeeShell = false});

  /// When true, only self-service tabs (Dashboard / Leave / Performance).
  final bool employeeShell;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final auth = context.watch<AuthState>();
    final isDark = appState.isDarkMode;
    final isCollapsed = appState.isSidebarCollapsed;

    final bgColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final userName =
        auth.user?.name.isNotEmpty == true ? auth.user!.name : 'User';
    final roleLabel = auth.user?.designationName.isNotEmpty == true
        ? auth.user!.designationName
        : (auth.company?.name ?? 'HR360');
    final companyLabel = auth.company?.name ?? 'Talent Cloud OS';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor.withOpacity(0.6), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '360',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'HR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const Text(
                                '360',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            companyLabel,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (!isCollapsed)
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    onPressed: () => appState.toggleSidebar(),
                    tooltip: 'Collapse Sidebar',
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              children: [
                if (!isCollapsed)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
                    child: Text(
                      'MAIN PLATFORM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textSecondary.withOpacity(0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                PermissionGate(
                  module: employeeShell ? 'Dashboard' : TabAccess.moduleFor(0),
                  child: _SidebarItem(
                    index: 0,
                    icon: Icons.grid_view_rounded,
                    label: 'Dashboard',
                    isCollapsed: isCollapsed,
                  ),
                ),
                if (employeeShell) ...[
                  PermissionGate(
                    module: 'Leave',
                    child: _SidebarItem(
                      index: 1,
                      icon: Icons.event_available_rounded,
                      label: 'Leave & Attendance',
                      isCollapsed: isCollapsed,
                    ),
                  ),
                  PermissionGate(
                    module: 'Performance',
                    child: _SidebarItem(
                      index: 2,
                      icon: Icons.radar_rounded,
                      label: '360° Performance',
                      isCollapsed: isCollapsed,
                    ),
                  ),
                ] else ...[
                PermissionGate(
                  module: TabAccess.moduleFor(1),
                  child: _SidebarItem(
                    index: 1,
                    icon: Icons.groups_rounded,
                    label: 'Workforce Hub',
                    isCollapsed: isCollapsed,
                    badge: '${appState.totalWorkforceCount}',
                  ),
                ),
                PermissionGate(
                  module: TabAccess.moduleFor(2),
                  child: _SidebarItem(
                    index: 2,
                    icon: Icons.radar_rounded,
                    label: '360° Performance',
                    isCollapsed: isCollapsed,
                  ),
                ),
                PermissionGate(
                  module: TabAccess.moduleFor(3),
                  child: _SidebarItem(
                    index: 3,
                    icon: Icons.event_available_rounded,
                    label: 'Leave & Attendance',
                    isCollapsed: isCollapsed,
                    badge:
                        '${appState.leaveRequests.where((r) => r.status == "Pending").length}',
                    badgeColor: AppTheme.warning,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'RECRUIT & FINANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textSecondary.withOpacity(0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
                PermissionGate(
                  module: TabAccess.moduleFor(4),
                  child: _SidebarItem(
                    index: 4,
                    icon: Icons.view_kanban_rounded,
                    label: 'Talent Pipeline',
                    isCollapsed: isCollapsed,
                    badge: '${appState.openRequisitionsCount}',
                    badgeColor: AppTheme.accent,
                  ),
                ),
                PermissionGate(
                  module: TabAccess.moduleFor(5),
                  child: _SidebarItem(
                    index: 5,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Payroll & Analytics',
                    isCollapsed: isCollapsed,
                  ),
                ),
                ],
              ],
            ),
          ),
          if (isCollapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: () => appState.toggleSidebar(),
                tooltip: 'Expand Sidebar',
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 10 : 16,
              vertical: 14,
            ),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCardHover,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: isCollapsed
                ? Center(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              roleLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (auth.isDemo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.warning,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
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

class _SidebarItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isCollapsed;
  final String? badge;
  final Color? badgeColor;

  const _SidebarItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isCollapsed,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isSelected = appState.currentTab == index;
    final isDark = appState.isDarkMode;

    const activeColor = AppTheme.primary;
    final inactiveText =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: isCollapsed ? label : '',
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: () => appState.setTab(index),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppTheme.primary.withOpacity(0.18)
                      : AppTheme.primary.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : inactiveText,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : AppTheme.primary)
                            : inactiveText,
                      ),
                    ),
                  ),
                  if (badge != null && badge != '0')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? AppTheme.primary).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (badgeColor ?? AppTheme.primary).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor ?? AppTheme.primaryLight,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
