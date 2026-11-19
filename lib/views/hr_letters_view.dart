import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/letters/letter_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import 'hr_letter_designer_page.dart';

Future<void> openHrLetterPrint(
  BuildContext context,
  int id, {
  bool download = false,
}) async {
  final token = context.read<AuthState>().session?.token ?? '';
  final uri = Uri.parse(
    '${AppConfig.apiBaseUrl}/hr-letters/instances/$id/print'
    '?access_token=${Uri.encodeQueryComponent(token)}'
    '${download ? '&download=1' : ''}',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Open manually: $uri')),
  );
}

/// Top-level HR Letters module: Dashboard · Designer · Categories · Send ·
/// Employee · Candidate · Reports.
class HrLettersView extends StatefulWidget {
  const HrLettersView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HrLettersView> createState() => _HrLettersViewState();
}

class _HrLettersViewState extends State<HrLettersView> {
  late final LetterState _state;

  static const _tabs = [
    'Dashboard',
    'Designer',
    'Categories',
    'Send Letter',
    'Employee Letters',
    'Candidate Letters',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _state = LetterState(context.read<AuthState>())
      ..tab = widget.initialTab.clamp(0, _tabs.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'HR Letters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _state.load(),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                    if (_state.tab == 2)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                        onPressed: () => _editCategory(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add category'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_tabs[i]),
                          selected: _state.tab == i,
                          onSelected: (_) => _state.setTab(i),
                        ),
                      ),
                  ],
                ),
              ),
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Expanded(
                child: _state.busy && _isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : switch (_state.tab) {
                        0 => _dashboard(),
                        1 => _designer(),
                        2 => _categories(),
                        3 => _send(),
                        4 => _instances(employee: true),
                        5 => _instances(employee: false),
                        _ => _reports(),
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _isEmpty => switch (_state.tab) {
        1 => _state.types.isEmpty,
        2 => _state.categories.isEmpty,
        4 || 5 => _state.instances.isEmpty,
        6 => _state.reportRows.isEmpty,
        _ => false,
      };

  Widget _dashboard() {
    final s = _state.stats;
    final cards = <(String, String, IconData)>[
      ('Templates', '${s['templates'] ?? 0}', Icons.description_outlined),
      ('Categories', '${s['categories'] ?? 0}', Icons.category_outlined),
      ('Pending approval', '${s['pending_approvals'] ?? 0}', Icons.pending_actions_outlined),
      ('Awaiting ack', '${s['awaiting_ack'] ?? 0}', Icons.mark_email_read_outlined),
      ('Issued this month', '${s['issued_this_month'] ?? 0}', Icons.outgoing_mail),
      ('Employee letters', '${s['employee_letters'] ?? 0}', Icons.badge_outlined),
      ('Candidate letters', '${s['candidate_letters'] ?? 0}', Icons.person_search_outlined),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in cards)
              SizedBox(
                width: 210,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(c.$3, color: HrTheme.brand(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                              Text(c.$1, style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
            onPressed: () => _state.setTab(3),
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send a letter'),
          ),
        ),
      ],
    );
  }

  Widget _designer() {
    return LetterDesignerScreen(state: _state);
  }

  Widget _categories() {
    if (_state.categories.isEmpty) {
      return Center(child: Text('No categories yet.', style: TextStyle(color: HrUi.muted(context))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _state.categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = _state.categories[i];
        return Card(
          child: ListTile(
            title: Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${c['template_count'] ?? 0} templates'),
            trailing: Wrap(
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editCategory(existing: c)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final err = await _state.deleteCategory((c['id'] as num).toInt());
                    if (!context.mounted) return;
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _send() {
    return _SendLetterPanel(state: _state);
  }

  Widget _instances({required bool employee}) {
    if (_state.instances.isEmpty) {
      return Center(
        child: Text(
          employee ? 'No employee letters issued yet.' : 'No candidate letters issued yet.',
          style: TextStyle(color: HrUi.muted(context)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _state.instances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final row = _state.instances[i];
        final recipient = employee
            ? '${row['employee_name'] ?? ''} ${row['employee_code'] != null && '${row['employee_code']}'.isNotEmpty ? '(${row['employee_code']})' : ''}'
            : '${row['candidate_name'] ?? ''}';
        return Card(
          child: ListTile(
            title: Text('${row['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '$recipient · ${row['reference_number'] ?? ''} · ${row['status_label'] ?? ''}'
              '${'${row['acknowledged_at'] ?? ''}'.isNotEmpty ? ' · Ack' : ''}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openInstance(row),
          ),
        );
      },
    );
  }

  Widget _reports() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                onPressed: () async {
                  _state.tab = 6;
                  await _state.loadTab();
                },
                child: const Text('Employee letters'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _state.loadCustomVariablesReport(),
                child: const Text('Custom variables'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _state.reportRows.isEmpty
              ? Center(child: Text('No report rows.', style: TextStyle(color: HrUi.muted(context))))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _state.reportRows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = _state.reportRows[i];
                    return ListTile(
                      title: Text('${r['name'] ?? r['type_name'] ?? 'Letter'}'),
                      subtitle: Text(
                        '${r['employee_name'] ?? r['recipient'] ?? r['candidate_name'] ?? ''} · '
                        '${r['reference_number'] ?? ''} · ${r['status_label'] ?? ''} · ${r['created_at'] ?? ''}',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _editCategory({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add category' : 'Edit category'),
        content: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await _state.saveCategory(
      {'name': name.text.trim(), 'status': 1},
      id: existing == null ? null : (existing['id'] as num).toInt(),
    );
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }


  Future<void> _openInstance(Map<String, dynamic> row) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _InstanceDialog(state: _state, row: row),
    );
    if (mounted) await _state.loadTab(silent: true);
  }
}

class _SendLetterPanel extends StatefulWidget {
  const _SendLetterPanel({required this.state});
  final LetterState state;

  @override
  State<_SendLetterPanel> createState() => _SendLetterPanelState();
}

class _SendLetterPanelState extends State<_SendLetterPanel> {
  int? _typeId;
  final _selectedEmployees = <int>{};
  int? _candidateId;
  final _custom = <String, TextEditingController>{};
  bool _email = false;
  bool _esign = false;
  bool _attachment = false;
  bool _saving = false;

  LetterState get state => widget.state;

  Map<String, dynamic>? get _type {
    if (_typeId == null) return null;
    for (final t in state.types) {
      if ((t['id'] as num?)?.toInt() == _typeId) return t;
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in _custom.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncCustomFields(Map<String, dynamic>? type) {
    for (final c in _custom.values) {
      c.dispose();
    }
    _custom.clear();
    final vars = (type?['custom_variables'] as List?) ?? [];
    for (var i = 0; i < vars.length; i++) {
      final v = vars[i];
      if (v is! Map) continue;
      final key = '${v['key'] ?? 'CustomVariable${i + 1}'}';
      _custom[key] = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ((state.options['employees'] as List?) ?? []).whereType<Map>().toList();
    final candidates = ((state.options['candidates'] as List?) ?? []).whereType<Map>().toList();
    final type = _type;
    final isCandidate = (type?['letter_kind'] as num?)?.toInt() == 1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<int>(
          value: _typeId,
          decoration: const InputDecoration(labelText: 'Template', border: OutlineInputBorder()),
          items: [
            for (final t in state.types.where((e) => (e['status'] as num?)?.toInt() == 1))
              DropdownMenuItem(
                value: (t['id'] as num).toInt(),
                child: Text('${t['name']} (${(t['letter_kind'] as num?)?.toInt() == 1 ? 'Candidate' : 'Employee'})'),
              ),
          ],
          onChanged: (v) {
            setState(() {
              _typeId = v;
              _syncCustomFields(_type);
              _selectedEmployees.clear();
              _candidateId = null;
            });
          },
        ),
        const SizedBox(height: 14),
        if (type != null && _custom.isNotEmpty) ...[
          Text('Custom variables', style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
          const SizedBox(height: 8),
          for (final e in _custom.entries) ...[
            TextField(
              controller: e.value,
              decoration: InputDecoration(labelText: e.key, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (type != null && !isCandidate) ...[
          Text('Employees', style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
          const SizedBox(height: 8),
          ...employees.take(80).map((e) {
            final id = (e['id'] as num?)?.toInt() ?? 0;
            return CheckboxListTile(
              dense: true,
              value: _selectedEmployees.contains(id),
              title: Text('${e['name']} (${e['code'] ?? ''})'),
              onChanged: (on) => setState(() {
                if (on == true) {
                  _selectedEmployees.add(id);
                } else {
                  _selectedEmployees.remove(id);
                }
              }),
            );
          }),
        ],
        if (type != null && isCandidate) ...[
          DropdownButtonFormField<int>(
            value: _candidateId,
            decoration: const InputDecoration(labelText: 'Job candidate', border: OutlineInputBorder()),
            items: [
              for (final c in candidates)
                DropdownMenuItem(
                  value: (c['id'] as num).toInt(),
                  child: Text('${c['name']} ${c['email'] ?? ''}'),
                ),
            ],
            onChanged: (v) => setState(() => _candidateId = v),
          ),
        ],
        const SizedBox(height: 12),
        Text('Delivery options (stored for later)', style: TextStyle(color: HrUi.muted(context))),
        SwitchListTile(
          title: const Text('Email (flag only)'),
          value: _email,
          onChanged: (v) => setState(() => _email = v),
        ),
        SwitchListTile(
          title: const Text('Attachment (flag only)'),
          value: _attachment,
          onChanged: (v) => setState(() => _attachment = v),
        ),
        SwitchListTile(
          title: const Text('eSign (flag only)'),
          value: _esign,
          onChanged: (v) => setState(() => _esign = v),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
          onPressed: _saving || type == null
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  setState(() => _saving = true);
                  final data = {for (final e in _custom.entries) e.key: e.value.text.trim()};
                  final err = await state.issueLetter({
                    'type_id': _typeId,
                    if (isCandidate) 'candidate_id': _candidateId,
                    if (!isCandidate) 'employee_ids': _selectedEmployees.toList(),
                    'letter_data': data,
                    'options': {
                      'save_to_documents': true,
                      'email': _email,
                      'attachment': _attachment,
                      'esign': _esign,
                    },
                  });
                  if (!mounted) return;
                  setState(() => _saving = false);
                  messenger.showSnackBar(
                    SnackBar(content: Text(err ?? 'Letter issued.')),
                  );
                  if (err == null) {
                    state.setTab(isCandidate ? 5 : 4);
                  }
                },
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_outlined),
          label: Text(_saving ? 'Issuing…' : 'Issue letter'),
        ),
      ],
    );
  }
}


class _InstanceDialog extends StatefulWidget {
  const _InstanceDialog({required this.state, required this.row});
  final LetterState state;
  final Map<String, dynamic> row;

  @override
  State<_InstanceDialog> createState() => _InstanceDialogState();
}

class _InstanceDialogState extends State<_InstanceDialog> {
  late final TextEditingController _contents;
  late final TextEditingController _ack;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _contents = TextEditingController(text: '${widget.row['contents'] ?? ''}');
    _ack = TextEditingController();
  }

  @override
  void dispose() {
    _contents.dispose();
    _ack.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final id = (row['id'] as num).toInt();
    final status = (row['status'] as num?)?.toInt() ?? 0;
    final ack = '${row['acknowledged_at'] ?? ''}';

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 760,
        height: 620,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${row['name']} · ${row['reference_number'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${row['employee_name'] ?? row['candidate_name'] ?? ''} · ${row['status_label'] ?? ''}'
                  '${ack.isNotEmpty ? ' · Acknowledged' : ''}',
                  style: TextStyle(color: HrUi.muted(context)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _contents,
                  minLines: 16,
                  maxLines: 24,
                  decoration: const InputDecoration(
                    labelText: 'Letter contents',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ),
            if (status == 1 && ack.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _ack,
                  decoration: const InputDecoration(
                    labelText: 'Acknowledgement note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => openHrLetterPrint(context, id),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print / PDF'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final err = await widget.state.updateInstance(id, {'contents': _contents.text});
                            if (!context.mounted) return;
                            setState(() => _busy = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err ?? 'Saved.')),
                            );
                          },
                    child: const Text('Save contents'),
                  ),
                  if (status == 0) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              final err = await widget.state.approve(id);
                              if (!context.mounted) return;
                              setState(() => _busy = false);
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                return;
                              }
                              Navigator.pop(context);
                            },
                      child: const Text('Approve'),
                    ),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              final err = await widget.state.reject(id);
                              if (!context.mounted) return;
                              setState(() => _busy = false);
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                return;
                              }
                              Navigator.pop(context);
                            },
                      child: const Text('Reject'),
                    ),
                  ],
                  if (status == 1 && ack.isEmpty)
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: _busy
                          ? null
                          : () async {
                              setState(() => _busy = true);
                              final err = await widget.state.acknowledge(id, note: _ack.text.trim());
                              if (!context.mounted) return;
                              setState(() => _busy = false);
                              if (err != null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                return;
                              }
                              Navigator.pop(context);
                            },
                      child: const Text('Acknowledge'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compatibility alias used by older navigation routes.
class LettersView extends StatelessWidget {
  const LettersView({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) => HrLettersView(initialTab: initialTab);
}
