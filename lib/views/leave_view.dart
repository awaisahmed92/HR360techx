import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/leave/leave_repository.dart';
import '../core/leave/leave_state.dart';
import '../theme/app_theme.dart';
import '../widgets/action_dialogs.dart';

class LeaveView extends StatefulWidget {
  const LeaveView({super.key});

  @override
  State<LeaveView> createState() => _LeaveViewState();
}

class _LeaveViewState extends State<LeaveView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final leaveState = context.watch<LeaveState>();
    final isDark = appState.isDarkMode;
    final useApi = !auth.isDemo;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return RefreshIndicator(
      onRefresh: () => leaveState.load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useApi && leaveState.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
                ),
                child: Text(
                  leaveState.error!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                ),
              ),
            _buildBalances(
              useApi: useApi,
              leaveState: leaveState,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      useApi
                          ? 'Leave requests (live)'
                          : 'Leave & Time-Off Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      useApi
                          ? 'Loaded from tenant API · pull to refresh'
                          : 'Demo mock data — toggle off Demo mode for live leave',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'Request Time Off',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    if (useApi) {
                      _showApplyDialog(context, leaveState);
                    } else {
                      ActionDialogs.showApplyLeaveDialog(context);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (useApi && leaveState.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (useApi)
              _buildApiList(
                leaveState: leaveState,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              )
            else
              _buildMockList(
                appState: appState,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalances({
    required bool useApi,
    required LeaveState leaveState,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    final colors = [
      AppTheme.primary,
      AppTheme.danger,
      AppTheme.warning,
      AppTheme.cyan,
    ];
    final icons = [
      Icons.flight_takeoff_rounded,
      Icons.medical_services_rounded,
      Icons.beach_access_rounded,
      Icons.home_work_rounded,
    ];

    if (!useApi) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cross = constraints.maxWidth < 600
              ? 1
              : (constraints.maxWidth < 1000 ? 2 : 4);
          final itemWidth =
              (constraints.maxWidth - ((cross - 1) * 16)) / cross;
          final mocks = [
            ('Annual Vacation', '18 Days', '6 Used of 24 Total', 0),
            ('Sick & Medical', '10 Days', '2 Used of 12 Total', 1),
            ('Casual & Personal', '5 Days', '1 Used of 6 Total', 2),
            ('Remote Work Days', 'Flexible', 'Policy: Hybrid 3/2 Model', 3),
          ];
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: mocks
                .map(
                  (m) => SizedBox(
                    width: itemWidth,
                    child: _balanceCard(
                      title: m.$1,
                      available: m.$2,
                      used: m.$3,
                      color: colors[m.$4],
                      icon: icons[m.$4],
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    final balances = leaveState.balances;
    if (balances.isEmpty) {
      return Text(
        'No leave balance types found for this employee.',
        style: TextStyle(
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.maxWidth < 600
            ? 1
            : (constraints.maxWidth < 1000 ? 2 : 4);
        final itemWidth = (constraints.maxWidth - ((cross - 1) * 16)) / cross;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < balances.length; i++)
              SizedBox(
                width: itemWidth,
                child: _balanceCard(
                  title: balances[i].name,
                  available: '${balances[i].available} Days',
                  used:
                      '${balances[i].usedLeaves} Used of ${balances[i].totalDays} Total',
                  color: colors[i % colors.length],
                  icon: icons[i % icons.length],
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildApiList({
    required LeaveState leaveState,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (leaveState.leaves.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          'No leave requests yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: leaveState.leaves.map((req) {
          final isApproved = req.statusLabel == 'Approved';
          final isPending = req.statusLabel == 'Pending';
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
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    req.employeeName.isNotEmpty
                        ? req.employeeName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              req.employeeName.isNotEmpty
                                  ? req.employeeName
                                  : 'Employee #${req.employeeId}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                          ),
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
                              req.leaveType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${req.from} → ${req.to} (${req.days} days)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      if (req.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '"${req.reason}"',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : AppTheme.lightTextMuted,
                          ),
                        ),
                      ],
                      if (req.approvalStepLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          req.approvalStepLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (req.canApprove) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                    onPressed: () async {
                      final err = await leaveState.approve(req.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Leave approved'),
                          backgroundColor:
                              err == null ? AppTheme.success : AppTheme.danger,
                        ),
                      );
                    },
                    child: const Text('Approve',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                    onPressed: () async {
                      final err = await leaveState.reject(req.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err ?? 'Leave rejected'),
                          backgroundColor:
                              err == null ? AppTheme.danger : AppTheme.warning,
                        ),
                      );
                    },
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                ] else if (!isPending) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isApproved ? AppTheme.success : AppTheme.danger)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.statusLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isApproved ? AppTheme.success : AppTheme.danger,
                      ),
                    ),
                  ),
                ] else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMockList({
    required AppState appState,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: appState.leaveRequests.map((req) {
          final isApproved = req.status == 'Approved';
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
                  backgroundImage: NetworkImage(req.employeeAvatar),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.employeeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Duration: ${req.startDate} → ${req.endDate} (${req.days} days)',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (req.status == 'Pending') ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                    onPressed: () =>
                        appState.updateLeaveStatus(req.id, 'Approved'),
                    child: const Text('Approve',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ] else
                  Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isApproved ? AppTheme.success : AppTheme.danger,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String available,
    required String used,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            available,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            used,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApplyDialog(BuildContext context, LeaveState leaveState) async {
    if (leaveState.types.isEmpty) {
      await leaveState.load();
    }
    if (!context.mounted) return;

    LeaveTypeDto? selected =
        leaveState.types.isNotEmpty ? leaveState.types.first : null;
    final reasonCtrl = TextEditingController();
    DateTime? from;
    DateTime? to;
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final days = (from != null && to != null)
                ? to!.difference(from!).inDays + 1
                : 1;
            return AlertDialog(
              title: const Text('Apply for leave'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<LeaveTypeDto>(
                      value: selected,
                      items: leaveState.types
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => selected = v),
                      decoration: const InputDecoration(labelText: 'Leave type'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        from == null
                            ? 'From date'
                            : DateFormat('yyyy-MM-dd').format(from!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setLocal(() => from = d);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        to == null
                            ? 'To date'
                            : DateFormat('yyyy-MM-dd').format(to!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: from ?? DateTime.now(),
                          firstDate: from ?? DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setLocal(() => to = d);
                      },
                    ),
                    Text('Days: $days', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting || selected == null || from == null || to == null
                      ? null
                      : () async {
                          setLocal(() => submitting = true);
                          final err = await leaveState.applyLeave(
                            leaveTypeId: selected!.id,
                            from: DateFormat('yyyy-MM-dd').format(from!),
                            to: DateFormat('yyyy-MM-dd').format(to!),
                            days: days < 1 ? 1 : days,
                            reason: reasonCtrl.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          if (err != null) {
                            setLocal(() => submitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Leave submitted'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    reasonCtrl.dispose();
  }
}
