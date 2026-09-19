import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/masters/master_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Generic grid + form for Phase 2 master entities (org, lifecycle, payroll items).
class MasterCrudView extends StatefulWidget {
  const MasterCrudView({super.key, required this.entityKey});

  final String entityKey;

  @override
  State<MasterCrudView> createState() => _MasterCrudViewState();
}

class _MasterCrudViewState extends State<MasterCrudView> {
  late final MasterState _state;
  bool _showForm = false;
  int? _editId;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _state = MasterState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load(widget.entityKey));
  }

  @override
  void didUpdateWidget(covariant MasterCrudView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityKey != widget.entityKey) {
      setState(() {
        _showForm = false;
        _editId = null;
      });
      _state.load(widget.entityKey);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        if (_state.busy && _state.rows.isEmpty && !_showForm) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_state.error != null && _state.rows.isEmpty && !_showForm) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: HrTheme.filledButton(context),
                    onPressed: () => _state.load(widget.entityKey),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (_showForm) return _buildForm();
        return _buildGrid();
      },
    );
  }

  Widget _buildGrid() {
    final cols = _state.columns;
    final filtered = _state.rows.where((r) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return r.values.any((v) => '$v'.toLowerCase().contains(q));
    }).toList();

    return HrDataGridPage(
      title: _state.title.isEmpty ? widget.entityKey : _state.title,
      icon: Icons.table_chart_outlined,
      searchHint: 'Search…',
      onSearch: (v) => setState(() => _query = v),
      onRefresh: () => _state.load(widget.entityKey),
      onAdd: _state.readOnly
          ? () {}
          : () {
              _openForm();
            },
      emptyMessage: _state.note ?? 'No records.',
      columns: [
        'S#',
        ...cols.map((c) => (c['label'] ?? c['key']).toString()),
        if (!_state.readOnly) '',
      ],
      rows: [
        for (var i = 0; i < filtered.length; i++)
          [
            Text('${i + 1}'),
            ...cols.map((c) => _cell(filtered[i], c)),
            if (!_state.readOnly)
              PopupMenuButton<String>(
                onSelected: (a) async {
                  final id = (filtered[i]['id'] as num?)?.toInt();
                  if (id == null) return;
                  if (a == 'edit') {
                    _openForm(row: filtered[i]);
                  } else if (a == 'delete') {
                    final err = await _state.remove(id);
                    if (!mounted) return;
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
    );
  }

  Widget _cell(Map<String, dynamic> row, Map<String, dynamic> col) {
    final key = col['key']?.toString() ?? '';
    var val = row[key];
    if (val == null && col['fallback'] != null) {
      val = row[col['fallback']];
    }
    if (col['type'] == 'status') {
      final on = val == 1 || val == '1' || val == true || '$val'.toLowerCase() == 'active';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? const Color(0xFF3B82F6) : HrUi.muted(context).withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          on ? 'Active' : '$val',
          style: TextStyle(
            color: on ? Colors.white : HrUi.label(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Text('${val ?? ''}');
  }

  void _openForm({Map<String, dynamic>? row}) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _values.clear();
    _editId = (row?['id'] as num?)?.toInt();
    for (final f in _state.fields) {
      final key = f['key']?.toString() ?? '';
      if (key.isEmpty) continue;
      final type = f['type']?.toString() ?? 'text';
      final initial = row?[key] ?? f['default'];
      if (type == 'fk' || type == 'select' || type == 'hidden') {
        _values[key] = initial;
      } else {
        _controllers[key] = TextEditingController(text: initial?.toString() ?? '');
      }
    }
    setState(() => _showForm = true);
  }

  Widget _buildForm() {
    return HrFormShell(
      moduleTitle: _state.title,
      moduleIcon: Icons.edit_note,
      formTitle: _editId == null ? 'Add Record' : 'Edit Record',
      onBack: () => setState(() => _showForm = false),
      footer: Row(
        children: [
          OutlinedButton(
            onPressed: () => setState(() => _showForm = false),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_state.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_state.note!, style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
            ),
          for (final f in _state.fields) _field(f),
        ],
      ),
    );
  }

  Widget _field(Map<String, dynamic> f) {
    final key = f['key']?.toString() ?? '';
    final type = f['type']?.toString() ?? 'text';
    final label = f['label']?.toString() ?? key;
    if (type == 'hidden') return const SizedBox.shrink();

    if (type == 'fk' || type == 'select') {
      final optsRaw = f['options'];
      final items = <DropdownMenuItem<String>>[];
      if (optsRaw is List) {
        for (final o in optsRaw) {
          if (o is Map) {
            final id = '${o['id']}';
            items.add(DropdownMenuItem(value: id, child: Text('${o['label']}')));
          }
        }
      } else if (optsRaw is Map) {
        optsRaw.forEach((k, v) {
          items.add(DropdownMenuItem(value: '$k', child: Text('$v')));
        });
      }
      final current = _values[key]?.toString();
      return HrFormRow(
        label: label,
        child: DropdownButtonFormField<String>(
          value: items.any((i) => i.value == current) ? current : null,
          items: items,
          onChanged: (v) => setState(() => _values[key] = v),
          decoration: hrFieldDecoration(context),
        ),
      );
    }

    if (type == 'textarea') {
      return HrFormRow(
        label: label,
        child: TextField(
          controller: _controllers[key],
          maxLines: 4,
          decoration: hrFieldDecoration(context),
        ),
      );
    }

    return HrFormRow(
      label: label,
      child: TextField(
        controller: _controllers[key],
        keyboardType: type == 'number'
            ? TextInputType.number
            : type == 'email'
                ? TextInputType.emailAddress
                : TextInputType.text,
        decoration: hrFieldDecoration(context, hint: f['hint']?.toString()),
      ),
    );
  }

  Future<void> _save() async {
    final data = <String, dynamic>{};
    for (final f in _state.fields) {
      final key = f['key']?.toString() ?? '';
      final type = f['type']?.toString() ?? 'text';
      if (type == 'fk' || type == 'select' || type == 'hidden') {
        final v = _values[key] ?? f['default'];
        if (v != null) data[key] = v;
      } else {
        data[key] = _controllers[key]?.text ?? '';
      }
    }
    final err = await _state.save(data, id: _editId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Saved'),
        backgroundColor: err == null ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
    if (err == null) setState(() => _showForm = false);
  }
}
