import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/payroll/payroll_state.dart';
import '../core/uploads/upload_service.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR Payroll Setup — Options, Payslip, Items, Calendar, Banks (API-backed).
class PayrollSetupView extends StatefulWidget {
  const PayrollSetupView({super.key});

  @override
  State<PayrollSetupView> createState() => _PayrollSetupViewState();
}

class _PayrollSetupViewState extends State<PayrollSetupView> {
  late final PayrollState _state;
  String _section = 'Payroll Options';

  static const _sections = [
    'Payroll Options',
    'Payslip Options',
    'Payroll Items',
    'Payroll Calendar',
    'Auto Deductions',
    'Auto Additions',
    'Overtime',
    'Bank Accounts',
    'Company Logo',
  ];

  Color get _accent => HrTheme.brand(context);

  // Local edit buffers
  late Map<String, dynamic> _setup;
  late Map<String, dynamic> _payslip;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _state = PayrollState(context.read<AuthState>());
    _setup = {};
    _payslip = {};
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _state.loadSetupBundle();
      if (!mounted) return;
      setState(() {
        _setup = Map<String, dynamic>.from(_state.setup);
        _payslip = Map<String, dynamic>.from(_state.payslipOptions);
        final logo = context.read<AuthState>().session?.company.logo;
        _logoUrl = AppConfig.resolveMediaUrl(logo);
      });
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);

    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage_outlined, color: HrUi.label(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Payroll Setup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: HrUi.card(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: HrUi.border(context)),
                      ),
                      child: Text(
                        '${_setup['name'] ?? 'General Payroll'}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: HrUi.label(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: HrUi.card(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: HrUi.border(context)),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            for (final s in _sections)
                              InkWell(
                                onTap: () => setState(() => _section = s),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _section == s ? _accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _section == s ? Colors.white : HrUi.label(context),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: HrUi.card(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: HrUi.border(context)),
                          ),
                          child: _state.busy && _setup.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : _body(brand),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(Color brand) {
    switch (_section) {
      case 'Payslip Options':
        return _payslipSection();
      case 'Payroll Items':
        return _itemsSection();
      case 'Payroll Calendar':
        return _calendarSection();
      case 'Auto Deductions':
        return _autoRulesSection(deduction: true);
      case 'Auto Additions':
        return _autoRulesSection(deduction: false);
      case 'Overtime':
        return _overtimeSection();
      case 'Bank Accounts':
        return _banksSection();
      case 'Company Logo':
        return _logoSection();
      default:
        return _optionsSection();
    }
  }

  Widget _optionsSection() {
    return ListView(
      children: [
        _h('Payroll Options'),
        _dd('Payroll Type', '${_setup['payroll_type'] ?? 'Payroll (Pakistan)'}', [
          'Payroll (Pakistan)',
          'Payroll (UAE)',
          'Payroll (UK)',
        ], (v) => setState(() => _setup['payroll_type'] = v)),
        _dd('Pay Schedule', '${_setup['pay_schedule'] ?? 'Monthly (12)'}', [
          'Monthly (12)',
          'Bi-Weekly (26)',
          'Weekly (52)',
        ], (v) => setState(() => _setup['pay_schedule'] = v)),
        _dd('Salaries Per Year', '${_setup['salaries_per_year'] ?? 12}', ['12', '13', '14'],
            (v) => setState(() => _setup['salaries_per_year'] = int.tryParse(v) ?? 12)),
        _dd('Fiscal Year Starting Month', '${_setup['fiscal_start_month'] ?? 'January'}', const [
          'January',
          'April',
          'July',
          'October',
        ], (v) => setState(() => _setup['fiscal_start_month'] = v)),
        _switch('Divide with Number of Days', _setup['divide_with_days'] == true, (v) {
          setState(() => _setup['divide_with_days'] = v);
        }),
        _dd(
          "Employee's Per Day Salary Calculation Method",
          '${_setup['per_day_method'] ?? 'Method 1 - Annual Gross Salary / 365'}',
          const [
            'Method 1 - Annual Gross Salary / 365',
            'Method 2 - Monthly Gross / Working Days',
          ],
          (v) => setState(() => _setup['per_day_method'] = v),
        ),
        _dd(
          'Pro-Rata Salary Calculation Method',
          '${_setup['pro_rata_method'] ?? 'Method 1 - Based on Annual Gross Salary'}',
          const [
            'Method 1 - Based on Annual Gross Salary',
            'Method 2 - Based on Monthly Gross',
          ],
          (v) => setState(() => _setup['pro_rata_method'] = v),
        ),
        _dd(
          'Salary Proration on Exit/Joining',
          '${_setup['exit_join_proration'] ?? 'Prorated Salary'}',
          const ['Prorated Salary', 'Full Month', 'No Proration'],
          (v) => setState(() => _setup['exit_join_proration'] = v),
        ),
        const Divider(height: 28),
        _h('Statutory (PK)'),
        _switch('Enable SESSI', _setup['enable_sessi'] == true, (v) {
          setState(() => _setup['enable_sessi'] = v);
        }),
        _num('SESSI Emp %', '${_setup['sessi_emp_percent'] ?? 1}', (v) {
          _setup['sessi_emp_percent'] = double.tryParse(v) ?? 1;
        }),
        _num('SESSI Org %', '${_setup['sessi_org_percent'] ?? 6}', (v) {
          _setup['sessi_org_percent'] = double.tryParse(v) ?? 6;
        }),
        _switch('Enable Provident Fund', _setup['enable_pf'] == true, (v) {
          setState(() => _setup['enable_pf'] = v);
        }),
        _num('PF Emp %', '${_setup['pf_emp_percent'] ?? 0}', (v) {
          _setup['pf_emp_percent'] = double.tryParse(v) ?? 0;
        }),
        _num('PF Org %', '${_setup['pf_org_percent'] ?? 0}', (v) {
          _setup['pf_org_percent'] = double.tryParse(v) ?? 0;
        }),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              final err = await _state.saveSetup(_setup);
              _toast(err ?? 'Payroll options saved.');
            },
            child: const Text('Save Payroll Options'),
          ),
        ),
      ],
    );
  }

  Widget _payslipSection() {
    return ListView(
      children: [
        _h('Payslip Options'),
        _dd('Payslip Title', '${_payslip['payslip_title'] ?? 'Payslip'}', [
          'Payslip',
          'Salary Slip',
          'Pay Advice',
        ], (v) => setState(() => _payslip['payslip_title'] = v)),
        _dd('Payslip Format', '${_payslip['payslip_format'] ?? 'Standard'}', [
          'Standard',
          'Compact',
          'Detailed',
        ], (v) => setState(() => _payslip['payslip_format'] = v)),
        _dd('Payslip Logo Alignment', '${_payslip['logo_alignment'] ?? 'Left'}', [
          'Left',
          'Center',
          'Right',
        ], (v) => setState(() => _payslip['logo_alignment'] = v)),
        _dd('Approval Levels', '${_payslip['approval_levels'] ?? 0}', ['0', '1', '2', '3'],
            (v) => setState(() => _payslip['approval_levels'] = int.tryParse(v) ?? 0)),
        _switch('Auto Email Payslips', _payslip['auto_email'] == true, (v) {
          setState(() => _payslip['auto_email'] = v);
        }),
        _switch('Add Signature area at bottom', _payslip['add_signature'] == true, (v) {
          setState(() => _payslip['add_signature'] = v);
        }),
        _switch('Show Bank Details', _payslip['show_bank'] == true, (v) {
          setState(() => _payslip['show_bank'] = v);
        }),
        _switch('Show YTD', _payslip['show_ytd'] == true, (v) {
          setState(() => _payslip['show_ytd'] = v);
        }),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              final err = await _state.savePayslipOptions(_payslip);
              _toast(err ?? 'Payslip options saved.');
            },
            child: const Text('Save Payslip Options'),
          ),
        ),
      ],
    );
  }

  Widget _itemsSection() {
    final rows = _state.setupItems;
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: _h('Manage Payroll Items')),
            TextButton(
              onPressed: () {
                context.read<AuthState>(); // keep import warm
                _toast('Use Payroll → Allowances / Deductions masters to add items.');
              },
              child: const Text('Open item masters'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _gridHeader(['S#', 'Item Name', 'Code', 'Category', 'Calc']),
        for (var i = 0; i < rows.length; i++)
          _gridRow([
            '${i + 1}',
            '${rows[i]['name'] ?? ''}',
            '${rows[i]['code'] ?? ''}',
            '${rows[i]['category'] ?? ''}',
            '${rows[i]['calc_type'] ?? ''}',
          ], i.isOdd),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No payroll items — seed 09_phase2_masters.sql', style: TextStyle(color: Colors.grey.shade600)),
          ),
      ],
    );
  }

  Widget _calendarSection() {
    final rows = _state.calendars;
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: _h('Manage Payroll Calendars')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () => _dialogCalendar(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Payroll Calendar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _gridHeader(['S#', 'Year', 'Start Date', 'End Date', 'Pay Periods', '']),
        for (var i = 0; i < rows.length; i++)
          _gridRow([
            '${i + 1}',
            '${rows[i]['year']}',
            '${rows[i]['start_date']}',
            '${rows[i]['end_date']}',
            '${rows[i]['pay_periods']}',
            'edit',
          ], i.isOdd, onEdit: () => _dialogCalendar(rows[i])),
      ],
    );
  }

  Future<void> _dialogCalendar([Map<String, dynamic>? row]) async {
    final year = TextEditingController(text: '${row?['year'] ?? DateTime.now().year}');
    final start = TextEditingController(text: '${row?['start_date'] ?? '${DateTime.now().year}-01-01'}');
    final end = TextEditingController(text: '${row?['end_date'] ?? '${DateTime.now().year}-12-31'}');
    final periods = TextEditingController(text: '${row?['pay_periods'] ?? 12}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(row == null ? 'Add Calendar' : 'Edit Calendar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: year, decoration: const InputDecoration(labelText: 'Year')),
            TextField(controller: start, decoration: const InputDecoration(labelText: 'Start Date')),
            TextField(controller: end, decoration: const InputDecoration(labelText: 'End Date')),
            TextField(controller: periods, decoration: const InputDecoration(labelText: 'Pay Periods')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final err = await _state.saveCalendar({
      'year': int.tryParse(year.text) ?? DateTime.now().year,
      'start_date': start.text.trim(),
      'end_date': end.text.trim(),
      'pay_periods': int.tryParse(periods.text) ?? 12,
      'label': 'FY ${year.text}',
    }, id: (row?['id'] as num?)?.toInt());
    _toast(err ?? 'Calendar saved.');
  }

  Widget _overtimeSection() {
    return ListView(
      children: [
        _h('Overtime'),
        Text(
          'Approved overtime entries (Timesheet → Overtime master) are applied automatically '
          'during Process Salary: hours × (basic÷30÷8) × multiplier.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        const SizedBox(height: 16),
        _switch('Enable Auto Overtime for Salaried Employees', _setup['enable_auto_overtime'] == true, (v) {
          setState(() => _setup['enable_auto_overtime'] = v);
        }),
        const Divider(height: 28),
        _h('Late Attendance'),
        Text(
          'Punch-in late minutes are matched to Auto Deduction bands during Process Salary.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        const SizedBox(height: 12),
        _switch('Enable Auto Late Deductions', _setup['enable_auto_late'] != false, (v) {
          setState(() => _setup['enable_auto_late'] = v);
        }),
        _dd('Work Start Time', '${_setup['work_start_time'] ?? '09:00:00'}', const [
          '08:00:00',
          '08:30:00',
          '09:00:00',
          '09:30:00',
          '10:00:00',
        ], (v) => setState(() => _setup['work_start_time'] = v)),
        _num('Late Grace Minutes', '${_setup['late_grace_minutes'] ?? 15}', (v) {
          _setup['late_grace_minutes'] = int.tryParse(v) ?? 15;
        }),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              final err = await _state.saveSetup(_setup);
              _toast(err ?? 'Overtime / late options saved.');
            },
            child: const Text('Save Auto Overtime'),
          ),
        ),
      ],
    );
  }

  Widget _autoRulesSection({required bool deduction}) {
    final path = deduction ? '/payroll/auto-deductions' : '/payroll/auto-additions';
    return _AutoRulesPanel(
      title: deduction ? 'Auto Deductions' : 'Auto Additions',
      accent: _accent,
      loadPath: path,
      savePath: path,
      deletePath: path,
      token: () async => context.read<AuthState>().session?.token,
      onToast: _toast,
    );
  }

  Widget _banksSection() {
    final rows = _state.banks;
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: _h('Company Bank Accounts')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () => _dialogBank(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Record'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _gridHeader(['S#', 'Bank Name', 'Account Number', 'Primary', '']),
        for (var i = 0; i < rows.length; i++)
          _gridRow([
            '${i + 1}',
            '${rows[i]['bank_name']}',
            '${rows[i]['account_number']}',
            rows[i]['is_primary'] == true ? 'Yes' : 'No',
            'edit',
          ], i.isOdd, onEdit: () => _dialogBank(rows[i])),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No record found.', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _dialogBank([Map<String, dynamic>? row]) async {
    final name = TextEditingController(text: '${row?['bank_name'] ?? ''}');
    final acct = TextEditingController(text: '${row?['account_number'] ?? ''}');
    final title = TextEditingController(text: '${row?['account_title'] ?? ''}');
    var primary = row?['is_primary'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(row == null ? 'Add Bank' : 'Edit Bank'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Bank Name')),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Account Title')),
              TextField(controller: acct, decoration: const InputDecoration(labelText: 'Account Number')),
              SwitchListTile(
                title: const Text('Primary Account'),
                value: primary,
                activeColor: _accent,
                onChanged: (v) => setLocal(() => primary = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final err = await _state.saveBank({
      'bank_name': name.text.trim(),
      'account_title': title.text.trim(),
      'account_number': acct.text.trim(),
      'is_primary': primary,
    }, id: (row?['id'] as num?)?.toInt());
    _toast(err ?? 'Bank saved.');
  }

  Widget _logoSection() {
    return ListView(
      children: [
        _h('Company Logo'),
        Text(
          'Shown on login card context and payslips. JPG/PNG up to 4MB.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _logoUrl != null && _logoUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(_logoUrl!), fit: BoxFit.contain)
                      : null,
                ),
                child: _logoUrl == null || _logoUrl!.isEmpty
                    ? Icon(Icons.business, size: 64, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _accent),
                onPressed: () async {
                  final up = UploadService(context.read<AuthState>());
                  final r = await up.pickAndUploadCompanyLogo();
                  if (r.error != null) {
                    _toast(r.error!);
                    return;
                  }
                  if (r.url != null) {
                    setState(() => _logoUrl = r.url);
                    _toast('Company logo updated.');
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text('Upload Company Logo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context))),
      );

  Widget _dd(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    final safe = items.contains(value) ? value : items.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: HrUi.muted(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: safe,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F3F3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: HrUi.label(context)))),
          Switch(value: value, activeColor: _accent, onChanged: onChanged),
          Text(value ? 'On' : 'Off', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _num(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: TextFormField(
              initialValue: value,
              keyboardType: TextInputType.number,
              onChanged: onChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridHeader(List<String> cols) {
    return Container(
      color: _accent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (final c in cols)
            Expanded(
              flex: c.isEmpty ? 1 : 2,
              child: Text(c, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _gridRow(List<String> cols, bool odd, {VoidCallback? onEdit}) {
    return Container(
      color: odd ? const Color(0xFFF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (var i = 0; i < cols.length; i++)
            Expanded(
              flex: cols[i].isEmpty || cols[i] == 'edit' ? 1 : 2,
              child: cols[i] == 'edit'
                  ? IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: onEdit,
                    )
                  : Text(cols[i], style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _AutoRulesPanel extends StatefulWidget {
  const _AutoRulesPanel({
    required this.title,
    required this.accent,
    required this.loadPath,
    required this.savePath,
    required this.deletePath,
    required this.token,
    required this.onToast,
  });

  final String title;
  final Color accent;
  final String loadPath;
  final String savePath;
  final String deletePath;
  final Future<String?> Function() token;
  final void Function(String) onToast;

  @override
  State<_AutoRulesPanel> createState() => _AutoRulesPanelState();
}

class _AutoRulesPanelState extends State<_AutoRulesPanel> {
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true;

  ApiClient get _api => ApiClient(tokenProvider: widget.token);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final res = await _api.dio.get(widget.loadPath);
      final d = res.data;
      if (d is Map && d['success'] == true) {
        _rows = ((d['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addRow() async {
    final from = TextEditingController(text: '0');
    final to = TextEditingController(text: '15');
    final amt = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${widget.title} Row'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: from, decoration: const InputDecoration(labelText: 'Minutes From')),
            TextField(controller: to, decoration: const InputDecoration(labelText: 'Minutes To')),
            TextField(controller: amt, decoration: const InputDecoration(labelText: 'Amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: widget.accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _api.dio.post(widget.savePath, data: {
      'minutes_from': int.tryParse(from.text) ?? 0,
      'minutes_to': int.tryParse(to.text) ?? 0,
      'amount': double.tryParse(amt.text) ?? 0,
      'amount_type': 'Specified Amount',
      'method': 'Fixed Amount',
    });
    widget.onToast('Row saved.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    return ListView(
      children: [
        Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context))),
        const SizedBox(height: 8),
        Text(
          'Late / early minute bands used when attendance auto rules are enabled in process.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          color: widget.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: const Row(
            children: [
              Expanded(child: Text('Minutes (From)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(child: Text('Minutes (To)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(child: Text('Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(child: Text('Method', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
              Expanded(child: Text('Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
            ],
          ),
        ),
        for (var i = 0; i < _rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: i.isOdd ? const Color(0xFFF9FAFB) : Colors.white,
            child: Row(
              children: [
                Expanded(child: Text('${_rows[i]['minutes_from']}')),
                Expanded(child: Text('${_rows[i]['minutes_to']}')),
                Expanded(child: Text('${_rows[i]['amount_type']}', overflow: TextOverflow.ellipsis)),
                Expanded(child: Text('${_rows[i]['method']}', overflow: TextOverflow.ellipsis)),
                Expanded(child: Text('${_rows[i]['amount']}')),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: widget.accent),
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('+ Add New Row'),
          ),
        ),
      ],
    );
  }
}
