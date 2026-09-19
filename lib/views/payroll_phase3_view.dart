import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/payroll/payroll_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

final _pkr = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

/// Payroll dashboard + process salary runs.
class PayrollProcessView extends StatefulWidget {
  const PayrollProcessView({super.key});

  @override
  State<PayrollProcessView> createState() => _PayrollProcessViewState();
}

class _PayrollProcessViewState extends State<PayrollProcessView> {
  late final PayrollState _ps;
  int? _projectId;
  DateTime _date = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _ps = PayrollState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ps.loadMeta();
      await _ps.loadDashboard();
      await _ps.loadRuns();
    });
  }

  @override
  void dispose() {
    _ps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ps,
      builder: (context, _) {
        final s = _ps.stats;
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Payroll Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: HrUi.label(context),
                  )),
              if (_ps.error != null) ...[
                const SizedBox(height: 8),
                Text(_ps.error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _stat('Defined structures', '${s['defined_structures'] ?? 0}', Icons.account_tree),
                  _stat('Processed this month', '${s['processed_this_month'] ?? 0}', Icons.done_all),
                  _stat('Month gross', _pkr.format((s['month_gross'] as num?)?.toDouble() ?? 0), Icons.payments),
                  _stat('Month net', _pkr.format((s['month_net'] as num?)?.toDouble() ?? 0), Icons.account_balance_wallet),
                  _stat('Month tax', _pkr.format((s['month_tax'] as num?)?.toDouble() ?? 0), Icons.receipt_long),
                ],
              ),
              const SizedBox(height: 24),
              Text('Run monthly process',
                  style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HrUi.card(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HrUi.border(context)),
                ),
                child: Column(
                  children: [
                    HrFormRow(
                      label: 'Project',
                      child: DropdownButtonFormField<int>(
                        value: _projectId,
                        items: [
                          for (final p in _ps.projects)
                            DropdownMenuItem(
                              value: (p['id'] as num?)?.toInt(),
                              child: Text('${p['label']}'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _projectId = v),
                        decoration: hrFieldDecoration(context, hint: 'Select project'),
                      ),
                    ),
                    HrFormRow(
                      label: 'Pay date',
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (d != null) setState(() => _date = d);
                        },
                        child: InputDecorator(
                          decoration: hrFieldDecoration(context),
                          child: Text(DateFormat('yyyy-MM-dd').format(_date)),
                        ),
                      ),
                    ),
                    HrFormRow(
                      label: 'Days',
                      child: TextFormField(
                        initialValue: '$_days',
                        keyboardType: TextInputType.number,
                        decoration: hrFieldDecoration(context),
                        onChanged: (v) => _days = int.tryParse(v) ?? 30,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _ps.busy ? null : _showSalaryStructure,
                            icon: const Icon(Icons.account_tree_outlined, size: 18),
                            label: const Text('Salary Structure'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _ps.busy ? null : _showSalarySheet,
                            icon: const Icon(Icons.table_chart_outlined, size: 18),
                            label: const Text('Salary Sheet'),
                          ),
                          FilledButton.icon(
                            style: HrTheme.filledButton(context),
                            onPressed: _ps.busy ? null : _run,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Process Salary'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recent payslips',
                  style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
              const SizedBox(height: 8),
              ..._ps.runs.take(30).map((r) => ListTile(
                    tileColor: HrUi.card(context),
                    title: Text('${r['employee_name']} · ${r['project_name']}'),
                    subtitle: Text(
                      '${r['date']} · Net ${_pkr.format((r['net_salary'] as num?)?.toDouble() ?? 0)}'
                      ' · Tax ${_pkr.format((r['tax_amount'] as num?)?.toDouble() ?? 0)}',
                    ),
                    trailing: TextButton(
                      onPressed: () => _showPayslip((r['id'] as num).toInt()),
                      child: const Text('Payslip'),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: HrTheme.brand(context)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: HrUi.muted(context))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
        ],
      ),
    );
  }

  Future<void> _run() async {
    if (_projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a project')),
      );
      return;
    }
    final err = await _ps.processRun(
      projectId: _projectId!,
      date: DateFormat('yyyy-MM-dd').format(_date),
      days: _days,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Payroll processed'),
        backgroundColor: err == null ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
  }

  Future<void> _showSalaryStructure() async {
    try {
      final api = _ps; // reuse
      await api.loadDefines();
      if (!mounted) return;
      final rows = api.defines;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Salary Structure'),
          content: SizedBox(
            width: 640,
            height: 400,
            child: rows.isEmpty
                ? const Text('No define-salary records.')
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Employee')),
                        DataColumn(label: Text('Project')),
                        DataColumn(label: Text('Basic')),
                        DataColumn(label: Text('Gross')),
                        DataColumn(label: Text('Net')),
                      ],
                      rows: [
                        for (final r in rows)
                          DataRow(cells: [
                            DataCell(Text('${r['employee_name'] ?? ''}')),
                            DataCell(Text('${r['project_name'] ?? ''}')),
                            DataCell(Text(_pkr.format((r['basic_salary'] as num?)?.toDouble() ?? 0))),
                            DataCell(Text(_pkr.format((r['total_allowance'] as num?)?.toDouble() ?? 0))),
                            DataCell(Text(_pkr.format((r['net_salary'] as num?)?.toDouble() ?? 0))),
                          ]),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showSalarySheet() async {
    final sheet = await _ps.loadSalarySheet(
      date: DateFormat('yyyy-MM-dd').format(_date),
      projectId: _projectId,
    );
    if (!mounted) return;
    if (sheet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ps.error ?? 'Could not load salary sheet')),
      );
      return;
    }
    final rows = ((sheet['rows'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final totals = Map<String, dynamic>.from(sheet['totals'] as Map? ?? {});
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salary Sheet'),
        content: SizedBox(
          width: 640,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Employees: ${totals['count'] ?? 0} · Gross ${_pkr.format((totals['gross'] as num?)?.toDouble() ?? 0)} · '
                'Net ${_pkr.format((totals['net'] as num?)?.toDouble() ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Employee')),
                      DataColumn(label: Text('Gross')),
                      DataColumn(label: Text('Tax')),
                      DataColumn(label: Text('Net')),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(cells: [
                          DataCell(Text('${r['employee_name'] ?? ''}')),
                          DataCell(Text(_pkr.format((r['total_allowance'] as num?)?.toDouble() ?? 0))),
                          DataCell(Text(_pkr.format((r['tax_amount'] as num?)?.toDouble() ?? 0))),
                          DataCell(Text(_pkr.format((r['net_salary'] as num?)?.toDouble() ?? 0))),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showPayslip(int id) async {
    final err = await _ps.loadPayslip(id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final p = _ps.payslip!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payslip — ${p['employee']?['name'] ?? ''}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p['company']?['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Period: ${p['period_date']} · Days: ${p['days']}'),
                Text('Designation: ${p['employee']?['designation'] ?? '—'}'),
                Text('Project: ${p['project']}'),
                const Divider(),
                Text('Gross: ${_pkr.format((p['total_allowance'] as num?)?.toDouble() ?? 0)}'),
                Text('Tax: ${_pkr.format((p['tax_amount'] as num?)?.toDouble() ?? 0)}'),
                Text('EOBI: ${_pkr.format((p['eobi_amount'] as num?)?.toDouble() ?? 0)}'),
                Text('Deductions: ${_pkr.format((p['total_deduction'] as num?)?.toDouble() ?? 0)}'),
                Text('Net: ${_pkr.format((p['net_salary'] as num?)?.toDouble() ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Divider(),
                for (final line in ((p['lines'] as List?) ?? []))
                  Text(
                    '${line['item']}: +${line['allowance']} / -${line['deduction']}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final token = context.read<AuthState>().session?.token ?? '';
              final uri = Uri.parse(
                '${AppConfig.apiBaseUrl}/payroll/payslip/$id/print'
                '?access_token=${Uri.encodeQueryComponent(token)}',
              );
              final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Open manually: $uri')),
                );
              }
            },
            child: const Text('Print / PDF'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

/// Define salary structures (per employee + project).
class PayrollDefineView extends StatefulWidget {
  const PayrollDefineView({super.key});

  @override
  State<PayrollDefineView> createState() => _PayrollDefineViewState();
}

class _PayrollDefineViewState extends State<PayrollDefineView> {
  late final PayrollState _ps;
  bool _form = false;
  int? _editId;
  int? _employeeId;
  int? _projectId;
  int? _stationId;
  final _basic = TextEditingController(text: '0');
  final Map<int, TextEditingController> _allow = {};
  final Map<int, TextEditingController> _deduct = {};

  @override
  void initState() {
    super.initState();
    _ps = PayrollState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ps.loadMeta();
      await _ps.loadDefines();
    });
  }

  @override
  void dispose() {
    _basic.dispose();
    for (final c in [..._allow.values, ..._deduct.values]) {
      c.dispose();
    }
    _ps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ps,
      builder: (context, _) {
        if (_form) return _buildForm();
        return HrDataGridPage(
          title: 'Define Salary',
          icon: Icons.payments_outlined,
          onAdd: _openForm,
          onRefresh: () => _ps.loadDefines(),
          columns: const [
            'S#',
            'Employee',
            'Project',
            'Station',
            'Basic',
            'Allowances',
            'Deductions',
            'Net',
            '',
          ],
          rows: [
            for (var i = 0; i < _ps.defines.length; i++)
              [
                Text('${i + 1}'),
                Text('${_ps.defines[i]['employee_name']}'),
                Text('${_ps.defines[i]['project_name']}'),
                Text('${_ps.defines[i]['station_name']}'),
                Text(_pkr.format((_ps.defines[i]['basic_salary'] as num?)?.toDouble() ?? 0)),
                Text(_pkr.format((_ps.defines[i]['total_allowance'] as num?)?.toDouble() ?? 0)),
                Text(_pkr.format((_ps.defines[i]['total_deduction'] as num?)?.toDouble() ?? 0)),
                Text(_pkr.format((_ps.defines[i]['net_salary'] as num?)?.toDouble() ?? 0)),
                PopupMenuButton<String>(
                  onSelected: (a) async {
                    final id = (_ps.defines[i]['id'] as num).toInt();
                    if (a == 'edit') {
                      _openForm(row: _ps.defines[i]);
                    } else if (a == 'delete') {
                      final err = await _ps.deleteDefine(id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err ?? 'Deleted')));
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
      },
    );
  }

  void _openForm({Map<String, dynamic>? row}) {
    _editId = (row?['id'] as num?)?.toInt();
    _employeeId = (row?['employee_id'] as num?)?.toInt();
    _projectId = (row?['project_id'] as num?)?.toInt();
    _stationId = (row?['station_id'] as num?)?.toInt();
    _basic.text = '${row?['basic_salary'] ?? 0}';
    for (final c in [..._allow.values, ..._deduct.values]) {
      c.dispose();
    }
    _allow.clear();
    _deduct.clear();
    for (final it in _ps.items) {
      final id = (it['id'] as num?)?.toInt();
      if (id == null) continue;
      final cat = '${it['category']}';
      if (cat == 'allowance' || cat == 'earning' || cat == 'bonus') {
        _allow[id] = TextEditingController(text: '0');
      } else if (cat == 'deduction') {
        _deduct[id] = TextEditingController(text: '0');
      }
    }
    setState(() => _form = true);
  }

  Widget _buildForm() {
    return HrFormShell(
      moduleTitle: 'Define Salary',
      moduleIcon: Icons.payments_outlined,
      formTitle: _editId == null ? 'Add Salary Structure' : 'Edit Salary Structure',
      onBack: () => setState(() => _form = false),
      footer: Row(
        children: [
          OutlinedButton(onPressed: () => setState(() => _form = false), child: const Text('Cancel')),
          const Spacer(),
          FilledButton(style: HrTheme.filledButton(context), onPressed: _save, child: const Text('Save')),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Salary is per employee + project (SCF rule). Tax & EOBI apply at process time.',
            style: TextStyle(color: HrUi.muted(context), fontSize: 12),
          ),
          const SizedBox(height: 12),
          HrFormRow(
            label: 'Employee',
            child: DropdownButtonFormField<int>(
              value: _employeeId,
              items: [
                for (final e in _ps.employees)
                  DropdownMenuItem(value: (e['id'] as num?)?.toInt(), child: Text('${e['label']}')),
              ],
              onChanged: (v) => setState(() => _employeeId = v),
              decoration: hrFieldDecoration(context),
            ),
          ),
          HrFormRow(
            label: 'Project',
            child: DropdownButtonFormField<int>(
              value: _projectId,
              items: [
                for (final p in _ps.projects)
                  DropdownMenuItem(value: (p['id'] as num?)?.toInt(), child: Text('${p['label']}')),
              ],
              onChanged: (v) => setState(() => _projectId = v),
              decoration: hrFieldDecoration(context),
            ),
          ),
          HrFormRow(
            label: 'Station',
            child: DropdownButtonFormField<int>(
              value: _stationId,
              items: [
                for (final s in _ps.stations)
                  DropdownMenuItem(value: (s['id'] as num?)?.toInt(), child: Text('${s['label']}')),
              ],
              onChanged: (v) => setState(() => _stationId = v),
              decoration: hrFieldDecoration(context),
            ),
          ),
          HrFormRow(
            label: 'Basic salary',
            child: TextField(
              controller: _basic,
              keyboardType: TextInputType.number,
              decoration: hrFieldDecoration(context),
            ),
          ),
          const SizedBox(height: 8),
          Text('Allowances / Earnings', style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
          for (final e in _allow.entries)
            HrFormRow(
              label: _itemName(e.key),
              child: TextField(
                controller: e.value,
                keyboardType: TextInputType.number,
                decoration: hrFieldDecoration(context),
              ),
            ),
          Text('Deductions', style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
          for (final e in _deduct.entries)
            HrFormRow(
              label: _itemName(e.key),
              child: TextField(
                controller: e.value,
                keyboardType: TextInputType.number,
                decoration: hrFieldDecoration(context),
              ),
            ),
        ],
      ),
    );
  }

  String _itemName(int id) {
    for (final it in _ps.items) {
      if ((it['id'] as num?)?.toInt() == id) {
        return '${it['name']}';
      }
    }
    return '$id';
  }

  Future<void> _save() async {
    if (_employeeId == null || _projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee and project are required')),
      );
      return;
    }
    final basic = double.tryParse(_basic.text) ?? 0;
    final items = <Map<String, dynamic>>[];
    Map<String, dynamic>? basicItem;
    for (final i in _ps.items) {
      if (i['code'] == 'BASIC') {
        basicItem = i;
        break;
      }
    }
    if (basicItem != null) {
      items.add({
        'payroll_item_id': (basicItem['id'] as num).toInt(),
        'allowance': basic,
        'deduction': 0,
      });
    }
    for (final e in _allow.entries) {
      final v = double.tryParse(e.value.text) ?? 0;
      if (v == 0) continue;
      items.add({'payroll_item_id': e.key, 'allowance': v, 'deduction': 0});
    }
    for (final e in _deduct.entries) {
      final v = double.tryParse(e.value.text) ?? 0;
      if (v == 0) continue;
      items.add({'payroll_item_id': e.key, 'allowance': 0, 'deduction': v});
    }
    final err = await _ps.saveDefine({
      'employee_id': _employeeId,
      'project_id': _projectId,
      'station_id': _stationId ?? 1,
      'basic_salary': basic,
      'items': items,
    }, id: _editId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Saved'),
        backgroundColor: err == null ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
    if (err == null) setState(() => _form = false);
  }
}
