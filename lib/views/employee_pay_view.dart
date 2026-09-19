import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR-style Employee Salary: Salary / Tax / Payment / Allocation / Banks.
class EmployeePayView extends StatefulWidget {
  const EmployeePayView({super.key});

  @override
  State<EmployeePayView> createState() => _EmployeePayViewState();
}

class _EmployeePayViewState extends State<EmployeePayView> {
  late final EmployeeState _emps;
  int? _employeeId;
  String _tab = 'Salary';
  Map<String, dynamic> _pay = {};
  List<Map<String, dynamic>> _banks = [];
  String? _empName;
  bool _busy = false;

  Color get _accent => HrTheme.brand(context);
  static const _tabs = [
    'Salary',
    'Tax',
    'Payment Method',
    'Salary Allocation',
    'Bank Accounts',
  ];

  @override
  void initState() {
    super.initState();
    _emps = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _emps.load();
      if (!mounted || _emps.rows.isEmpty) return;
      await _select((_emps.rows.first['employee_id'] as num).toInt());
    });
  }

  @override
  void dispose() {
    _emps.dispose();
    super.dispose();
  }

  ApiClient get _api =>
      ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);

  Future<void> _select(int id) async {
    setState(() {
      _employeeId = id;
      _busy = true;
    });
    try {
      final res = await _api.dio.get('/employees/$id/pay');
      final d = res.data;
      if (d is Map && d['success'] == true) {
        _pay = asStringKeyedMap(d['pay']);
        _banks = ((d['banks'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        final emp = asStringKeyedMap(d['employee']);
        _empName = '${emp['name']}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _save() async {
    if (_employeeId == null) return;
    setState(() => _busy = true);
    try {
      final res = await _api.dio.post('/employees/$_employeeId/pay', data: _pay);
      final d = res.data;
      final msg = (d is Map && d['success'] == true) ? 'Saved.' : ((d is Map ? d['message'] : null) ?? 'Failed');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _emps,
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
                    Icon(Icons.payments_outlined, color: HrUi.label(context)),
                    const SizedBox(width: 8),
                    Text('Employee Salary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HrUi.label(context))),
                    const Spacer(),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<int>(
                        value: _employeeId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _emps.rows.map((e) {
                          final id = (e['employee_id'] as num).toInt();
                          return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) _select(v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_empName != null)
                  Text(_empName!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300)),
                const SizedBox(height: 12),
                Expanded(
                  child: _busy && _pay.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 180,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: HrUi.border(context)),
                              ),
                              child: ListView(
                                padding: const EdgeInsets.all(8),
                                children: [
                                  for (final t in _tabs)
                                    InkWell(
                                      onTap: () => setState(() => _tab = t),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _tab == t ? _accent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          t,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: _tab == t ? Colors.white : HrUi.label(context),
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: HrUi.border(context)),
                                ),
                                child: _tabBody(),
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

  Widget _tabBody() {
    switch (_tab) {
      case 'Tax':
        return _taxTab();
      case 'Payment Method':
        return _paymentTab();
      case 'Salary Allocation':
        return _allocTab();
      case 'Bank Accounts':
        return _banksTab();
      default:
        return _salaryTab();
    }
  }

  Widget _salaryTab() {
    return ListView(
      children: [
        _h('Salary'),
        _field('Payroll Setup', _dd(_pay['payroll_setup']?.toString() ?? 'General Payroll', [
          'General Payroll',
        ], (v) => setState(() => _pay['payroll_setup'] = v))),
        _field('Salary Type', _dd(_pay['salary_type']?.toString() ?? 'Salary', [
          'Salary',
          'Hourly',
        ], (v) => setState(() => _pay['salary_type'] = v))),
        _field('Currency', _dd(_pay['currency']?.toString() ?? 'PKR', ['PKR', 'USD', 'AED'],
            (v) => setState(() => _pay['currency'] = v))),
        _num('Hours Per Week', 'hours_per_week'),
        _num('Annual Salary', 'annual_salary'),
        _num('Gross Salary', 'gross_salary'),
        _num('Hourly Salary', 'hourly_salary'),
        _num('Overtime Hourly Salary', 'ot_hourly_salary'),
        _num('Bonus Entitlement', 'bonus_entitlement'),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent),
          onPressed: _busy ? null : _save,
          child: const Text('Save Salary'),
        ),
      ],
    );
  }

  Widget _taxTab() {
    return ListView(
      children: [
        _h('Tax'),
        _field('Residency Status', _dd(_pay['residency_status']?.toString() ?? 'Resident', [
          'Resident',
          'Non-Resident',
        ], (v) => setState(() => _pay['residency_status'] = v))),
        SwitchListTile(
          title: const Text('Exclude Employee from Tax'),
          value: _pay['exclude_from_tax'] == true,
          activeColor: _accent,
          onChanged: (v) => setState(() => _pay['exclude_from_tax'] = v),
        ),
        _h('Previous Tax Info'),
        _num('Previous Months', 'prev_months'),
        _num('Previous Taxable Salary', 'prev_taxable'),
        _num('Previous Tax', 'prev_tax'),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent),
          onPressed: _busy ? null : _save,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _paymentTab() {
    return ListView(
      children: [
        _h('Payment Method'),
        _field(
          'Payment Method',
          _dd(_pay['payment_method']?.toString() ?? 'Manual', [
            'Manual',
            'Direct Deposit',
            'Cheque',
            'Cash',
          ], (v) => setState(() => _pay['payment_method'] = v)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent),
          onPressed: _busy ? null : _save,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _allocTab() {
    return ListView(
      children: [
        _h('Salary Allocation'),
        _field(
          'Salary Allocation By',
          _dd(_pay['salary_allocation_by']?.toString() ?? '—', [
            '—',
            'Company',
            'Division',
            'Station',
            'Department',
          ], (v) => setState(() => _pay['salary_allocation_by'] = v == '—' ? null : v)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _accent),
          onPressed: _busy ? null : _save,
          child: const Text('Save Salary Allocation'),
        ),
      ],
    );
  }

  Widget _banksTab() {
    return ListView(
      children: [
        Row(
          children: [
            Expanded(child: _h('Manage Employee Bank Accounts')),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _accent),
              onPressed: _addBank,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Record'),
            ),
          ],
        ),
        Container(
          color: _accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: const Row(
            children: [
              Expanded(child: Text('S#', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Bank Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Account Number', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Primary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        if (_banks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No record found.', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
        else
          for (var i = 0; i < _banks.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: i.isOdd ? const Color(0xFFF9FAFB) : Colors.white,
              child: Row(
                children: [
                  Expanded(child: Text('${i + 1}')),
                  Expanded(flex: 2, child: Text('${_banks[i]['bank_name']}')),
                  Expanded(flex: 2, child: Text('${_banks[i]['account_number']}')),
                  Expanded(child: Text(_banks[i]['is_primary'] == true ? 'Yes' : 'No')),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _addBank() async {
    if (_employeeId == null) return;
    final name = TextEditingController();
    final acct = TextEditingController();
    var primary = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setL) => AlertDialog(
          title: const Text('Add Bank'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Bank Name')),
              TextField(controller: acct, decoration: const InputDecoration(labelText: 'Account Number')),
              SwitchListTile(
                title: const Text('Primary'),
                value: primary,
                onChanged: (v) => setL(() => primary = v),
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
    await _api.dio.post('/employees/$_employeeId/banks', data: {
      'bank_name': name.text.trim(),
      'account_number': acct.text.trim(),
      'is_primary': primary,
    });
    await _select(_employeeId!);
  }

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context))),
      );

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _dd(String value, List<String> items, ValueChanged<String> onChanged) {
    final safe = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: safe,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _num(String label, String key) {
    return _field(
      label,
      TextFormField(
        initialValue: '${_pay[key] ?? 0}',
        keyboardType: TextInputType.number,
        onChanged: (v) => _pay[key] = double.tryParse(v) ?? 0,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          isDense: true,
        ),
      ),
    );
  }
}
