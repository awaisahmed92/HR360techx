import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/leave/leave_repository.dart';
import '../core/leave/leave_state.dart';
import '../widgets/hr_form_kit.dart';
import '../theme/hr_theme.dart';
import 'leave_module_settings_view.dart';

class LeaveView extends StatefulWidget {
  const LeaveView({super.key});

  @override
  State<LeaveView> createState() => _LeaveViewState();
}

class _LeaveViewState extends State<LeaveView> {
  bool _showForm = false;
  bool _showSettings = false;
  bool _showTypes = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveState>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveState>();

    if (_showTypes) {
      return LeaveTypesManageView(
        onBack: () => setState(() {
          _showTypes = false;
          _showSettings = true;
        }),
      );
    }
    if (_showSettings) {
      return LeaveModuleSettingsView(
        onBack: () => setState(() => _showSettings = false),
        onManageTypes: () => setState(() {
          _showSettings = false;
          _showTypes = true;
        }),
      );
    }
    if (_showForm) {
      return LeaveAddForm(
        onBack: () => setState(() => _showForm = false),
        onSaved: () async {
          setState(() => _showForm = false);
          await leave.load();
        },
      );
    }

    final rows = leave.leaves.where((l) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return '${l.employeeName}${l.leaveType}${l.reason}'.toLowerCase().contains(q);
    }).toList();

    return Stack(
      children: [
        HrDataGridPage(
          title: 'Leaves',
          icon: Icons.event_available_rounded,
          onAdd: () => setState(() => _showForm = true),
          onRefresh: () => leave.load(),
          onSearch: (v) => setState(() => _query = v),
          emptyMessage: leave.loading ? 'Loading…' : 'No leave records.',
          columns: const [
            'S#',
            'Employee',
            'Leave Type',
            'From',
            'To',
            'Days',
            'Approval Status',
            '',
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              [
                Text('${i + 1}'),
                Text(rows[i].employeeName.isEmpty
                    ? 'Employee #${rows[i].employeeId}'
                    : rows[i].employeeName),
                Text(rows[i].leaveType),
                Text(rows[i].from),
                Text(rows[i].to),
                Text('${rows[i].days}'),
                HrStatusPill(
                  label: rows[i].statusLabel,
                  pending: rows[i].status == 0,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, size: 18),
                  onSelected: (v) async {
                    if (!rows[i].canApprove) return;
                    final remarksCtrl = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(v == 'approve' ? 'Approve Leave' : 'Reject Leave'),
                        content: TextField(
                          controller: remarksCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Remarks (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(v == 'approve' ? 'Approve' : 'Reject'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    final err = v == 'approve'
                        ? await leave.approve(rows[i].id, remarks: remarksCtrl.text.trim())
                        : await leave.reject(rows[i].id, remarks: remarksCtrl.text.trim());
                    remarksCtrl.dispose();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(err ??
                              (v == 'approve' ? 'Approved' : 'Rejected'))),
                    );
                  },
                  itemBuilder: (_) => [
                    if (rows[i].canApprove) ...[
                      const PopupMenuItem(value: 'approve', child: Text('Approve')),
                      const PopupMenuItem(value: 'reject', child: Text('Reject')),
                    ],
                  ],
                ),
              ],
          ],
        ),
        Positioned(
          top: 16,
          right: 20,
          child: IconButton(
            tooltip: 'Leave Settings',
            onPressed: () => setState(() => _showSettings = true),
            icon: Icon(Icons.settings_outlined, color: HrTheme.brand(context)),
          ),
        ),
      ],
    );
  }
}

class LeaveAddForm extends StatefulWidget {
  const LeaveAddForm({super.key, required this.onBack, required this.onSaved});
  final VoidCallback onBack;
  final Future<void> Function() onSaved;

  @override
  State<LeaveAddForm> createState() => _LeaveAddFormState();
}

class _LeaveAddFormState extends State<LeaveAddForm> {
  LeaveTypeDto? _type;
  DateTime? _from;
  DateTime? _to;
  final _reason = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveState>();
    _type ??= leave.types.isNotEmpty ? leave.types.first : null;
    final days = (_from != null && _to != null)
        ? _to!.difference(_from!).inDays + 1
        : 1;

    return HrFormShell(
      moduleTitle: 'Leaves',
      moduleIcon: Icons.event_available_rounded,
      formTitle: 'Add New Leave',
      onBack: widget.onBack,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: _saving ? null : widget.onBack, child: const Text('Cancel')),
          const SizedBox(width: 10),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _saving ? null : () => _submit(leave, days),
            child: const Text('Save Leave'),
          ),
        ],
      ),
      child: Column(
        children: [
          HrFormSection(
            title: 'Leave Information',
            children: [
              HrFormRow(
                label: 'Leave Type',
                required: true,
                child: HrDropdown<LeaveTypeDto>(
                  value: _type,
                  hint: 'Select leave type',
                  items: leave.types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v),
                ),
              ),
              HrFormRow(
                label: 'Reason',
                required: true,
                child: TextField(
                  controller: _reason,
                  maxLines: 2,
                  style: hrFieldTextStyle(context),
                  decoration: hrFieldDecoration(context, hint: 'Reason'),
                ),
              ),
            ],
          ),
          HrFormSection(
            title: 'Leave Duration',
            children: [
              HrFormRow(
                label: 'From Date',
                required: true,
                child: _date(_from, (d) => setState(() => _from = d)),
              ),
              HrFormRow(
                label: 'To Date',
                required: true,
                child: _date(_to, (d) => setState(() => _to = d)),
              ),
              HrFormRow(
                label: 'Days',
                showInfo: false,
                child: Text('$days', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _date(DateTime? v, ValueChanged<DateTime> onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: v ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: hrFieldDecoration(context, suffix: const Icon(Icons.calendar_today_outlined, size: 18)),
        child: Text(
          v == null ? 'Select date' : DateFormat('yyyy-MM-dd').format(v),
          style: hrFieldTextStyle(context),
        ),
      ),
    );
  }

  Future<void> _submit(LeaveState leave, int days) async {
    if (_type == null || _from == null || _to == null || _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }
    setState(() => _saving = true);
    final err = await leave.applyLeave(
      leaveTypeId: _type!.id,
      from: DateFormat('yyyy-MM-dd').format(_from!),
      to: DateFormat('yyyy-MM-dd').format(_to!),
      days: days < 1 ? 1 : days,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await widget.onSaved();
  }
}
