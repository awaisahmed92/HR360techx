import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/action_dialogs.dart';

class PayrollView extends StatelessWidget {
  const PayrollView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    final totalMonthlyGross = appState.monthlyPayrollSum;
    final totalTaxes = totalMonthlyGross * 0.22;
    final totalBenefits = appState.totalWorkforceCount * 420.0;
    final totalNet = totalMonthlyGross - totalTaxes - totalBenefits;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Payroll Stat Cards
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
                    child: _buildSummaryCard(
                      title: 'Monthly Gross Payroll',
                      value: currency.format(totalMonthlyGross),
                      subtitle: 'Across ${appState.totalWorkforceCount} team members',
                      color: HrTheme.brand(context),
                      icon: Icons.account_balance_rounded,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSummaryCard(
                      title: 'Net Disbursed Funds',
                      value: currency.format(totalNet),
                      subtitle: 'Direct deposited to bank accounts',
                      color: AppTheme.success,
                      icon: Icons.payments_rounded,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSummaryCard(
                      title: 'Tax & Withholdings (22%)',
                      value: currency.format(totalTaxes),
                      subtitle: 'Federal & state compliance',
                      color: AppTheme.warning,
                      icon: Icons.receipt_long_rounded,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSummaryCard(
                      title: 'Medical & Benefits Pool',
                      value: currency.format(totalBenefits),
                      subtitle: 'Health, Dental & 401(k) matching',
                      color: AppTheme.cyan,
                      icon: Icons.shield_rounded,
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Disbursement Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee Payroll Breakdown (September 2026)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Itemized salaries, deductions, and downloadable official tax statements',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: HrTheme.brand(context),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_for_offline_rounded, size: 18, color: Colors.white),
                label: const Text('Export Payroll CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exported HR360_Payroll_Sept_2026.csv successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payroll Table List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: appState.allEmployeesRaw.map((emp) {
                final gross = emp.salary / 12;
                final tax = gross * 0.22;
                final insurance = 420.0;
                final net = gross - tax - insurance;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightCardHover,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(emp.avatar),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              '${emp.role} • ${emp.department}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gross Salary',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            Text(
                              currency.format(gross),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Net Disbursed',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            Text(
                              currency.format(net),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HrTheme.brand(context),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.receipt_rounded, size: 16, color: Colors.white),
                        label: const Text('Payslip', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () => ActionDialogs.showPayslipDialog(context, emp),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
