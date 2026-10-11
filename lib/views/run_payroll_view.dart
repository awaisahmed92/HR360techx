import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../widgets/hr_form_kit.dart';
import '../core/auth/auth_state.dart';
import '../core/payroll/payroll_state.dart';
import '../core/util/json_maps.dart';

/// Run Payroll matches the process form, pay period, and payslip preview.
/// Station, department, and designation filters are sent when salaries are generated.
class RunPayrollView extends StatefulWidget {
  const RunPayrollView({super.key});

  @override
  State<RunPayrollView> createState() => _RunPayrollViewState();
}

class _RunPayrollViewState extends State<RunPayrollView> {
  late final PayrollState _ps;
  String? _country;
  String? _setupName;
  List<int> _users = [];
  List<int> _exempt = [];
  List<String> _embassies = [];
  List<int> _clients = [];
  List<int> _stations = [];
  List<int> _departments = [];
  List<int> _designations = [];
  String _userType = 'All User Types';
  String _userCategory = 'All User Categories';
  String _cycle = 'Regular';
  String? _sortBy;
  List<String> _extraFields = [];
  List<String> _hiddenFields = [];
  List<String> _customFields = [];
  List<String> _itemTypes = [];
  DateTime? _deductStart;
  DateTime? _deductEnd;
  bool _excludeBasic = false;
  bool _excludeDeductions = false;
  bool _showZero = false;
  bool _checkDuplicate = true;
  late DateTime _payDate;
  late DateTime _period;
  List<Map<String, dynamic>> _rows = [];
  final Map<int, TextEditingController> _notes = {};
  int? _openId;
  String? _note;

  static const _brown = Color(0xFFB08968);
  static const _field = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _payDate = now;
    _period = DateTime(now.year, now.month);
    _ps = PayrollState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _ps.loadMeta());
  }

  @override
  void dispose() {
    for (final note in _notes.values) {
      note.dispose();
    }
    _ps.dispose();
    super.dispose();
  }

  String get _currency {
    final company = context.read<AuthState>().company?.currency ?? '';
    if (company.isNotEmpty) return company;
    return (_ps.stats['currency'] ?? 'USD').toString();
  }

  String _money(num? value) => NumberFormat.decimalPattern().format(value ?? 0);

  List<Map<String, dynamic>> get _countries =>
      ((_ps.meta['countries'] as List?) ?? []).map(asStringKeyedMap).toList();

  List<Map<String, dynamic>> get _employees =>
      ((_ps.meta['employees'] as List?) ?? []).map(asStringKeyedMap).toList();

  List<Map<String, dynamic>> get _stationOptions =>
      ((_ps.meta['stations'] as List?) ?? []).map(asStringKeyedMap).toList();

  List<Map<String, dynamic>> get _departmentOptions =>
      ((_ps.meta['departments'] as List?) ?? []).map(asStringKeyedMap).toList();

  List<Map<String, dynamic>> get _designationOptions =>
      ((_ps.meta['designations'] as List?) ?? []).map(asStringKeyedMap).toList();

  List<Map<String, dynamic>> get _clientOptions =>
      ((_ps.meta['projects'] as List?) ?? []).map(asStringKeyedMap).toList();

  List<String> get _setupNames {
    final setup = asStringKeyedMap(_ps.meta['setup']);
    final saved = '${setup['payroll_type'] ?? ''}'.trim();
    return [
      if (saved.isNotEmpty) saved,
      'General Payroll',
      'Project Based Setup',
    ];
  }

  Map<String, dynamic> get _body => {
        'country': _country,
        'employee_ids': _users,
        'exclude_ids': _exempt,
        'embassy_codes': _embassies,
        'project_ids': _clients,
        'station_ids': _stations,
        'department_ids': _departments,
        'designation_ids': _designations,
        'date': DateFormat('yyyy-MM-dd').format(DateTime(_period.year, _period.month + 1, 0)),
        'days': DateTime(_period.year, _period.month + 1, 0).day,
      };

  String _rangeLabel(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1, 0);
    return '${DateFormat('MMMM d, y').format(start)}-${DateFormat('MMMM d, y').format(end)}';
  }

  Future<void> _preview() async {
    setState(() => _note = null);
    try {
      final rows = await _ps.previewRun(_body);
      if (!mounted) return;
      for (final note in _notes.values) {
        note.dispose();
      }
      _notes.clear();
      for (final row in rows) {
        final id = (row['id'] as num?)?.toInt() ?? 0;
        _notes[id] = TextEditingController();
      }
      setState(() {
        _rows = rows;
        _openId = null;
        _note = rows.isEmpty
            ? 'No defined salaries match this station, department, or designation. Open Define Salary, then preview again.'
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => _note = 'Preview failed. $e');
    }
  }

  Future<void> _generate() async {
    final err = await _ps.generateRun(_body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Payslips generated for the selected filters.')),
    );
  }

  List<Map<String, dynamic>> get _visible {
    final rows = [
      for (final row in _rows)
        if (_showZero || ((row['net'] as num?) ?? 0) != 0) row,
    ];
    final key = switch (_sortBy) {
      'Department' => 'department_name',
      'Branch' || 'Station' => 'station_name',
      'Designation' => 'designation_name',
      'Employee ID' => 'employee_id',
      _ => 'employee_name',
    };
    rows.sort((a, b) => '${a[key]}'.toLowerCase().compareTo('${b[key]}'.toLowerCase()));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ps,
      builder: (context, _) {
        return ColoredBox(
          color: Colors.white,
          child: _country == null ? _countryGate() : _workspace(),
        );
      },
    );
  }

  Widget _countryGate() {
    return Center(
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a Payroll Country', style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 10),
            _countryDrop(),
          ],
        ),
      ),
    );
  }

  Widget _countryDrop() {
    return HrDropdown<String>(
      value: _country,
      isExpanded: true,
      decoration: _box(),
      hint: 'Select a Payroll Country',
      items: [
        for (final c in _countries)
          DropdownMenuItem(value: '${c['code']}', child: Text('${c['name']}')),
      ],
      onChanged: (v) => setState(() {
        _country = v;
        _rows = [];
        _openId = null;
      }),
    );
  }

  Widget _workspace() {
    final visible = _visible;
    final total = visible.fold<num>(0, (sum, row) => sum + ((row['net'] as num?) ?? 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 40),
      children: [
        const Text('Run Payroll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 280,
            child: Column(
              children: [
                const Text('Select a Payroll Country', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 6),
                _countryDrop(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _tile(Icons.account_balance_wallet_outlined, 'Process Payroll', selected: true, onTap: () {})),
            const SizedBox(width: 12),
            Expanded(child: _tile(Icons.receipt_long_outlined, 'Payslips', onTap: () {
              context.read<AppState>().openScreen(moduleId: 'payroll', subId: 'salary_payslips');
            })),
            const SizedBox(width: 12),
            Expanded(child: _tile(Icons.calculate_outlined, 'Payroll Calculator', onTap: _calculator)),
            const SizedBox(width: 12),
            Expanded(child: _tile(Icons.bar_chart_outlined, 'Reports', onTap: () {
              context.read<AppState>().openScreen(moduleId: 'payroll', subId: 'payroll_reports');
            })),
          ],
        ),
        const SizedBox(height: 22),
        const Text('Process Payroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _form(),
        const SizedBox(height: 14),
        Row(
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: _ps.busy ? null : _preview,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Preview Payslips'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5E7EB),
                foregroundColor: const Color(0xFF4B5563),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payroll filters kept for this run.')),
                );
              },
              child: const Text('Save Template'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.read<AppState>().openScreen(moduleId: 'payroll', subId: 'define_salary'),
              child: const Text('Define Salary'),
            ),
          ],
        ),
        if (_note != null) ...[
          const SizedBox(height: 10),
          Text(_note!, style: const TextStyle(color: Color(0xFFB45309))),
        ],
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 18),
          _table(visible),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Total    ${_money(total)}', style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _ps.busy ? null : _preview,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Preview Payslips'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _export,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Export Report'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _ps.busy ? null : _generate,
                child: const Text('Generate Payslips'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _form() {
    final months = [for (var m = 1; m <= 12; m++) DateTime(_period.year, m)];
    final itemNames = ((_ps.meta['items'] as List?) ?? [])
        .map((e) => '${asStringKeyedMap(e)['name']}')
        .where((n) => n.isNotEmpty)
        .toList();
    final countries = _countries;
    final embassyOptions = [
      for (var i = 0; i < countries.length; i++)
        {'id': i, 'code': '${countries[i]['code']}', 'label': '${countries[i]['name']}'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payroll For', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _line(
          'Payroll Setup',
          HrDropdown<String>(
            value: _setupNames.contains(_setupName) ? _setupName : null,
            isExpanded: true,
            decoration: _box(),
            hint: '-',
            items: [
              for (final name in _setupNames) DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: (v) => setState(() => _setupName = v),
          ),
          'Saved payroll setup used for this run.',
        ),
        _line(
          'Users',
          _multi('Select Users', _employees, _users, (v) => setState(() => _users = v), person: true),
          'Generate salaries only for these people. Leave empty for everyone in the other filters.',
        ),
        _line(
          'Exempt Users',
          _multi('Select Users', _employees, _exempt, (v) => setState(() => _exempt = v), person: true),
          'These people are left out of this payroll run.',
        ),
        _line(
          'Embassies',
          _multi(
            'Select Embassy',
            embassyOptions,
            [
              for (final option in embassyOptions)
                if (_embassies.contains(option['code'])) option['id'] as int,
            ],
            (ids) => setState(() {
              _embassies = [
                for (final option in embassyOptions)
                  if (ids.contains(option['id'])) '${option['code']}',
              ];
            }),
            allLabel: 'All Embassies',
          ),
          'Limit the run to stations in the selected country or embassy.',
        ),
        _line(
          'Clients',
          _multi('Select Client', _clientOptions, _clients, (v) => setState(() => _clients = v), allLabel: 'All Clients'),
          'Limit the run to people on the selected client or project.',
        ),
        _line(
          'Stations',
          _multi('Select Station', _stationOptions, _stations, (v) => setState(() => _stations = v), allLabel: 'All Stations'),
          'Station-wise salary generation. Leave empty to include every station in the country.',
        ),
        _line(
          'Departments',
          _multi('Select Department', _departmentOptions, _departments, (v) => setState(() => _departments = v), allLabel: 'All Departments'),
          'Department-wise salary generation.',
        ),
        _line(
          'Designations',
          _multi('Select Designation', _designationOptions, _designations, (v) => setState(() => _designations = v), allLabel: 'All Designations'),
          'Designation-wise salary generation.',
        ),
        _line('Users Type', _chipChoice(_userType, const ['All User Types', 'Salary', 'Hourly'], (v) => setState(() => _userType = v)), 'Salary or hourly users.'),
        _line('User Category', _chipChoice(_userCategory, const ['All User Categories', 'Permanent', 'Contract'], (v) => setState(() => _userCategory = v)), 'Permanent or contract users.'),
        const SizedBox(height: 8),
        const Text('Pay Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _line('Pay Date', _dateField(_payDate, (d) {
          if (d != null) setState(() => _payDate = d);
        }), 'Date printed on the payslip.'),
        const SizedBox(height: 8),
        const Text('Salary Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _line(
          'Auto Deduction - Start Date',
          _dateField(_deductStart, (d) => setState(() => _deductStart = d)),
          'Start of automatic deductions for this period.',
        ),
        _line(
          'Auto Deduction - End Date',
          _dateField(_deductEnd, (d) => setState(() => _deductEnd = d)),
          'End of automatic deductions for this period.',
        ),
        _line(
          'Pay Period',
          HrDropdown<DateTime>(
            value: DateTime(_period.year, _period.month),
            isExpanded: true,
            decoration: _box(),
            items: [
              for (final month in months)
                DropdownMenuItem(value: month, child: Text(_rangeLabel(month))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _period = v);
            },
          ),
          'Salary month. Example: October 1, 2026-October 31, 2026.',
        ),
        _line(
          'Pay Cycle',
          HrDropdown<String>(
            value: _cycle,
            isExpanded: true,
            decoration: _box(),
            items: const [
              DropdownMenuItem(value: 'Regular', child: Text('Regular')),
              DropdownMenuItem(value: 'Off Cycle', child: Text('Off Cycle')),
            ],
            onChanged: (v) => setState(() => _cycle = v ?? 'Regular'),
          ),
          'Regular payroll or an off-cycle run.',
        ),
        _line('Exclude Basic Salary', Switch(value: _excludeBasic, onChanged: (v) => setState(() => _excludeBasic = v)), 'Leave basic salary off this preview.'),
        _line('Exclude Auto Deductions', Switch(value: _excludeDeductions, onChanged: (v) => setState(() => _excludeDeductions = v)), 'Leave automatic deductions off this preview.'),
        const SizedBox(height: 8),
        const Text('Preview Payslips Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _line('Additional Fields', _textMulti('Select Fields', const ['Department', 'Station', 'Designation', 'Employee ID'], _extraFields, (v) => setState(() => _extraFields = v)), 'Extra columns on the preview.'),
        _line('Hide Fields', _textMulti('Select Fields', const ['Hours', 'Taxes', 'Additions', 'Deductions'], _hiddenFields, (v) => setState(() => _hiddenFields = v)), 'Columns to hide on the preview.'),
        _line('User Custom Fields', _textMulti('Select Fields', const ['Grade', 'Category', 'Nationality'], _customFields, (v) => setState(() => _customFields = v)), 'Custom columns kept for this template.'),
        _line(
          'Sort By',
          HrDropdown<String>(
            value: _sortBy,
            isExpanded: true,
            decoration: _box(),
            hint: 'Sort by',
            items: const [
              DropdownMenuItem(value: 'Preferred Name', child: Text('Preferred Name')),
              DropdownMenuItem(value: 'Last Name', child: Text('Last Name')),
              DropdownMenuItem(value: 'Employee ID', child: Text('Employee ID')),
              DropdownMenuItem(value: 'Station', child: Text('Station')),
              DropdownMenuItem(value: 'Department', child: Text('Department')),
              DropdownMenuItem(value: 'Designation', child: Text('Designation')),
            ],
            onChanged: (v) => setState(() => _sortBy = v),
          ),
          'Order of people on the preview.',
        ),
        _line(
          'Payroll Items Type',
          _textMulti('Select Payroll Items Type', itemNames.isEmpty ? const ['Basic Salary', 'Allowance', 'Deduction'] : itemNames, _itemTypes, (v) => setState(() => _itemTypes = v)),
          'Which payroll items appear when a row is expanded.',
        ),
        _line('Show Negative/Zero Amount', Switch(value: _showZero, onChanged: (v) => setState(() => _showZero = v)), 'Include payslips whose net is zero or negative.'),
        _line('Check Duplicate Payslips', Switch(value: _checkDuplicate, onChanged: (v) => setState(() => _checkDuplicate = v)), 'Warn before a second payslip is generated for the same period.'),
      ],
    );
  }

  Widget _line(String label, Widget field, String tip, {bool showClear = false, VoidCallback? onClear}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 220, child: Text(label, style: const TextStyle(color: Color(0xFF6B7280)))),
          SizedBox(width: 340, child: field),
          SizedBox(
            width: 36,
            child: showClear
                ? IconButton(
                    tooltip: 'Clear',
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                  )
                : null,
          ),
          Tooltip(
            message: tip,
            child: const Icon(Icons.info_outline, size: 18, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }

  bool get _showHours => !_hiddenFields.contains('Hours');
  bool get _showAdd => !_hiddenFields.contains('Additions');
  bool get _showDed => !_hiddenFields.contains('Deductions');
  bool get _showTax => !_hiddenFields.contains('Taxes');

  Widget _table(List<Map<String, dynamic>> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1180,
          child: Column(
            children: [
              Container(
                color: _brown,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(children: [
                      _head('Number', 52),
                      _head('User', 180),
                      _head('Notes', 150),
                      _head('Salary Type', 90),
                      if (_showHours) const SizedBox(width: 220, child: Center(child: Text('Hours', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
                      if (_showAdd) _head('Additions', 80),
                      if (_showDed) _head('Deductions', 90),
                      _head('Gross Pay', 90),
                      if (_showTax) _head('Taxes', 70),
                      _head('Net Pay', 90),
                      const SizedBox(width: 36),
                    ]),
                    if (_showHours)
                      Row(children: [
                        const SizedBox(width: 472),
                        _head('Regular', 55),
                        _head('Overtime', 55),
                        _head('PTO', 50),
                        _head('Holiday', 60),
                      ]),
                  ],
                ),
              ),
              for (var i = 0; i < rows.length; i++) ...[
                _personRow(i, rows[i]),
                if (_openId == (rows[i]['id'] as num?)?.toInt()) _itemEditor(rows[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _personRow(int index, Map<String, dynamic> row) {
    final id = (row['id'] as num?)?.toInt() ?? 0;
    final name = '${row['employee_name']}';
    final open = _openId == id;
    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _cell('${index + 1}', 52),
          SizedBox(
            width: 180,
            child: Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: const Color(0xFFE5E7EB), child: Text(_initials(name), style: const TextStyle(fontSize: 9, color: Color(0xFF374151)))),
                const SizedBox(width: 6),
                Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: _notes[id],
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Add Notes',
                filled: true,
                fillColor: _field,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
              ),
            ),
          ),
          _cell('${row['salary_type'] ?? 'Salary'}', 90),
          if (_showHours) ...[
            _cell('0', 55),
            _cell('0', 55),
            _cell('0', 50),
            _cell('0', 60),
          ],
          if (_showAdd) _cell(_money(row['additions'] as num?), 80),
          if (_showDed) _cell(_money(row['deductions'] as num?), 90),
          _cell(_money(row['gross'] as num?), 90),
          if (_showTax) _cell(_money(row['tax'] as num?), 70),
          _cell(_money(row['net'] as num?), 90),
          IconButton(
            onPressed: () => setState(() => _openId = open ? null : id),
            icon: Icon(open ? Icons.expand_less : Icons.expand_more, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _itemEditor(Map<String, dynamic> row) {
    final items = ((row['items'] as List?) ?? []).map(asStringKeyedMap).where((item) {
      if (_itemTypes.isEmpty) return true;
      return _itemTypes.contains('${item['item']}');
    }).toList();
    final names = ((_ps.meta['items'] as List?) ?? [])
        .map((e) => '${asStringKeyedMap(e)['name']}')
        .where((n) => n.isNotEmpty)
        .toList();
    return _ItemEditor(
      items: items,
      catalog: names.isEmpty ? const ['Basic Salary', 'Allowance', 'Deduction'] : names,
      onUpdate: (next) => _applyItems(row, next),
    );
  }

  void _applyItems(Map<String, dynamic> row, List<Map<String, dynamic>> items) {
    final id = (row['id'] as num?)?.toInt();
    num additions = 0;
    num deductions = 0;
    num basic = 0;
    for (final item in items) {
      final amount = num.tryParse('${item['amount']}') ?? 0;
      final name = '${item['item']}'.toLowerCase();
      if (name.contains('basic')) {
        basic += amount;
      } else if (amount < 0) {
        deductions += amount.abs();
      } else {
        additions += amount;
      }
    }
    if (_excludeBasic) basic = 0;
    if (_excludeDeductions) deductions = 0;
    final gross = basic + additions;
    setState(() {
      final index = _rows.indexWhere((r) => (r['id'] as num?)?.toInt() == id);
      if (index < 0) return;
      _rows[index] = {
        ..._rows[index],
        'items': items,
        'additions': additions,
        'deductions': deductions,
        'gross': gross,
        'net': gross - deductions - ((row['tax'] as num?) ?? 0),
      };
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payslip items updated on this preview.')),
    );
  }

  Widget _head(String text, double width) => SizedBox(
        width: width,
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _cell(String text, double width) => SizedBox(
        width: width,
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
      );

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  Widget _chipChoice(String value, List<String> items, ValueChanged<String> onChanged) {
    return HrDropdown<String>(
      value: items.contains(value) ? value : items.first,
      isExpanded: true,
      decoration: _box(),
      selectedItemBuilder: (context) => [
        for (final item in items)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE8EEF9), borderRadius: BorderRadius.circular(12)),
              child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            ),
          ),
      ],
      items: [for (final item in items) DropdownMenuItem(value: item, child: Text(item))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _dateField(DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: _box(icon: Icons.calendar_today_outlined),
        child: Text(
          value == null ? 'mm / dd / yyyy' : DateFormat('MM/dd/yyyy').format(value),
          style: TextStyle(color: value == null ? const Color(0xFF9CA3AF) : const Color(0xFF111827)),
        ),
      ),
    );
  }

  Widget _textMulti(String hint, List<String> options, List<String> selected, ValueChanged<List<String>> onChanged) {
    final mapped = <Map<String, dynamic>>[
      for (var i = 0; i < options.length; i++) {'id': i, 'label': options[i]},
    ];
    final ids = [for (var i = 0; i < options.length; i++) if (selected.contains(options[i])) i];
    return _multi(hint, mapped, ids, (next) {
      onChanged([for (final id in next) if (id >= 0 && id < options.length) options[id]]);
    });
  }

  Widget _multi(String hint, List<Map<String, dynamic>> options, List<int> selected, ValueChanged<List<int>> onChanged, {String? allLabel, bool person = false}) {
    return HrLookupSelect<int>(
      multiple: true,
      hint: hint,
      allLabel: allLabel,
      values: selected,
      onMultiChanged: onChanged,
      options: [
        for (final option in options)
          if ((option['id'] as num?) != null)
            HrLookupOption<int>(
              value: (option['id'] as num).toInt(),
              label: '${option['label'] ?? option['name'] ?? ''}',
              subtitle: '${option['code'] ?? option['employee_code'] ?? ''}',
              person: person,
            ),
      ],
    );
  }

  Widget _tile(IconData icon, String label, {required VoidCallback onTap, bool selected = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 92,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F1FB) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB), width: selected ? 1.4 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  InputDecoration _box({IconData? icon}) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _field,
        suffixIcon: icon == null ? null : Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      );

  void _export() {
    final lines = [
      'User,Station,Department,Designation,Gross,Net',
      for (final row in _visible)
        '"${row['employee_name']}","${row['station_name']}","${row['department_name']}","${row['designation_name']}",${row['gross']},${row['net']}',
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Report'),
        content: SizedBox(width: 560, child: SingleChildScrollView(child: SelectableText(lines.join('\n')))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _calculator() async {
    final amount = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payroll Calculator'),
        content: TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Annual salary'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final monthly = (double.tryParse(amount.text) ?? 0) / 12;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Monthly gross ${_money(monthly)} $_currency')),
              );
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
    amount.dispose();
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({required this.items, required this.catalog, required this.onUpdate});

  final List<Map<String, dynamic>> items;
  final List<String> catalog;
  final ValueChanged<List<Map<String, dynamic>>> onUpdate;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  late List<Map<String, dynamic>> _items = [
    for (final item in widget.items)
      {
        'item': item['item'] ?? 'Basic Salary',
        'description': item['description'] ?? item['item'] ?? '',
        'hours': '${item['hours'] ?? 0}',
        'amount': '${item['amount'] ?? ((item['allowance'] as num?) ?? 0) - ((item['deduction'] as num?) ?? 0)}',
        'employer': '${item['employer'] ?? 0}',
      },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(40, 8, 16, 12),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF4B5563),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const Row(
              children: [
                SizedBox(width: 40, child: Text('Num', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 180, child: Text('Payroll Item', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 220, child: Text('Description', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 80, child: Text('Hours', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 110, child: Text('Amount', style: TextStyle(color: Colors.white, fontSize: 12))),
                SizedBox(width: 110, child: Text('Employer Share', style: TextStyle(color: Colors.white, fontSize: 12))),
              ],
            ),
          ),
          for (var i = 0; i < _items.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text('${i + 1}', textAlign: TextAlign.center)),
                  SizedBox(
                    width: 180,
                    child: HrDropdown<String>(
                      value: widget.catalog.contains(_items[i]['item']) ? '${_items[i]['item']}' : widget.catalog.first,
                      isExpanded: true,
                      decoration: _mini(),
                      items: [for (final name in widget.catalog) DropdownMenuItem(value: name, child: Text(name, overflow: TextOverflow.ellipsis))],
                      onChanged: (v) => setState(() => _items[i]['item'] = v ?? _items[i]['item']),
                    ),
                  ),
                  SizedBox(width: 220, child: _edit('${_items[i]['description']}', (v) => _items[i]['description'] = v)),
                  SizedBox(width: 80, child: _edit('${_items[i]['hours']}', (v) => _items[i]['hours'] = v)),
                  SizedBox(width: 110, child: _edit('${_items[i]['amount']}', (v) => _items[i]['amount'] = v)),
                  SizedBox(width: 110, child: _edit('${_items[i]['employer']}', (v) => _items[i]['employer'] = v)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB08968), foregroundColor: Colors.white),
            onPressed: () => widget.onUpdate(_items),
            child: const Text('Update Payslip Items'),
          ),
        ],
      ),
    );
  }

  Widget _edit(String value, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: _mini(),
    );
  }

  InputDecoration _mini() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
      );
}

