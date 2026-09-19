import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/action_dialogs.dart';

class PerformanceView extends StatefulWidget {
  const PerformanceView({super.key});

  @override
  State<PerformanceView> createState() => _PerformanceViewState();
}

class _PerformanceViewState extends State<PerformanceView> {
  int _selectedEmployeeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isDesktop = MediaQuery.of(context).size.width >= 1050;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final selectedEmp = appState.allEmployeesRaw[_selectedEmployeeIndex.clamp(0, appState.allEmployeesRaw.length - 1)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HrTheme.brand(context).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.warningGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '360° Continuous Feedback & Growth Hub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Holistic multi-rater appraisals: Peer, Manager, Self, and Cross-functional feedback cycles.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HrTheme.brand(context),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.star_rate_rounded, color: Colors.white, size: 18),
                  label: const Text('Log 360 Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  onPressed: () => ActionDialogs.showAddReviewDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Interactive Employee 360 Radar Deep Dive
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Individual 360° Competency Radar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    // Dropdown to switch employee
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedEmployeeIndex,
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          items: List.generate(
                            appState.allEmployeesRaw.length,
                            (index) => DropdownMenuItem(
                              value: index,
                              child: Text(
                                '${appState.allEmployeesRaw[index].name} (${appState.allEmployeesRaw[index].role})',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedEmployeeIndex = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Radar Chart
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 280,
                          child: RadarChartWidget(
                            isDark: isDark,
                            polygonColor: HrTheme.brandLight(context),
                            data: selectedEmp.competencies,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Breakdown bars
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(selectedEmp.avatar),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedEmp.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Overall Rating: ${selectedEmp.rating} / 5.0 ★',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            ...selectedEmp.competencies.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '${(entry.value * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 6,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: entry.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: HrTheme.gradient(context),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  SizedBox(
                    height: 260,
                    child: RadarChartWidget(
                      isDark: isDark,
                      polygonColor: HrTheme.brandLight(context),
                      data: selectedEmp.competencies,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Company OKRs & Goal Milestones
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Q3/Q4 Strategic OKRs & Key Milestones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildOKRItem('Single Page Application Performance', 'Target: Sub-second load & 60fps render time', 0.94, AppTheme.success, isDark),
                _buildOKRItem('Talent Retention & Satisfaction Index', 'Target: >92% eNPS across global engineering hub', 0.88, HrTheme.brand(context), isDark),
                _buildOKRItem('360 Appraisal Cycle Completion', 'Target: 100% peer & manager reviews finalized', 0.76, AppTheme.warning, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feed of 360 Reviews
          Text(
            'Recent 360 Feedback Syntheses (${appState.reviews.length} Logged)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Column(
            children: appState.reviews.map((rev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(rev.reviewerAvatar),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${rev.reviewerName} (${rev.reviewerRole}) → ${rev.employeeName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${rev.reviewType} • ${rev.date}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppTheme.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${rev.score} / 5.0',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '"${rev.feedback}"',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOKRItem(String title, String subtitle, double progress, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 7,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
