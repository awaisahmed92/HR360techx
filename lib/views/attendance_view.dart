import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/app_theme.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ss = context.watch<SelfServiceState>();
    final isDark = app.isDarkMode;
    final today = ss.attendanceToday;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final card = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final canIn = today?['can_punch_in'] == true;
    final canOut = today?['can_punch_out'] == true;
    final record = today?['record'] as Map?;

    return RefreshIndicator(
      onRefresh: () => ss.loadAttendance(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Attendance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary)),
          Text('Punch in / out for today', style: TextStyle(color: textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today: ${today?['date'] ?? '—'}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 8),
                Text('In: ${record?['punch_in'] ?? '—'}', style: TextStyle(color: textSecondary)),
                Text('Out: ${record?['punch_out'] ?? '—'}', style: TextStyle(color: textSecondary)),
                if (record?['total_minutes'] != null)
                  Text('Total: ${record!['total_minutes']} min',
                      style: TextStyle(color: textSecondary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      onPressed: !canIn
                          ? null
                          : () async {
                              final err = await ss.punch('in');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(err ?? 'Punched in'),
                                backgroundColor: err == null ? AppTheme.success : AppTheme.danger,
                              ));
                            },
                      child: const Text('Punch In', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                      onPressed: !canOut
                          ? null
                          : () async {
                              final err = await ss.punch('out');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(err ?? 'Punched out'),
                                backgroundColor: err == null ? AppTheme.success : AppTheme.danger,
                              ));
                            },
                      child: const Text('Punch Out', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('This month',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
          const SizedBox(height: 12),
          if (ss.attendanceMonth.isEmpty)
            Text('No records yet.', style: TextStyle(color: textSecondary))
          else
            ...ss.attendanceMonth.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    '${r['date']}  ·  in ${r['punch_in'] ?? '—'}  ·  out ${r['punch_out'] ?? '—'}',
                    style: TextStyle(color: textPrimary, fontSize: 13),
                  ),
                )),
        ],
      ),
    );
  }
}
