import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/training/training_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Training list · calendar · trainers · types.
class TrainingView extends StatefulWidget {
  const TrainingView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  late final TrainingState _state;

  @override
  void initState() {
    super.initState();
    _state = TrainingState(context.read<AuthState>())..tab = widget.initialTab.clamp(0, 3);
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text('Training',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Sessions')),
                        ButtonSegment(value: 1, label: Text('Calendar')),
                        ButtonSegment(value: 2, label: Text('Trainers')),
                        ButtonSegment(value: 3, label: Text('Types')),
                      ],
                      selected: {_state.tab},
                      onSelectionChanged: (s) => _state.setTab(s.first),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: () {
                        if (_state.tab == 0) _addTraining();
                        if (_state.tab == 1) _state.load();
                        if (_state.tab == 2) _addTrainer();
                        if (_state.tab == 3) _addType();
                      },
                      icon: Icon(_state.tab == 1 ? Icons.refresh : Icons.add, size: 18),
                      label: Text(_state.tab == 1 ? 'Refresh' : 'Add'),
                    ),
                    if (_state.tab != 1)
                      IconButton(onPressed: () => _state.load(), icon: const Icon(Icons.refresh)),
                  ],
                ),
              ),
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Expanded(
                child: _state.busy && _empty
                    ? const Center(child: CircularProgressIndicator())
                    : switch (_state.tab) {
                        0 => _sessions(),
                        1 => _calendar(),
                        2 => _trainers(),
                        _ => _types(),
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  bool get _empty =>
      (_state.tab == 0 && _state.trainings.isEmpty) ||
      (_state.tab == 1 && _state.events.isEmpty) ||
      (_state.tab == 2 && _state.trainers.isEmpty) ||
      (_state.tab == 3 && _state.types.isEmpty);

  Widget _sessions() {
    if (_state.trainings.isEmpty) {
      return Center(child: Text('No training sessions yet.', style: TextStyle(color: HrUi.muted(context))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _state.trainings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = _state.trainings[i];
        return Card(
          child: ListTile(
            title: Text(
              '${t['training_type_name'] ?? 'Training'}${t['batch_name'] != null && '${t['batch_name']}'.isNotEmpty ? ' · ${t['batch_name']}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${t['start_date'] ?? ''} → ${t['end_date'] ?? ''} · ${t['trainer_name'] ?? '—'} · '
              '${t['attendee_count'] ?? 0} attendees · ${t['training_status'] ?? ''}'
              '${t['venue'] != null && '${t['venue']}'.isNotEmpty ? '\n${t['venue']}' : ''}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await _state.deleteTraining((t['id'] as num).toInt());
                if (err != null) {
                  messenger.showSnackBar(SnackBar(content: Text(err)));
                }
              },
            ),
            onTap: () => _addTraining(existing: t),
          ),
        );
      },
    );
  }

  Widget _calendar() {
    final label =
        '${_state.calendarMonth.year}-${_state.calendarMonth.month.toString().padLeft(2, '0')}';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _state.calendarMonth =
                      DateTime(_state.calendarMonth.year, _state.calendarMonth.month - 1);
                  _state.load();
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
              IconButton(
                onPressed: () {
                  _state.calendarMonth =
                      DateTime(_state.calendarMonth.year, _state.calendarMonth.month + 1);
                  _state.load();
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: _state.events.isEmpty
              ? Center(child: Text('No sessions this month.', style: TextStyle(color: HrUi.muted(context))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _state.events.length,
                  itemBuilder: (context, i) {
                    final e = _state.events[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: HrTheme.brand(context).withValues(alpha: 0.15),
                        child: Text(
                          '${e['start_date']}'.length >= 10 ? '${e['start_date']}'.substring(8, 10) : '?',
                          style: TextStyle(color: HrTheme.brand(context), fontWeight: FontWeight.w800),
                        ),
                      ),
                      title: Text('${e['title']}'),
                      subtitle: Text('${e['start_date']} · ${e['trainer'] ?? ''} · ${e['venue'] ?? ''}'),
                      trailing: Text('${e['status']}', style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _trainers() {
    if (_state.trainers.isEmpty) {
      return Center(child: Text('No trainers yet.', style: TextStyle(color: HrUi.muted(context))));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: _state.trainers
          .map((t) => ListTile(
                title: Text('${t['name']}'),
                subtitle: Text('${t['role'] ?? ''} · ${t['internal_external'] ?? ''} · ${t['email'] ?? ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final err = await _state.deleteTrainer((t['id'] as num).toInt());
                    if (mounted && err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
                onTap: () => _addTrainer(existing: t),
              ))
          .toList(),
    );
  }

  Widget _types() {
    if (_state.types.isEmpty) {
      return Center(child: Text('No training types yet.', style: TextStyle(color: HrUi.muted(context))));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: _state.types
          .map((t) => ListTile(
                title: Text('${t['name']}'),
                subtitle: Text(
                    '${t['category'] ?? ''} · ${t['is_mandatory'] == true ? 'Mandatory' : 'Optional'}'
                    '${t['renewal_months'] != null ? ' · renew ${t['renewal_months']} mo' : ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final err = await _state.deleteType((t['id'] as num).toInt());
                    if (mounted && err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
                onTap: () => _addType(existing: t),
              ))
          .toList(),
    );
  }

  Future<void> _addTraining({Map<String, dynamic>? existing}) async {
    final types = (_state.options['types'] as List?) ?? [];
    final trainers = (_state.options['trainers'] as List?) ?? [];
    final employees = (_state.options['employees'] as List?) ?? [];
    final statuses = (_state.options['statuses'] as List?) ?? [];

    int? typeId = (existing?['training_type_id'] as num?)?.toInt();
    int? trainerId = (existing?['trainer_id'] as num?)?.toInt();
    String status = '${existing?['training_status'] ?? 'Scheduled'}';
    final batch = TextEditingController(text: '${existing?['batch_name'] ?? ''}');
    final venue = TextEditingController(text: '${existing?['venue'] ?? ''}');
    final desc = TextEditingController(text: '${existing?['description'] ?? ''}');
    final start = TextEditingController(text: '${existing?['start_date'] ?? _ymd(DateTime.now())}');
    final end = TextEditingController(text: '${existing?['end_date'] ?? _ymd(DateTime.now())}');
    final cost = TextEditingController(text: '${existing?['cost'] ?? 0}');
    final selected = <int>{};

    if (existing != null) {
      final detail = await _state.loadTrainingDetail((existing['id'] as num).toInt());
      if (detail != null) {
        final ids = (detail['participant_ids'] as List?) ?? [];
        selected.addAll(ids.map((e) => (e as num).toInt()));
      }
    }
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add Training' : 'Edit Training'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    value: typeId,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ...types.whereType<Map>().map((e) {
                        final id = (e['id'] as num?)?.toInt();
                        return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                      }),
                    ],
                    onChanged: (v) => setLocal(() => typeId = v),
                  ),
                  DropdownButtonFormField<int?>(
                    value: trainerId,
                    decoration: const InputDecoration(labelText: 'Trainer'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ...trainers.whereType<Map>().map((e) {
                        final id = (e['id'] as num?)?.toInt();
                        return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                      }),
                    ],
                    onChanged: (v) => setLocal(() => trainerId = v),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statuses.whereType<Map>().map((e) {
                      final id = '${e['id']}';
                      return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                    }).toList(),
                    onChanged: (v) => setLocal(() => status = v ?? 'Scheduled'),
                  ),
                  TextField(controller: batch, decoration: const InputDecoration(labelText: 'Batch name')),
                  TextField(controller: venue, decoration: const InputDecoration(labelText: 'Venue')),
                  TextField(controller: start, decoration: const InputDecoration(labelText: 'Start date (YYYY-MM-DD)')),
                  TextField(controller: end, decoration: const InputDecoration(labelText: 'End date (YYYY-MM-DD)')),
                  TextField(
                    controller: cost,
                    decoration: const InputDecoration(labelText: 'Cost'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Participants', style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 160),
                    child: ListView(
                      shrinkWrap: true,
                      children: employees.whereType<Map>().map((e) {
                        final id = (e['id'] as num?)?.toInt();
                        if (id == null) return const SizedBox.shrink();
                        return CheckboxListTile(
                          dense: true,
                          value: selected.contains(id),
                          title: Text('${e['name']}', style: const TextStyle(fontSize: 13)),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (v) => setLocal(() {
                            if (v == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final err = await _state.saveTraining({
      'training_type_id': typeId,
      'trainer_id': trainerId,
      'training_status': status,
      'batch_name': batch.text.trim(),
      'venue': venue.text.trim(),
      'start_date': start.text.trim(),
      'end_date': end.text.trim(),
      'cost': double.tryParse(cost.text) ?? 0,
      'description': desc.text.trim(),
      'participant_ids': selected.toList(),
    }, id: (existing?['id'] as num?)?.toInt());
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addTrainer({Map<String, dynamic>? existing}) async {
    final first = TextEditingController(text: '${existing?['first_name'] ?? ''}');
    final last = TextEditingController(text: '${existing?['last_name'] ?? ''}');
    final role = TextEditingController(text: '${existing?['role'] ?? ''}');
    final email = TextEditingController(text: '${existing?['email'] ?? ''}');
    final phone = TextEditingController(text: '${existing?['phone'] ?? ''}');
    String kind = '${existing?['internal_external'] ?? 'internal'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add Trainer' : 'Edit Trainer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: first, decoration: const InputDecoration(labelText: 'First name *')),
              TextField(controller: last, decoration: const InputDecoration(labelText: 'Last name')),
              TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
              DropdownButtonFormField<String>(
                value: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'internal', child: Text('Internal')),
                  DropdownMenuItem(value: 'external', child: Text('External')),
                ],
                onChanged: (v) => setLocal(() => kind = v ?? 'internal'),
              ),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || first.text.trim().isEmpty) return;
    final err = await _state.saveTrainer({
      'first_name': first.text.trim(),
      'last_name': last.text.trim(),
      'role': role.text.trim(),
      'internal_external': kind,
      'email': email.text.trim(),
      'phone': phone.text.trim(),
    }, id: (existing?['id'] as num?)?.toInt());
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addType({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final category = TextEditingController(text: '${existing?['category'] ?? ''}');
    final renewal = TextEditingController(text: '${existing?['renewal_months'] ?? ''}');
    final desc = TextEditingController(text: '${existing?['description'] ?? ''}');
    bool mandatory = existing?['is_mandatory'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add Type' : 'Edit Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
              TextField(
                controller: renewal,
                decoration: const InputDecoration(labelText: 'Renewal months'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('Mandatory'),
                value: mandatory,
                onChanged: (v) => setLocal(() => mandatory = v),
              ),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final err = await _state.saveType({
      'name': name.text.trim(),
      'category': category.text.trim(),
      'renewal_months': int.tryParse(renewal.text),
      'is_mandatory': mandatory,
      'description': desc.text.trim(),
    }, id: (existing?['id'] as num?)?.toInt());
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
