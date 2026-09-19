import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/lifecycle/lifecycle_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

class TerminationView extends StatefulWidget {
  const TerminationView({super.key});

  @override
  State<TerminationView> createState() => _TerminationViewState();
}

class _TerminationViewState extends State<TerminationView> {
  late final TerminationState _state;

  @override
  void initState() {
    super.initState();
    _state = TerminationState(context.read<AuthState>());
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
                    Text('Termination',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: _add,
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
                child: _state.busy && _state.rows.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _state.rows.isEmpty
                        ? Center(child: Text('No terminations recorded.', style: TextStyle(color: HrUi.muted(context))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _state.rows.length,
                            itemBuilder: (context, i) {
                              final r = _state.rows[i];
                              return ListTile(
                                title: Text('${r['employee_name']} · ${r['termination_type']}'),
                                subtitle: Text(
                                    '${r['employee_code'] ?? ''} · ${r['termination_date']} · ${r['department_name'] ?? ''}\n${r['reason'] ?? ''}'),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final err = await _state.delete((r['id'] as num).toInt());
                                    if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _add() async {
    final employees = (_state.options['employees'] as List?) ?? [];
    final types = (_state.options['types'] as List?) ?? [];
    int? empId;
    String termType = 'Others';
    final date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final notice = TextEditingController();
    final reason = TextEditingController();
    var deactivate = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Termination'),
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
                DropdownButtonFormField<String>(
                  value: termType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: types.whereType<Map>().map((e) {
                    final id = '${e['id']}';
                    return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                  }).toList(),
                  onChanged: (v) => setLocal(() => termType = v ?? 'Others'),
                ),
                TextField(controller: date, decoration: const InputDecoration(labelText: 'Termination date')),
                TextField(controller: notice, decoration: const InputDecoration(labelText: 'Notice date')),
                TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deactivate employee'),
                  value: deactivate,
                  onChanged: (v) => setLocal(() => deactivate = v),
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
    final err = await _state.save({
      'employee_id': empId,
      'termination_type': termType,
      'termination_date': date.text.trim(),
      'notice_date': notice.text.trim().isEmpty ? null : notice.text.trim(),
      'reason': reason.text.trim(),
      'deactivate_employee': deactivate,
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class LoanApplicationView extends StatefulWidget {
  const LoanApplicationView({super.key});

  @override
  State<LoanApplicationView> createState() => _LoanApplicationViewState();
}

class _LoanApplicationViewState extends State<LoanApplicationView> {
  late final LoanApplicationState _state;

  @override
  void initState() {
    super.initState();
    _state = LoanApplicationState(context.read<AuthState>());
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
                    Text('Loan Applications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: _add,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Apply'),
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
                child: _state.busy && _state.rows.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _state.rows.isEmpty
                        ? Center(child: Text('No loan applications.', style: TextStyle(color: HrUi.muted(context))))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _state.rows.length,
                            itemBuilder: (context, i) {
                              final r = _state.rows[i];
                              final status = '${r['status']}';
                              return Card(
                                child: ListTile(
                                  title: Text('${r['employee_name']} · ${r['loan_amount']}'),
                                  subtitle: Text(
                                      '${r['start_date']} → ${r['end_date']} · ${r['status_label']}\n${r['purpose_of_loan'] ?? ''}'),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (status == 'pending') ...[
                                        IconButton(
                                          tooltip: 'Approve',
                                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final err = await _state.setStatus((r['id'] as num).toInt(), 'approved');
                                            if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Reject',
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final err = await _state.setStatus((r['id'] as num).toInt(), 'rejected');
                                            if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                                          },
                                        ),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final err = await _state.delete((r['id'] as num).toInt());
                                          if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _add() async {
    final employees = (_state.options['employees'] as List?) ?? [];
    int? empId;
    final amount = TextEditingController();
    final purpose = TextEditingController();
    final start = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final end = TextEditingController(
        text: DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Loan Application'),
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
                TextField(
                  controller: amount,
                  decoration: const InputDecoration(labelText: 'Amount *'),
                  keyboardType: TextInputType.number,
                ),
                TextField(controller: purpose, decoration: const InputDecoration(labelText: 'Purpose'), maxLines: 2),
                TextField(controller: start, decoration: const InputDecoration(labelText: 'Start date')),
                TextField(controller: end, decoration: const InputDecoration(labelText: 'End date')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok != true || empId == null) return;
    final err = await _state.save({
      'employee_id': empId,
      'loan_amount': double.tryParse(amount.text) ?? 0,
      'purpose_of_loan': purpose.text.trim(),
      'start_date': start.text.trim(),
      'end_date': end.text.trim(),
      'status': 'pending',
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
