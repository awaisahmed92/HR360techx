import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/performance/performance_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// API-backed Performance: Reviews · Indicators · Appraisals.
class PerformanceView extends StatefulWidget {
  const PerformanceView({super.key});

  @override
  State<PerformanceView> createState() => _PerformanceViewState();
}

class _PerformanceViewState extends State<PerformanceView> {
  late final PerformanceState _state;

  @override
  void initState() {
    super.initState();
    _state = PerformanceState(context.read<AuthState>());
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
                    Text('Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Reviews')),
                        ButtonSegment(value: 1, label: Text('Indicators')),
                        ButtonSegment(value: 2, label: Text('Appraisals')),
                        ButtonSegment(value: 3, label: Text('Goals')),
                        ButtonSegment(value: 4, label: Text('Types')),
                        ButtonSegment(value: 5, label: Text('Cycles')),
                      ],
                      selected: {_state.tab},
                      onSelectionChanged: (s) => _state.setTab(s.first),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: () {
                        if (_state.tab == 0) _addReview();
                        if (_state.tab == 1) _addIndicator();
                        if (_state.tab == 2) _addAppraisal();
                        if (_state.tab == 3) _addGoal();
                        if (_state.tab == 4) _addGoalType();
                        if (_state.tab == 5) _addCycle();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
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
                child: _state.busy && _state.reviews.isEmpty && _state.goals.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_state.tab == 0) ..._reviews(),
                          if (_state.tab == 1) ..._indicators(),
                          if (_state.tab == 2) ..._appraisals(),
                          if (_state.tab == 3) ..._goals(),
                          if (_state.tab == 4) ..._goalTypes(),
                          if (_state.tab == 5) ..._cycles(),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _reviews() {
    if (_state.reviews.isEmpty) {
      return [Text('No reviews yet.', style: TextStyle(color: HrUi.muted(context)))];
    }
    return _state.reviews
        .map((r) => ListTile(
              title: Text('${r['employee_name']} · ${r['indicator_name'] ?? 'General'}'),
              subtitle: Text('Rating ${r['rating']} · ${r['review_date'] ?? ''} · ${r['comments'] ?? ''}'),
              leading: CircleAvatar(
                backgroundColor: HrTheme.brand(context).withOpacity(0.15),
                child: Text('${r['rating']}',
                    style: TextStyle(color: HrTheme.brand(context), fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ))
        .toList();
  }

  List<Widget> _indicators() {
    if (_state.indicators.isEmpty) {
      return [Text('No indicators yet.', style: TextStyle(color: HrUi.muted(context)))];
    }
    return _state.indicators
        .map((i) => ListTile(
              title: Text('${i['name']}'),
              subtitle: Text('${i['description'] ?? ''}'),
            ))
        .toList();
  }

  List<Widget> _appraisals() {
    if (_state.appraisals.isEmpty) {
      return [Text('No appraisals yet.', style: TextStyle(color: HrUi.muted(context)))];
    }
    return _state.appraisals
        .map((a) {
          final stage = '${a['stage_label'] ?? a['current_stage'] ?? 'Goal Setting'}';
          final done = '${a['current_stage']}' == 'acknowledged';
          return ListTile(
            title: Text('${a['employee_name']} · ${a['period'] ?? ''}'),
            subtitle: Text(
              '${a['cycle_name'] != null && '${a['cycle_name']}'.isNotEmpty ? '${a['cycle_name']} · ' : ''}'
              '$stage · ${a['status_label']} · Score ${a['overall_score'] ?? '—'} · ${a['final_rating'] ?? ''}',
            ),
            trailing: done
                ? Icon(Icons.check_circle, color: Colors.green.shade600)
                : TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final err = await _state.advanceAppraisal((a['id'] as num).toInt());
                      if (err != null) {
                        messenger.showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        messenger.showSnackBar(const SnackBar(content: Text('Stage advanced')));
                      }
                    },
                    child: const Text('Next stage →'),
                  ),
          );
        })
        .toList();
  }

  List<Widget> _goals() {
    if (_state.goals.isEmpty) {
      return [Text('No goals yet.', style: TextStyle(color: HrUi.muted(context)))];
    }
    return _state.goals
        .map((g) {
          final appraisalId = (g['appraisal_id'] as num?)?.toInt();
          Map<String, dynamic>? linked;
          if (appraisalId != null) {
            for (final a in _state.appraisals) {
              if ((a['id'] as num?)?.toInt() == appraisalId) {
                linked = a;
                break;
              }
            }
          }
          return ListTile(
            title: Text('${g['title']}'),
            subtitle: Text(
                '${g['employee_name']} · ${g['goal_type_name'] ?? '—'} · '
                '${linked != null ? 'Appraisal ${linked['period'] ?? linked['id']} · ' : ''}'
                'Target ${g['target_value'] ?? '—'} · ${g['status_label']} · Score ${g['score']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await _state.deleteGoal((g['id'] as num).toInt());
                if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
              },
            ),
          );
        })
        .toList();
  }

  List<Widget> _cycles() {
    if (_state.cycles.isEmpty) {
      return [Text('No cycles yet. Add a review cycle to group appraisals.', style: TextStyle(color: HrUi.muted(context)))];
    }
    return _state.cycles
        .map((c) => ListTile(
              title: Text('${c['name']}'),
              subtitle: Text('${c['status_label']} · ${c['period_start'] ?? ''} → ${c['period_end'] ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final err = await _state.deleteCycle((c['id'] as num).toInt());
                  if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                },
              ),
            ))
        .toList();
  }

  List<Widget> _goalTypes() {
    if (_state.goalTypes.isEmpty) {
      return [Text('No goal types yet.', style: TextStyle(color: HrUi.muted(context)))];
    }
    return _state.goalTypes
        .map((t) => ListTile(
              title: Text('${t['name']}'),
              subtitle: Text('${t['description'] ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final err = await _state.deleteGoalType((t['id'] as num).toInt());
                  if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                },
              ),
            ))
        .toList();
  }

  Future<void> _addReview() async {
    final employees = (_state.options['employees'] as List?) ?? [];
    final indicators = (_state.options['indicators'] as List?) ?? [];
    int? empId;
    int? indId;
    final rating = TextEditingController(text: '4');
    final comments = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Log Review'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: empId,
                  decoration: const InputDecoration(labelText: 'Employee *'),
                  items: employees.whereType<Map>().map((e) {
                    final id = (e['id'] as num?)?.toInt();
                    return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                  }).toList(),
                  onChanged: (v) => setLocal(() => empId = v),
                ),
                DropdownButtonFormField<int>(
                  value: indId,
                  decoration: const InputDecoration(labelText: 'Indicator'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...indicators.whereType<Map>().map((e) {
                      final id = (e['id'] as num?)?.toInt();
                      return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                    }),
                  ],
                  onChanged: (v) => setLocal(() => indId = v),
                ),
                TextField(
                  controller: rating,
                  decoration: const InputDecoration(labelText: 'Rating (0–10)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(controller: comments, decoration: const InputDecoration(labelText: 'Comments'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || empId == null) return;
    final err = await _state.saveReview({
      'employee_id': empId,
      'indicator_id': indId,
      'rating': double.tryParse(rating.text) ?? 0,
      'comments': comments.text.trim(),
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addIndicator() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Indicator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final err = await _state.saveIndicator({
      'name': name.text.trim(),
      'description': desc.text.trim(),
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addAppraisal() async {
    final employees = (_state.options['employees'] as List?) ?? [];
    int? empId;
    int? cycleId;
    final period = TextEditingController(text: '2026 H1');
    final score = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Appraisal'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: empId,
                  decoration: const InputDecoration(labelText: 'Employee *'),
                  items: employees.whereType<Map>().map((e) {
                    final id = (e['id'] as num?)?.toInt();
                    return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                  }).toList(),
                  onChanged: (v) => setLocal(() => empId = v),
                ),
                DropdownButtonFormField<int?>(
                  value: cycleId,
                  decoration: const InputDecoration(labelText: 'Cycle'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ..._state.cycles.map((c) {
                      final id = (c['id'] as num?)?.toInt();
                      return DropdownMenuItem(value: id, child: Text('${c['name']}'));
                    }),
                  ],
                  onChanged: (v) => setLocal(() => cycleId = v),
                ),
                TextField(controller: period, decoration: const InputDecoration(labelText: 'Period')),
                TextField(
                  controller: score,
                  decoration: const InputDecoration(labelText: 'Overall Score'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || empId == null) return;
    final err = await _state.saveAppraisal({
      'employee_id': empId,
      'cycle_id': cycleId,
      'period': period.text.trim(),
      'overall_score': double.tryParse(score.text),
      'status': 0,
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addGoal() async {
    final employees = (_state.options['employees'] as List?) ?? [];
    final types = (_state.options['goal_types'] as List?) ?? [];
    int? empId;
    int? typeId;
    int? appraisalId;
    final title = TextEditingController();
    final target = TextEditingController();
    final metric = TextEditingController();
    final period = TextEditingController(text: '2026 H1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Goal'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: empId,
                    decoration: const InputDecoration(labelText: 'Employee *'),
                    items: employees.whereType<Map>().map((e) {
                      final id = (e['id'] as num?)?.toInt();
                      return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                    }).toList(),
                    onChanged: (v) => setLocal(() => empId = v),
                  ),
                  DropdownButtonFormField<int?>(
                    value: typeId,
                    decoration: const InputDecoration(labelText: 'Goal type'),
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
                    value: appraisalId,
                    decoration: const InputDecoration(labelText: 'Link to appraisal'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      ..._state.appraisals.map((a) {
                        final id = (a['id'] as num?)?.toInt();
                        final label = '${a['employee_name'] ?? ''} · ${a['period'] ?? id}';
                        return DropdownMenuItem(value: id, child: Text(label));
                      }),
                    ],
                    onChanged: (v) => setLocal(() => appraisalId = v),
                  ),
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Title *')),
                  TextField(controller: metric, decoration: const InputDecoration(labelText: 'Metric')),
                  TextField(controller: target, decoration: const InputDecoration(labelText: 'Target')),
                  TextField(controller: period, decoration: const InputDecoration(labelText: 'Period')),
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
    if (ok != true || empId == null || title.text.trim().isEmpty) return;
    final err = await _state.saveGoal({
      'employee_id': empId,
      'goal_type_id': typeId,
      'appraisal_id': appraisalId,
      'title': title.text.trim(),
      'metric': metric.text.trim(),
      'target_value': target.text.trim(),
      'period': period.text.trim(),
      'status': 0,
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addGoalType() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Goal Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final err = await _state.saveGoalType({
      'name': name.text.trim(),
      'description': desc.text.trim(),
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addCycle() async {
    final name = TextEditingController();
    final start = TextEditingController(text: '2026-01-01');
    final end = TextEditingController(text: '2026-06-30');
    int status = 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Review Cycle'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
                TextField(controller: start, decoration: const InputDecoration(labelText: 'Period start (YYYY-MM-DD)')),
                TextField(controller: end, decoration: const InputDecoration(labelText: 'Period end (YYYY-MM-DD)')),
                DropdownButtonFormField<int>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Open')),
                    DropdownMenuItem(value: 0, child: Text('Closed')),
                  ],
                  onChanged: (v) => setLocal(() => status = v ?? 1),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final err = await _state.saveCycle({
      'name': name.text.trim(),
      'period_start': start.text.trim(),
      'period_end': end.text.trim(),
      'status': status,
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
