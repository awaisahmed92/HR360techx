import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/stat_charts.dart';
import '../widgets/action_dialogs.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final currency = NumberFormat.compactSimpleCurrency();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: HrTheme.brand(context).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: HrTheme.gradient(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to HR360 TechX Talent Cloud 🚀',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All team metrics, 360° reviews, attendance, and recruitment pipelines are operating at peak health.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HrTheme.brand(context),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 18),
                    label: const Text('New 360 Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    onPressed: () => ActionDialogs.showAddReviewDialog(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Top Metric Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 4;
              if (width < 600) {
                crossAxisCount = 1;
              } else if (width < 1000) {
                crossAxisCount = 2;
              }

              final itemWidth = (width - ((crossAxisCount - 1) * 16)) / crossAxisCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      title: 'Total Workforce',
                      value: '${appState.totalWorkforceCount}',
                      subtitle: '${appState.activeWorkforceCount} Active • ${appState.remoteCount} Remote',
                      icon: Icons.groups_rounded,
                      gradient: HrTheme.gradient(context),
                      trend: '+14.2%',
                      isPositiveTrend: true,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      title: 'Attendance Rate',
                      value: '98.4%',
                      subtitle: '${appState.onLeaveCount} on approved leave',
                      icon: Icons.event_available_rounded,
                      gradient: AppTheme.successGradient,
                      trend: '+2.1%',
                      isPositiveTrend: true,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      title: 'Active Pipeline',
                      value: '${appState.openRequisitionsCount}',
                      subtitle: 'Candidates across 5 stages',
                      icon: Icons.view_kanban_rounded,
                      gradient: AppTheme.accentGradient,
                      trend: '+4 New',
                      isPositiveTrend: true,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: MetricCard(
                      title: 'Monthly Payroll',
                      value: currency.format(appState.monthlyPayrollSum),
                      subtitle: 'Disbursed on 1st of month',
                      icon: Icons.account_balance_wallet_rounded,
                      gradient: AppTheme.warningGradient,
                      trend: '100% on-time',
                      isPositiveTrend: true,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Analytics Section
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Department Headcount Distribution
                Expanded(
                  flex: 5,
                  child: _buildCard(
                context: context,
                isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    title: 'Department Workforce Allocation',
                    subtitle: 'Headcount distribution across company units',
                    icon: Icons.pie_chart_rounded,
                    action: TextButton(
                      onPressed: () => appState.setTab(1),
                      child: const Text('View All Employees →'),
                    ),
                    child: DepartmentBarChart(isDark: isDark),
                  ),
                ),
                const SizedBox(width: 24),
                // Right: 360 Performance Radar Spotlight
                Expanded(
                  flex: 4,
                  child: _buildCard(
                context: context,
                isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    title: '360° Competency Radar',
                    subtitle: 'Alex Rivera (Staff Architect) Review Synthesis',
                    icon: Icons.radar_rounded,
                    action: TextButton(
                      onPressed: () => appState.setTab(2),
                      child: const Text('Full 360 Hub →'),
                    ),
                    child: SizedBox(
                      height: 240,
                      child: RadarChartWidget(
                        isDark: isDark,
                        polygonColor: HrTheme.brandLight(context),
                        data: appState.allEmployeesRaw[1].competencies,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _buildCard(
                context: context,
                isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              title: 'Department Workforce Allocation',
              subtitle: 'Headcount distribution across company units',
              icon: Icons.pie_chart_rounded,
              child: DepartmentBarChart(isDark: isDark),
            ),
            const SizedBox(height: 24),
            _buildCard(
                context: context,
                isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              title: '360° Competency Radar',
              subtitle: 'Alex Rivera (Staff Architect) Review Synthesis',
              icon: Icons.radar_rounded,
              child: SizedBox(
                height: 240,
                child: RadarChartWidget(
                  isDark: isDark,
                  polygonColor: HrTheme.brandLight(context),
                  data: appState.allEmployeesRaw[1].competencies,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Bottom Row: Attendance Trend & Activity Stream
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attendance Weekly Curve
                Expanded(
                  flex: 5,
                  child: _buildCard(
                context: context,
                isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    title: 'Workforce Attendance Trends',
                    subtitle: '7-Day Check-in & Punch compliance',
                    icon: Icons.trending_up_rounded,
                    child: AttendanceTrendChart(isDark: isDark),
                  ),
                ),
                const SizedBox(width: 24),
                // Recent Pending Approvals & Logs
                Expanded(
                  flex: 4,
                  child: _buildCard(
                context: context,
                isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    title: 'Pending Leave Approvals',
                    subtitle: 'Requires HR / Manager sign-off',
                    icon: Icons.pending_actions_rounded,
                    action: TextButton(
                      onPressed: () => appState.setTab(3),
                      child: const Text('Manage Leaves →'),
                    ),
                    child: Column(
                      children: appState.leaveRequests.take(2).map((req) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(req.employeeAvatar),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.employeeName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${req.type} (${req.days} days)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (req.status == 'Pending') ...[
                                IconButton(
                                  icon: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
                                  onPressed: () => appState.updateLeaveStatus(req.id, 'Approved'),
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 22),
                                  onPressed: () => appState.updateLeaveStatus(req.id, 'Rejected'),
                                  tooltip: 'Reject',
                                ),
                              ] else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (req.status == 'Approved' ? AppTheme.success : AppTheme.danger).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: req.status == 'Approved' ? AppTheme.success : AppTheme.danger,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _buildCard(
                context: context,
                isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              title: 'Workforce Attendance Trends',
              subtitle: '7-Day Check-in & Punch compliance',
              icon: Icons.trending_up_rounded,
              child: AttendanceTrendChart(isDark: isDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? action,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: HrTheme.brandLight(context), size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
