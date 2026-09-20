import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/leave/leave_repository.dart';
import '../core/leave/leave_state.dart';
import '../core/network/api_client.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_controls.dart';
import '../widgets/hr_form_kit.dart';

/// Leave module settings (gear): Options · Approvals · Notifications · Manage Types
class LeaveModuleSettingsView extends StatefulWidget {
  const LeaveModuleSettingsView({
    super.key,
    required this.onBack,
    required this.onManageTypes,
  });

  final VoidCallback onBack;
  final VoidCallback onManageTypes;

  @override
  State<LeaveModuleSettingsView> createState() =>
      _LeaveModuleSettingsViewState();
}

class _LeaveModuleSettingsViewState extends State<LeaveModuleSettingsView> {
  String _nav = 'Leaves Options';

  static const _items = [
    'Leaves Options',
    'Leave Thresholds',
    'Approvals',
    'Notifications',
    'Data Grid',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveState>().loadModuleOptions();
      context.read<SelfServiceState>().loadWorkflowSettings('leave');
    });
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveState>();
    final ss = context.watch<SelfServiceState>();

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: HrTheme.heading(context)),
                const SizedBox(width: 8),
                Text('Leaves',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: HrTheme.heading(context),
                    )),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back'),
                ),
              ],
            ),
          ),
          Expanded(
            child: HrSettingsShell(
              title: 'Leaves Settings',
              navItems: _items,
              selectedNav: _nav,
              onNav: (v) => setState(() => _nav = v),
              onSave: () async {
                String? err;
                if (_nav == 'Leaves Options') {
                  err = await leave.saveModuleOptions();
                } else if (_nav == 'Approvals') {
                  err = await ss.saveApprovalSettings('leave');
                } else if (_nav == 'Notifications') {
                  err = await ss.saveNotificationSettings('leave');
                } else if (_nav == 'Leave Thresholds') {
                  // Thresholds save per-row
                  err = null;
                }
                if (!mounted) return;
                if (_nav == 'Leave Thresholds') return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Settings saved'),
                    backgroundColor:
                        err == null ? const Color(0xFF10B981) : Colors.redAccent,
                  ),
                );
              },
              child: switch (_nav) {
                'Leaves Options' => _LeaveOptionsPanel(onManageTypes: widget.onManageTypes),
                'Leave Thresholds' => const _LeaveThresholdsPanel(),
                'Approvals' => const _LeaveApprovalsPanel(),
                'Notifications' => const _LeaveNotificationsPanel(),
                _ => Text(
                    'Data Grid column preferences coming soon.',
                    style: TextStyle(color: HrUi.muted(context)),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveOptionsPanel extends StatelessWidget {
  const _LeaveOptionsPanel({required this.onManageTypes});
  final VoidCallback onManageTypes;

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveState>();
    final o = leave.moduleOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HrFormRow(
          label: 'Leaves Types',
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onManageTypes,
              icon: Icon(Icons.settings, size: 16, color: HrTheme.brand(context)),
              label: Text(
                'Manage Leaves Types',
                style: TextStyle(
                  color: HrTheme.brand(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Leaves Quota Settings',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: HrUi.label(context),
            )),
        const SizedBox(height: 10),
        for (final e in const [
          ('allow_edit_quota', 'Allow Editing of Taken/Pending in Leaves Quota'),
          ('carry_forward', 'Carry Forward Leaves on Leaves Quota Reset Date'),
          ('pro_rata', 'Pro-Rata Based Leaves Quota Assignment'),
          ('show_prorated', 'Show Prorated Leaves in Leaves Quota/Summary'),
          ('disable_quota_deletion', 'Disable Leave Quota Deletion'),
          ('create_future_quota', 'Create Leave Quota for Future Leave'),
        ])
          HrToggleRow(
            label: e.$2,
            value: o[e.$1] == true,
            onChanged: (v) => leave.patchModuleOption(e.$1, v),
          ),
      ],
    );
  }
}

class _LeaveThresholdsPanel extends StatefulWidget {
  const _LeaveThresholdsPanel();

  @override
  State<_LeaveThresholdsPanel> createState() => _LeaveThresholdsPanelState();
}

class _LeaveThresholdsPanelState extends State<_LeaveThresholdsPanel> {
  int? _designationId;
  final Set<int> _typeIds = {};
  final _from = TextEditingController(text: '1');
  final _to = TextEditingController(text: '5');
  int? _editId;
  List<Map<String, dynamic>> _designations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final leave = context.read<LeaveState>();
      await leave.loadThresholds();
      await leave.loadManagedTypes();
      await _loadDesignations();
    });
  }

  Future<void> _loadDesignations() async {
    try {
      final client = ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);
      final res = await client.dio.get('/employees/meta');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        final opts = data['options'];
        if (opts is Map && opts['designations'] is List) {
          setState(() {
            _designations = (opts['designations'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leave Thresholds',
            style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context), fontSize: 16)),
        Text('Max days by designation & leave type (blocks apply when exceeded).',
            style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _designationId,
          decoration: const InputDecoration(labelText: 'Designation', isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('—')),
            ..._designations.map((d) {
              final id = (d['id'] as num?)?.toInt();
              return DropdownMenuItem(value: id, child: Text('${d['name']}'));
            }),
          ],
          onChanged: (v) => setState(() => _designationId = v),
        ),
        const SizedBox(height: 8),
        Text('Leave Types', style: TextStyle(fontWeight: FontWeight.w600, color: HrUi.label(context))),
        Wrap(
          spacing: 8,
          children: leave.managedTypes.map((t) {
            final sel = _typeIds.contains(t.id);
            return FilterChip(
              label: Text(t.name),
              selected: sel,
              onSelected: (v) => setState(() {
                if (v) {
                  _typeIds.add(t.id);
                } else {
                  _typeIds.remove(t.id);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _from,
                decoration: const InputDecoration(labelText: 'Threshold From', isDense: true),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _to,
                decoration: const InputDecoration(labelText: 'Threshold To (max days)', isDense: true),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            if (_designationId == null || _typeIds.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select designation and at least one leave type.')),
              );
              return;
            }
            final err = await leave.saveThreshold({
              'designation_id': _designationId,
              'leave_type_ids': _typeIds.toList(),
              'threshold_from': int.tryParse(_from.text) ?? 0,
              'threshold_to': int.tryParse(_to.text) ?? 0,
              'status': 1,
            }, id: _editId);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
            if (err == null) {
              setState(() {
                _editId = null;
                _typeIds.clear();
              });
            }
          },
          child: Text(_editId == null ? 'Add Threshold' : 'Update Threshold'),
        ),
        const SizedBox(height: 20),
        if (leave.thresholds.isEmpty)
          Text('No thresholds yet.', style: TextStyle(color: HrUi.muted(context)))
        else
          ...leave.thresholds.map((r) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${r['designation_name']} · ${r['leave_type_label']}'),
              subtitle: Text('From ${r['threshold_from']} → To ${r['threshold_to']} days'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () {
                      setState(() {
                        _editId = (r['id'] as num?)?.toInt();
                        _designationId = (r['designation_id'] as num?)?.toInt();
                        _from.text = '${r['threshold_from']}';
                        _to.text = '${r['threshold_to']}';
                        _typeIds
                          ..clear()
                          ..addAll(((r['leave_type_ids'] as List?) ?? []).map((e) => (e as num).toInt()));
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      final id = (r['id'] as num?)?.toInt();
                      if (id == null) return;
                      final err = await leave.deleteThreshold(id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Deleted')));
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _LeaveApprovalsPanel extends StatelessWidget {
  const _LeaveApprovalsPanel();

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final settings = ss.approvalSettings;
    final employees = ss.workflowEmployees;
    final levels = (settings['approval_levels'] as num?)?.toInt() ?? 1;
    final assignees = settings['level_assignees'];
    final map = assignees is Map
        ? Map<String, dynamic>.from(assignees)
        : <String, dynamic>{};

    int? assigneeFor(int level) {
      final raw = map['$level'];
      if (raw is Map) return (raw['employee_id'] as num?)?.toInt();
      if (raw is num) return raw.toInt();
      return null;
    }

    return Column(
      children: [
        Text(
          'These settings apply only to the Leave module.',
          style: TextStyle(color: HrUi.muted(context), fontSize: 13),
        ),
        const SizedBox(height: 12),
        HrFormRow(
          label: 'Approval Method',
          child: HrDropdown<String>(
            value: (settings['approval_method'] as String?) ?? 'multi_level',
            items: const [
              DropdownMenuItem(value: 'multi_level', child: Text('Multi-level Approval')),
            ],
            onChanged: (v) {
              if (v != null) ss.patchApprovalLocal({'approval_method': v});
            },
          ),
        ),
        HrFormRow(
          label: 'Approval Levels',
          child: HrDropdown<int>(
            value: levels,
            items: const [
              DropdownMenuItem(value: 0, child: Text('Auto Approved')),
              DropdownMenuItem(value: 1, child: Text('One Level')),
              DropdownMenuItem(value: 2, child: Text('Two Levels')),
              DropdownMenuItem(value: 3, child: Text('Three Levels')),
            ],
            onChanged: (v) {
              if (v != null) ss.patchApprovalLocal({'approval_levels': v});
            },
          ),
        ),
        if (levels >= 1)
          for (var lvl = 1; lvl <= levels && lvl <= 3; lvl++)
            HrFormRow(
              label: 'Level $lvl Approver',
              required: true,
              child: HrDropdown<int>(
                value: assigneeFor(lvl),
                hint: 'Select employee',
                items: employees
                    .map((e) => DropdownMenuItem(
                          value: (e['id'] as num).toInt(),
                          child: Text((e['name'] ?? '').toString()),
                        ))
                    .toList(),
                onChanged: (v) {
                  final next = Map<String, dynamic>.from(map);
                  next['$lvl'] = {'level': lvl, 'employee_id': v};
                  ss.patchApprovalLocal({'level_assignees': next});
                },
              ),
            ),
      ],
    );
  }
}

class _LeaveNotificationsPanel extends StatelessWidget {
  const _LeaveNotificationsPanel();

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final settings = ss.notificationSettings;
    final employees = ss.workflowEmployees;

    List<int> ids(String key) =>
        ((settings[key] as List?) ?? []).map((e) => (e as num).toInt()).toList();

    List<Map<String, dynamic>> selected(String key) {
      final set = ids(key).toSet();
      return employees.where((e) => set.contains((e['id'] as num).toInt())).toList();
    }

    return Column(
      children: [
        HrToggleRow(
          label: 'Do not send Notification to Employee',
          value: settings['do_not_notify_employee'] == true,
          onChanged: (v) => ss.patchNotificationLocal({'do_not_notify_employee': v}),
        ),
        HrFormRow(
          label: 'Notify upon Submission',
          child: HrMultiSelect<Map<String, dynamic>>(
            hint: 'Select Employees',
            items: employees,
            values: selected('notify_on_submission'),
            labelOf: (e) => (e['name'] ?? '').toString(),
            onChanged: (list) => ss.patchNotificationLocal({
              'notify_on_submission': list.map((e) => (e['id'] as num).toInt()).toList(),
            }),
          ),
        ),
        HrFormRow(
          label: 'Notify upon Approval',
          child: HrMultiSelect<Map<String, dynamic>>(
            hint: 'Select Employees',
            items: employees,
            values: selected('notify_on_approval'),
            labelOf: (e) => (e['name'] ?? '').toString(),
            onChanged: (list) => ss.patchNotificationLocal({
              'notify_on_approval': list.map((e) => (e['id'] as num).toInt()).toList(),
            }),
          ),
        ),
      ],
    );
  }
}

/// Manage Leave Types grid + Add form
class LeaveTypesManageView extends StatefulWidget {
  const LeaveTypesManageView({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<LeaveTypesManageView> createState() => _LeaveTypesManageViewState();
}

class _LeaveTypesManageViewState extends State<LeaveTypesManageView> {
  bool _showForm = false;
  LeaveTypeDto? _editing;
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveState>().loadManagedTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leave = context.watch<LeaveState>();
    if (_showForm) {
      return _AddLeaveTypeForm(
        existing: _editing,
        onBack: () => setState(() {
          _showForm = false;
          _editing = null;
        }),
        onSaved: () async {
          setState(() {
            _showForm = false;
            _editing = null;
          });
          await leave.loadManagedTypes();
        },
      );
    }

    final rows = leave.managedTypes.where((t) {
      if (_q.isEmpty) return true;
      return '${t.name}${t.category}'.toLowerCase().contains(_q.toLowerCase());
    }).toList();

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: HrTheme.heading(context)),
              const SizedBox(width: 8),
              Text('Leaves',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: HrTheme.heading(context),
                  )),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Manage Leaves Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HrUi.label(context),
              )),
          const SizedBox(height: 12),
          HrDataGridPage(
            title: 'Leave Types',
            icon: Icons.category_outlined,
            onAdd: () => setState(() {
              _editing = null;
              _showForm = true;
            }),
            onRefresh: () => leave.loadManagedTypes(),
            onSearch: (v) => setState(() => _q = v),
            searchHint: 'Search',
            emptyMessage: 'No leave types. Click + Add Record.',
            columns: const [
              'Title',
              'Leave Type',
              'Leaves Allowed Per Year',
              'Duration Type',
              'Company',
              'Station',
              '',
            ],
            rows: [
              for (final t in rows)
                [
                  Text(t.name),
                  Text(t.category),
                  Text(t.days.toStringAsFixed(3)),
                  Text(t.durationType),
                  const Text('All Companies'),
                  const Text('All Stations'),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.menu, size: 18),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        setState(() {
                          _editing = t;
                          _showForm = true;
                        });
                      } else if (v == 'delete') {
                        final err = await leave.deleteLeaveType(t.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err ?? 'Deleted')),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AddLeaveTypeForm extends StatefulWidget {
  const _AddLeaveTypeForm({
    required this.onBack,
    required this.onSaved,
    this.existing,
  });

  final VoidCallback onBack;
  final Future<void> Function() onSaved;
  final LeaveTypeDto? existing;

  @override
  State<_AddLeaveTypeForm> createState() => _AddLeaveTypeFormState();
}

class _AddLeaveTypeFormState extends State<_AddLeaveTypeForm> {
  final _title = TextEditingController();
  final _calendar = TextEditingController();
  final _ref = TextEditingController();
  final _days = TextEditingController(text: '1');
  String _category = 'Unpaid Leave';
  String _duration = 'Days';
  bool _quotaReset = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.name;
      _calendar.text = e.calendarTitle;
      _ref.text = e.referenceNumber;
      _days.text = '${e.days}';
      _category = e.category;
      _duration = e.durationType;
      _quotaReset = e.quotaReset;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _calendar.dispose();
    _ref.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HrFormShell(
      moduleTitle: 'Leaves',
      moduleIcon: Icons.mail_outline,
      formTitle: widget.existing == null ? 'Add Leave Type' : 'Edit Leave Type',
      onBack: widget.onBack,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: widget.onBack, child: const Text('Cancel')),
          const SizedBox(width: 10),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      child: Column(
        children: [
          HrFormSection(
            title: 'Leave Type Information',
            children: [
              HrFormRow(
                label: 'Title',
                required: true,
                child: HrTextField(controller: _title, hint: 'Title'),
              ),
              HrFormRow(
                label: 'Title in Calendar',
                child: HrTextField(controller: _calendar, hint: 'Name in Calendar'),
              ),
              HrFormRow(
                label: 'Reference Number',
                child: HrTextField(controller: _ref, hint: 'Reference Number'),
              ),
              HrFormRow(
                label: 'Leave Type',
                child: HrDropdown<String>(
                  value: _category,
                  items: const [
                    DropdownMenuItem(value: 'Paid Leave', child: Text('Paid Leave')),
                    DropdownMenuItem(value: 'Unpaid Leave', child: Text('Unpaid Leave')),
                    DropdownMenuItem(
                        value: 'Half Day Paid Leave', child: Text('Half Day Paid Leave')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
              ),
              HrFormRow(
                label: 'Leaves Allowed Per Year',
                child: HrTextField(
                  controller: _days,
                  hint: '1',
                  keyboardType: TextInputType.number,
                ),
              ),
              HrFormRow(
                label: 'Leave Duration Type',
                child: HrDropdown<String>(
                  value: _duration,
                  items: const [
                    DropdownMenuItem(value: 'Days', child: Text('Days')),
                    DropdownMenuItem(value: 'Hours', child: Text('Hours')),
                  ],
                  onChanged: (v) => setState(() => _duration = v ?? _duration),
                ),
              ),
            ],
          ),
          HrFormSection(
            title: 'Leave Quota Assignment',
            children: [
              HrToggleRow(
                label: 'Leaves Quota Reset',
                value: _quotaReset,
                onChanged: (v) => setState(() => _quotaReset = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }
    setState(() => _saving = true);
    final err = await context.read<LeaveState>().saveLeaveType({
      'name': _title.text.trim(),
      'calendar_title': _calendar.text.trim(),
      'reference_number': _ref.text.trim(),
      'category': _category,
      'days': double.tryParse(_days.text) ?? 1,
      'duration_type': _duration,
      'quota_reset': _quotaReset,
      'is_active': true,
    }, id: widget.existing?.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await widget.onSaved();
  }
}
