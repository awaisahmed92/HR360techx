import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/leave/leave_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';

class ApprovalsInboxView extends StatefulWidget {
  const ApprovalsInboxView({super.key});

  @override
  State<ApprovalsInboxView> createState() => _ApprovalsInboxViewState();
}

class _ApprovalsInboxViewState extends State<ApprovalsInboxView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadApprovals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ss = context.watch<SelfServiceState>();
    final leave = context.read<LeaveState>();
    final isDark = app.isDarkMode;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final card = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return RefreshIndicator(
      onRefresh: () => ss.loadApprovals(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Approvals inbox',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary)),
          Text('${ss.approvals.length} pending item(s)',
              style: TextStyle(color: textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (ss.approvals.isEmpty)
            Text('Nothing waiting for you.', style: TextStyle(color: textSecondary))
          else
            ...ss.approvals.map((item) {
              final kind = (item['kind'] ?? '').toString();
              final id = item['id'] as int? ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: HrTheme.brand(context).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(kind.toUpperCase(),
                          style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HrTheme.brandLight(context))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item['title']} · ${item['employee_name']}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: textPrimary)),
                          Text((item['summary'] ?? '').toString(),
                              style: TextStyle(color: textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        String? err;
                        if (kind == 'leave') {
                          err = await leave.approve(id);
                        } else if (kind == 'travel') {
                          err = await ss.travelAct('approve', id);
                        } else if (kind == 'timesheet') {
                          err = await ss.timesheetAct('approve', id);
                        }
                        await ss.loadApprovals();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(err ?? 'Approved'),
                          backgroundColor: err == null ? AppTheme.success : AppTheme.danger,
                        ));
                      },
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
