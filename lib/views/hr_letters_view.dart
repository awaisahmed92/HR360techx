import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/letters/letter_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

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
                    if (_state.tab == 1)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                        onPressed: () => _editType(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New template'),
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
    if (_state.types.isEmpty) {
      return Center(child: Text('No templates yet.', style: TextStyle(color: HrUi.muted(context))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _state.types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = _state.types[i];
        final kind = (t['letter_kind'] as num?)?.toInt() == 1 ? 'Candidate' : 'Employee';
        final active = (t['status'] as num?)?.toInt() == 1;
        return Card(
          child: ListTile(
            title: Text('${t['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('$kind · ${t['category_name'] ?? 'Uncategorized'}${active ? '' : ' · Inactive'}'),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editType(existing: t)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final err = await _state.deleteType((t['id'] as num).toInt());
                    if (!context.mounted) return;
                    if (err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              ],
            ),
            onTap: () => _editType(existing: t),
          ),
        );
      },
    );
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

  Future<void> _editType({Map<String, dynamic>? existing}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DesignerDialog(
        state: _state,
        existing: existing,
      ),
    );
    if (mounted) await _state.loadTab(silent: true);
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

class _DesignerDialog extends StatefulWidget {
  const _DesignerDialog({required this.state, this.existing});
  final LetterState state;
  final Map<String, dynamic>? existing;

  @override
  State<_DesignerDialog> createState() => _DesignerDialogState();
}

class _DesignerDialogState extends State<_DesignerDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _name;
  late final TextEditingController _contents;
  late final TextEditingController _header;
  late final TextEditingController _footer;
  late final TextEditingController _refPattern;
  late final TextEditingController _logo;
  late final TextEditingController _footerImage;
  int? _categoryId;
  int _kind = 0;
  int _status = 1;
  bool _skipApproval = false;
  String _pageSize = 'A4';
  final _margins = <String, TextEditingController>{};
  final _custom = <Map<String, TextEditingController>>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    final e = widget.existing;
    _name = TextEditingController(text: '${e?['name'] ?? ''}');
    _contents = TextEditingController(text: '${e?['contents'] ?? ''}');
    _header = TextEditingController(text: '${e?['header_html'] ?? ''}');
    _footer = TextEditingController(text: '${e?['footer_html'] ?? ''}');
    _refPattern = TextEditingController(text: '${e?['reference_pattern'] ?? 'HRL-{YYYY}-{####}'}');
    _logo = TextEditingController(text: '${e?['logo_path'] ?? ''}');
    _footerImage = TextEditingController(text: '${e?['footer_image_path'] ?? ''}');
    _categoryId = (e?['category_id'] as num?)?.toInt();
    _kind = (e?['letter_kind'] as num?)?.toInt() ?? 0;
    _status = (e?['status'] as num?)?.toInt() ?? 1;
    final opts = (e?['options'] is Map) ? Map<String, dynamic>.from(e!['options'] as Map) : <String, dynamic>{};
    _skipApproval = opts['skip_approval'] == true;
    _pageSize = '${opts['page_size'] ?? 'A4'}';
    for (final k in ['margin_top', 'margin_right', 'margin_bottom', 'margin_left']) {
      _margins[k] = TextEditingController(text: '${opts[k] ?? 20}');
    }
    final vars = (e?['custom_variables'] as List?) ?? [];
    for (final v in vars) {
      if (v is! Map) continue;
      _custom.add({
        'key': TextEditingController(text: '${v['key'] ?? ''}'),
        'label': TextEditingController(text: '${v['label'] ?? ''}'),
        'type': TextEditingController(text: '${v['type'] ?? 'Text'}'),
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _name.dispose();
    _contents.dispose();
    _header.dispose();
    _footer.dispose();
    _refPattern.dispose();
    _logo.dispose();
    _footerImage.dispose();
    for (final c in _margins.values) {
      c.dispose();
    }
    for (final row in _custom) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ((widget.state.options['categories'] as List?) ?? []).whereType<Map>().toList();
    final placeholders = _kind == 1
        ? ((widget.state.options['candidate_placeholders'] as List?) ?? [])
        : ((widget.state.options['employee_placeholders'] as List?) ?? []);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 860,
        height: 640,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    widget.existing == null ? 'New template' : 'Edit template',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Contents'),
                Tab(text: 'Header & Footer'),
                Tab(text: 'Custom Variables'),
                Tab(text: 'Images'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        value: _categoryId,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          for (final c in cats)
                            DropdownMenuItem(value: (c['id'] as num).toInt(), child: Text('${c['name']}')),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _kind,
                        decoration: const InputDecoration(labelText: 'Letter kind', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Employee')),
                          DropdownMenuItem(value: 1, child: Text('Job candidate')),
                        ],
                        onChanged: (v) => setState(() => _kind = v ?? 0),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _refPattern,
                        decoration: const InputDecoration(labelText: 'Reference pattern', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _pageSize,
                        decoration: const InputDecoration(labelText: 'Page size', border: OutlineInputBorder()),
                        items: [
                          for (final s in ((widget.state.options['page_sizes'] as List?) ?? ['A4']))
                            DropdownMenuItem(value: '$s', child: Text('$s')),
                        ],
                        onChanged: (v) => setState(() => _pageSize = v ?? 'A4'),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final e in _margins.entries)
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: e.value,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: e.key.replaceAll('_', ' '),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Skip approval'),
                        value: _skipApproval,
                        onChanged: (v) => setState(() => _skipApproval = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: _status == 1,
                        onChanged: (v) => setState(() => _status = v ? 1 : 0),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in placeholders)
                            ActionChip(
                              label: Text('$p'),
                              onPressed: () {
                                final t = _contents;
                                final text = t.text;
                                final sel = t.selection;
                                final insert = '$p';
                                final start = sel.start >= 0 ? sel.start : text.length;
                                final end = sel.end >= 0 ? sel.end : text.length;
                                t.text = text.replaceRange(start, end, insert);
                                t.selection = TextSelection.collapsed(offset: start + insert.length);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contents,
                        minLines: 12,
                        maxLines: 20,
                        decoration: const InputDecoration(
                          labelText: 'Contents (HTML allowed)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: _header,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(labelText: 'Header HTML', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _footer,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(labelText: 'Footer HTML', border: OutlineInputBorder()),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _custom.add({
                              'key': TextEditingController(text: 'CustomVariable${_custom.length + 1}'),
                              'label': TextEditingController(text: 'Field ${_custom.length + 1}'),
                              'type': TextEditingController(text: 'Text'),
                            });
                          }),
                          icon: const Icon(Icons.add),
                          label: const Text('Add variable'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _custom.length; i++) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _custom[i]['key'],
                                decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _custom[i]['label'],
                                decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _custom[i]['type'],
                                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() {
                                for (final c in _custom[i].values) {
                                  c.dispose();
                                }
                                _custom.removeAt(i);
                              }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: _logo,
                        decoration: const InputDecoration(labelText: 'Logo path', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _footerImage,
                        decoration: const InputDecoration(labelText: 'Footer image path', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload via Files module later; store relative paths for now.',
                        style: TextStyle(color: HrUi.muted(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            final body = {
                              'name': _name.text.trim(),
                              'category_id': _categoryId,
                              'letter_kind': _kind,
                              'contents': _contents.text,
                              'header_html': _header.text,
                              'footer_html': _footer.text,
                              'reference_pattern': _refPattern.text.trim(),
                              'logo_path': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
                              'footer_image_path':
                                  _footerImage.text.trim().isEmpty ? null : _footerImage.text.trim(),
                              'status': _status,
                              'custom_variables': [
                                for (final row in _custom)
                                  {
                                    'key': row['key']!.text.trim(),
                                    'label': row['label']!.text.trim(),
                                    'type': row['type']!.text.trim(),
                                  },
                              ],
                              'options': {
                                'page_size': _pageSize,
                                'skip_approval': _skipApproval,
                                'logo_align': 'left',
                                for (final e in _margins.entries)
                                  e.key: double.tryParse(e.value.text.trim()) ?? 20,
                              },
                            };
                            final err = await widget.state.saveType(
                              body,
                              id: widget.existing == null ? null : (widget.existing!['id'] as num).toInt(),
                            );
                            if (!context.mounted) return;
                            setState(() => _saving = false);
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                              return;
                            }
                            Navigator.pop(context);
                          },
                    child: Text(_saving ? 'Saving…' : 'Save'),
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
