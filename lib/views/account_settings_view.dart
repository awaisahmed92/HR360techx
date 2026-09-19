import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/hr_theme.dart';
import '../core/util/json_maps.dart';
import '../widgets/hr_controls.dart';
import '../widgets/hr_form_kit.dart';
import 'themes_view.dart' show ThemesPanel;

/// Account Settings hub: Themes · Approvals · Notifications (WebHR-style).
class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  static const _nav = [
    'Themes',
    'Approvals',
    'Notifications',
    'Security',
    'Personal Information',
  ];

  String _navItem = 'Approvals';
  String _module = 'travel';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadWorkflowSettings(_module);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final app = context.watch<AppState>();

    return HrSettingsShell(
      title: 'Account Settings',
      navItems: _nav,
      selectedNav: _navItem,
      onNav: (item) {
        if (item == 'Personal Information') {
          app.setTab(app.profileTabIndex);
          return;
        }
        setState(() => _navItem = item);
        if (item == 'Approvals' || item == 'Notifications') {
          ss.loadWorkflowSettings(_module);
        }
      },
      onSave: (_navItem == 'Themes' || _navItem == 'Security')
          ? null
          : () async {
              final err = _navItem == 'Approvals'
                  ? await ss.saveApprovalSettings(_module)
                  : await ss.saveNotificationSettings(_module);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err ?? 'Settings saved'),
                  backgroundColor:
                      err == null ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              );
            },
      child: switch (_navItem) {
        'Themes' => ThemesPanel(
            brandId: app.brandThemeId,
            onPick: app.setBrandTheme,
          ),
        'Approvals' => _ApprovalsPanel(
            module: _module,
            onModule: (m) {
              setState(() => _module = m);
              ss.loadWorkflowSettings(m);
            },
          ),
        'Notifications' => _NotificationsPanel(
            module: _module,
            onModule: (m) {
              setState(() => _module = m);
              ss.loadWorkflowSettings(m);
            },
          ),
        'Security' => const _SecurityPanel(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _ModulePicker extends StatelessWidget {
  const _ModulePicker({required this.module, required this.onModule});
  final String module;
  final ValueChanged<String> onModule;

  @override
  Widget build(BuildContext context) {
    return HrFormRow(
      label: 'Module',
      child: HrDropdown<String>(
        value: module,
        hint: 'Select module',
        items: const [
          DropdownMenuItem(value: 'travel', child: Text('Travel')),
          DropdownMenuItem(value: 'leave', child: Text('Leave')),
          DropdownMenuItem(value: 'timesheet', child: Text('Timesheet')),
        ],
        onChanged: (v) {
          if (v != null) onModule(v);
        },
      ),
    );
  }
}

class _SecurityPanel extends StatefulWidget {
  const _SecurityPanel();

  @override
  State<_SecurityPanel> createState() => _SecurityPanelState();
}

class _SecurityPanelState extends State<_SecurityPanel> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Change Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: HrUi.label(context),
          ),
        ),
        const SizedBox(height: 16),
        HrFormRow(
          label: 'Current password',
          child: TextField(
            controller: _current,
            obscureText: true,
            decoration: hrFieldDecoration(context, hint: 'Current'),
          ),
        ),
        HrFormRow(
          label: 'New password',
          child: TextField(
            controller: _next,
            obscureText: true,
            decoration: hrFieldDecoration(context, hint: 'Min 6 characters'),
          ),
        ),
        HrFormRow(
          label: 'Confirm',
          child: TextField(
            controller: _confirm,
            obscureText: true,
            decoration: hrFieldDecoration(context, hint: 'Repeat new password'),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Saving…' : 'Update Password'),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_next.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters.')),
      );
      return;
    }
    if (_next.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password and confirm do not match.')),
      );
      return;
    }
    setState(() => _busy = true);
    final err = await context.read<AuthState>().changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Password updated.'),
        backgroundColor: err == null ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
    if (err == null) {
      _current.clear();
      _next.clear();
      _confirm.clear();
    }
  }
}

class _ApprovalsPanel extends StatelessWidget {
  const _ApprovalsPanel({required this.module, required this.onModule});
  final String module;
  final ValueChanged<String> onModule;

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final settings = ss.approvalSettings;
    final employees = ss.workflowEmployees;
    final levels = (settings['approval_levels'] as num?)?.toInt() ?? 1;
    final assignees = asStringKeyedMap(settings['level_assignees']);

    int? assigneeFor(int level) {
      final raw = assignees['$level'] ?? assignees[level];
      if (raw is Map) return (raw['employee_id'] as num?)?.toInt();
      if (raw is num) return raw.toInt();
      return null;
    }

    return Column(
      children: [
        _ModulePicker(module: module, onModule: onModule),
        HrFormRow(
          label: 'Approval Method',
          child: HrDropdown<String>(
            value: (settings['approval_method'] as String?) ?? 'multi_level',
            items: const [
              DropdownMenuItem(value: 'multi_level', child: Text('Multi-level Approval')),
              DropdownMenuItem(value: 'single', child: Text('Single Approval')),
            ],
            onChanged: (v) {
              if (v == null) return;
              ss.patchApprovalLocal({'approval_method': v});
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
              DropdownMenuItem(value: 4, child: Text('Four Levels')),
              DropdownMenuItem(value: 5, child: Text('Five Levels')),
            ],
            onChanged: (v) {
              if (v == null) return;
              ss.patchApprovalLocal({'approval_levels': v});
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
                  final next = Map<String, dynamic>.from(assignees);
                  next['$lvl'] = {
                    'level': lvl,
                    'employee_id': v,
                    'employee_name': '',
                  };
                  ss.patchApprovalLocal({'level_assignees': next});
                },
              ),
            ),
        HrToggleRow(
          label: 'Restart Approval on Edit',
          value: settings['restart_on_edit'] == true,
          onChanged: (v) => ss.patchApprovalLocal({'restart_on_edit': v}),
        ),
        HrToggleRow(
          label: 'Skip Specific Approvals',
          value: settings['skip_specific'] == true,
          onChanged: (v) => ss.patchApprovalLocal({'skip_specific': v}),
        ),
        HrToggleRow(
          label: 'Hide Rejected Records',
          value: settings['hide_rejected'] == true,
          onChanged: (v) => ss.patchApprovalLocal({'hide_rejected': v}),
        ),
        if (ss.workflowError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(ss.workflowError!, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel({required this.module, required this.onModule});
  final String module;
  final ValueChanged<String> onModule;

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final settings = ss.notificationSettings;
    final employees = ss.workflowEmployees;

    List<int> ids(String key) =>
        ((settings[key] as List?) ?? []).map((e) => (e as num).toInt()).toList();

    List<Map<String, dynamic>> selectedMaps(String key) {
      final set = ids(key).toSet();
      return employees.where((e) => set.contains((e['id'] as num).toInt())).toList();
    }

    return Column(
      children: [
        _ModulePicker(module: module, onModule: onModule),
        HrToggleRow(
          label: 'Do not send Notification to Employee',
          value: settings['do_not_notify_employee'] == true,
          onChanged: (v) => ss.patchNotificationLocal({'do_not_notify_employee': v}),
        ),
        HrFormRow(
          label: 'Notify upon Submission',
          child: Row(
            children: [
              Expanded(
                child: HrMultiSelect<Map<String, dynamic>>(
                  hint: 'Select Employees',
                  items: employees,
                  values: selectedMaps('notify_on_submission'),
                  labelOf: (e) => (e['name'] ?? '').toString(),
                  onChanged: (list) {
                    ss.patchNotificationLocal({
                      'notify_on_submission':
                          list.map((e) => (e['id'] as num).toInt()).toList(),
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text('SMS', style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
              Switch.adaptive(
                value: settings['sms_on_submission'] == true,
                activeColor: HrTheme.brand(context),
                onChanged: (v) =>
                    ss.patchNotificationLocal({'sms_on_submission': v}),
              ),
            ],
          ),
        ),
        HrFormRow(
          label: 'Notify upon Approval',
          child: HrMultiSelect<Map<String, dynamic>>(
            hint: 'Select Employees',
            items: employees,
            values: selectedMaps('notify_on_approval'),
            labelOf: (e) => (e['name'] ?? '').toString(),
            onChanged: (list) {
              ss.patchNotificationLocal({
                'notify_on_approval':
                    list.map((e) => (e['id'] as num).toInt()).toList(),
              });
            },
          ),
        ),
        HrFormRow(
          label: 'Notify Upon Approval Reassignment',
          child: HrMultiSelect<Map<String, dynamic>>(
            hint: 'Select Employees',
            items: employees,
            values: selectedMaps('notify_on_reassignment'),
            labelOf: (e) => (e['name'] ?? '').toString(),
            onChanged: (list) {
              ss.patchNotificationLocal({
                'notify_on_reassignment':
                    list.map((e) => (e['id'] as num).toInt()).toList(),
              });
            },
          ),
        ),
      ],
    );
  }
}
