import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/self_service/self_service_state.dart';
import '../widgets/hr_form_kit.dart';
import '../theme/hr_theme.dart';

class TimesheetView extends StatefulWidget {
  const TimesheetView({super.key});

  @override
  State<TimesheetView> createState() => _TimesheetViewState();
}

class _TimesheetViewState extends State<TimesheetView> {
  bool _showForm = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadTimesheet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    if (_showForm) {
      return TimesheetAddForm(
        onBack: () => setState(() => _showForm = false),
        onSaved: () async {
          setState(() => _showForm = false);
          await ss.loadTimesheet();
        },
      );
    }

    final rows = ss.timesheets.where((t) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return '${t['employee_name']}${t['project_name']}${t['description']}'
          .toLowerCase()
          .contains(q);
    }).toList();

    return HrDataGridPage(
      title: 'Timesheets',
      icon: Icons.schedule_rounded,
      onAdd: () => setState(() => _showForm = true),
      onRefresh: () => ss.loadTimesheet(),
      onSearch: (v) => setState(() => _query = v),
      columns: const [
        'S#',
        'Employee',
        'Project',
        'From',
        'To',
        'Hours',
        'Approval Status',
        '',
      ],
      rows: [
        for (var i = 0; i < rows.length; i++)
          [
            Text('${i + 1}'),
            Text((rows[i]['employee_name'] ?? '').toString()),
            Text((rows[i]['project_name'] ?? '').toString()),
            Text((rows[i]['from_date'] ?? '').toString()),
            Text((rows[i]['to_date'] ?? '').toString()),
            Text('${rows[i]['hours']}'),
            HrStatusPill(
              label: (rows[i]['status'] as num?)?.toInt() == 0
                  ? 'Level 1 Approval Pending'
                  : (rows[i]['status_label'] ?? '').toString(),
              pending: (rows[i]['status'] as num?)?.toInt() == 0,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, size: 18),
              onSelected: (v) async {
                if (rows[i]['can_approve'] != true) return;
                final err = await ss.timesheetAct(v, rows[i]['id'] as int);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err ?? 'Done')),
                );
              },
              itemBuilder: (_) => [
                if (rows[i]['can_approve'] == true) ...[
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                  const PopupMenuItem(value: 'reject', child: Text('Reject')),
                ],
              ],
            ),
          ],
      ],
    );
  }
}

class TimesheetAddForm extends StatefulWidget {
  const TimesheetAddForm({super.key, required this.onBack, required this.onSaved});
  final VoidCallback onBack;
  final Future<void> Function() onSaved;

  @override
  State<TimesheetAddForm> createState() => _TimesheetAddFormState();
}

class _TimesheetAddFormState extends State<TimesheetAddForm> {
  final _hours = TextEditingController(text: '8');
  final _desc = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  bool _saving = false;

  @override
  void dispose() {
    _hours.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HrFormShell(
      moduleTitle: 'Timesheets',
      moduleIcon: Icons.schedule_rounded,
      formTitle: 'Add New Timesheet',
      onBack: widget.onBack,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: _saving ? null : widget.onBack, child: const Text('Cancel')),
          const SizedBox(width: 10),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _saving ? null : _submit,
            child: const Text('Save Timesheet'),
          ),
        ],
      ),
      child: Column(
        children: [
          HrFormSection(
            title: 'Timesheet Information',
            children: [
              HrFormRow(
                label: 'Project',
                required: true,
                child: InputDecorator(
                  decoration: hrFieldDecoration(context, ),
                  child: const Text('Core Operations'),
                ),
              ),
              HrFormRow(
                label: 'Hours',
                required: true,
                child: TextField(
                  controller: _hours,
                  keyboardType: TextInputType.number,
                  style: hrFieldTextStyle(context),
                  decoration: hrFieldDecoration(context, hint: 'Hours'),
                ),
              ),
              HrFormRow(
                label: 'Description',
                child: TextField(
                  controller: _desc,
                  maxLines: 2,
                  style: hrFieldTextStyle(context),
                  decoration: hrFieldDecoration(context, hint: 'Description'),
                ),
              ),
            ],
          ),
          HrFormSection(
            title: 'Period',
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
          firstDate: DateTime.now().subtract(const Duration(days: 90)),
          lastDate: DateTime.now(),
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

  Future<void> _submit() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dates are required')),
      );
      return;
    }
    setState(() => _saving = true);
    final err = await context.read<SelfServiceState>().applyTimesheet({
      'project_id': 1,
      'from_date': DateFormat('yyyy-MM-dd').format(_from!),
      'to_date': DateFormat('yyyy-MM-dd').format(_to!),
      'hours': double.tryParse(_hours.text) ?? 0,
      'description': _desc.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await widget.onSaved();
  }
}
