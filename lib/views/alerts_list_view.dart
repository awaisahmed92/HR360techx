import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/leave/leave_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Full list opened from My Alerts → See more.
class AlertsListView extends StatefulWidget {
  const AlertsListView({super.key, required this.mode});

  final String mode;

  @override
  State<AlertsListView> createState() => _AlertsListViewState();
}

class _AlertsListViewState extends State<AlertsListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ss = context.read<SelfServiceState>();
      ss.loadApprovals();
      ss.loadNotifications();
    });
  }

  String _when(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('d MMM yyyy, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final approvals = widget.mode == 'approvals';
    final rows = approvals ? ss.approvals : ss.inboxNotifications;
    final title = approvals ? 'All approvals' : 'All actions';

    return Scaffold(
      backgroundColor: HrUi.pageBg(context),
      appBar: AppBar(
        backgroundColor: HrTheme.brand(context),
        foregroundColor: HrTheme.onBrand(context),
        title: Text(title),
      ),
      body: rows.isEmpty
          ? Center(child: Text('Nothing to do today.', style: TextStyle(color: HrUi.muted(context), fontSize: 16)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final row = rows[i];
                return approvals ? _approvalCard(context, ss, row) : _actionCard(context, row);
              },
            ),
    );
  }

  Widget _actionCard(BuildContext context, Map<String, dynamic> row) {
    final title = (row['title'] ?? '').toString();
    final body = (row['body'] ?? '').toString();
    return _card(
      context,
      title: title.isNotEmpty ? title : 'Action',
      subtitle: body,
      when: _when((row['created_at'] ?? '').toString()),
    );
  }

  Widget _approvalCard(BuildContext context, SelfServiceState ss, Map<String, dynamic> row) {
    final kind = (row['kind'] ?? '').toString();
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final who = (row['employee_name'] ?? '').toString();
    final label = (row['module'] ?? kind).toString();
    final summary = (row['summary'] ?? row['title'] ?? '').toString();
    return _card(
      context,
      title: 'Acknowledgement required for $label${who.isEmpty ? '' : ' — $who'}',
      subtitle: summary,
      when: _when((row['created_at'] ?? '').toString()),
      trailing: kind == 'leave' || kind == 'travel' || kind == 'timesheet'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _act(context, ss, kind, id, approve: true),
                  child: const Text('Approve'),
                ),
                TextButton(
                  onPressed: () => _act(context, ss, kind, id, approve: false),
                  child: Text('Reject', style: TextStyle(color: AppTheme.danger)),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _act(BuildContext context, SelfServiceState ss, String kind, int id, {required bool approve}) async {
    final leave = context.read<LeaveState>();
    String? err;
    if (kind == 'leave') {
      err = approve ? await leave.approve(id) : await leave.reject(id);
    } else if (kind == 'travel') {
      err = await ss.travelAct(approve ? 'approve' : 'reject', id);
    } else if (kind == 'timesheet') {
      err = await ss.timesheetAct(approve ? 'approve' : 'reject', id);
    }
    await ss.loadApprovals();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? (approve ? 'Approved' : 'Rejected')),
      backgroundColor: err == null ? AppTheme.success : AppTheme.danger,
    ));
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String when,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HrTheme.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_tree_outlined, size: 20, color: HrUi.label(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: HrUi.muted(context), fontSize: 13)),
                ],
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(when, style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
