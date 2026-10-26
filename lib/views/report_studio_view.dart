import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Left-hand report list, filters, then a generated grid.
class ReportStudioView extends StatefulWidget {
  const ReportStudioView({super.key});

  @override
  State<ReportStudioView> createState() => _ReportStudioViewState();
}

class _ReportDef {
  const _ReportDef(this.id, this.title, this.blurb);
  final String id;
  final String title;
  final String blurb;
}

class _ReportStudioViewState extends State<ReportStudioView> {
  static const _reports = [
    _ReportDef('people', 'People Register', 'Who is in each station, project, and department.'),
    _ReportDef('attendance', 'Attendance Hours', 'Clock-in, clock-out, and hours in the date range.'),
    _ReportDef('late_starts', 'Late Starts', 'Days that started after 09:05.'),
    _ReportDef('open_punches', 'Open Punches', 'A start time with no end time.'),
    _ReportDef('leave_activity', 'Leave Activity', 'Leave that overlaps the date range.'),
    _ReportDef('pay_profile', 'Pay Profile', 'Annual, monthly, basic, and hourly pay.'),
    _ReportDef('processed_pay', 'Processed Pay', 'Pay that has already been run.'),
    _ReportDef('additions', 'Additions Ledger', 'Allowances and other additions on the pay structure.'),
    _ReportDef('deductions', 'Deductions Ledger', 'Deductions on the pay structure.'),
    _ReportDef('overtime', 'Overtime Ledger', 'Overtime hours in the date range.'),
  ];

  late final ApiClient _api;
  String _report = _reports.first.id;
  bool _busy = false;
  bool _loadingOptions = true;
  String? _error;
  Map<String, dynamic> _options = {};
  List<Map<String, dynamic>> _columns = [];
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _totals = {};
  bool _generated = false;

  String? _stationId;
  String? _projectId;
  String? _divisionId;
  String? _parentId;
  String? _departmentId;
  String? _designationId;
  String? _employeeId;
  String _status = 'active';
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime(DateTime.now().year, DateTime.now().month + 2, 0);

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthState>();
    _api = ApiClient(tokenProvider: () async => auth.session?.token);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  Future<void> _loadOptions() async {
    try {
      final res = await _api.dio.get('/reports/studio/meta');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        _options = asStringKeyedMap(data['options']);
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loadingOptions = false);
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/reports/studio/run', queryParameters: {
        'report': _report,
        'status': _status,
        if (_stationId != null) 'station_id': _stationId,
        if (_projectId != null) 'project_id': _projectId,
        if (_divisionId != null) 'division_id': _divisionId,
        if (_parentId != null) 'parent_department_id': _parentId,
        if (_departmentId != null) 'department_id': _departmentId,
        if (_designationId != null) 'designation_id': _designationId,
        if (_employeeId != null) 'employee_id': _employeeId,
        'from': _ymd(_from),
        'to': _ymd(_to),
      });
      final data = res.data;
      if (data is Map && data['success'] == true) {
        _columns = ((data['columns'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        _rows = ((data['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
        _totals = asStringKeyedMap(data['totals']);
        _generated = true;
      } else {
        _error = 'The report could not be generated.';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final current = _reports.firstWhere((r) => r.id == _report);
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 250, child: _rail(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Text(current.title,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: HrUi.label(context))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(current.blurb, style: TextStyle(color: HrUi.muted(context))),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      _filterCard(context),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      if (_generated) _result(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rail(BuildContext context) {
    final brand = HrTheme.brand(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HrTheme.card(context),
        border: Border(right: BorderSide(color: HrUi.border(context))),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('Reports', style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
          ),
          for (final report in _reports)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color: report.id == _report ? brand : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    _report = report.id;
                    _generated = false;
                    _rows = [];
                    _totals = {};
                    _error = null;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      report.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: report.id == _report ? HrTheme.onBrand(context) : HrUi.label(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterCard(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HrTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrTheme.heading(context))),
            const SizedBox(height: 12),
            if (_loadingOptions)
              const LinearProgressIndicator()
            else ...[
              _drop('Station', _stationId, _options['stations'], (v) => _stationId = v),
              _drop('Project', _projectId, _options['projects'], (v) => _projectId = v),
              _drop('Division', _divisionId, _options['divisions'], (v) => _divisionId = v),
              _drop('Parent department', _parentId, _options['parent_departments'], (v) => _parentId = v),
              _drop('Department', _departmentId, _options['departments'], (v) => _departmentId = v),
              _drop('Employee', _employeeId, _options['employees'], (v) => _employeeId = v),
              _drop('Designation', _designationId, _options['designations'], (v) => _designationId = v),
              _drop('Status', _status, const [
                {'id': 'active', 'name': 'Active people'},
                {'id': 'all', 'name': 'Everyone'},
              ], (v) => _status = v ?? 'active', allowEmpty: false),
              _dates(context),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: HrTheme.brand(context),
                foregroundColor: HrTheme.onBrand(context),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              onPressed: _busy ? null : _generate,
              child: Text(_busy ? 'Generating…' : 'Generate report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drop(String label, String? value, Object? raw, ValueChanged<String?> onChanged, {bool allowEmpty = true}) {
    final items = ((raw as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label, style: TextStyle(color: HrUi.muted(context)))),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: HrUi.pageBg(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              hint: Text(allowEmpty ? 'All' : ''),
              items: [
                if (allowEmpty) const DropdownMenuItem(value: null, child: Text('All')),
                for (final item in items)
                  DropdownMenuItem(
                    value: '${item['id']}',
                    child: Text('${item['name']}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dates(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text('Date range', style: TextStyle(color: HrUi.muted(context)))),
          _dateButton(_from, (d) => _from = d),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
          _dateButton(_to, (d) => _to = d),
        ],
      ),
    );
  }

  Widget _dateButton(DateTime value, ValueChanged<DateTime> onPick) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) setState(() => onPick(picked));
      },
      child: Text(_ymd(value)),
    );
  }

  Widget _result(BuildContext context) {
    if (_rows.isEmpty) {
      return Text('No rows for these filters.', style: TextStyle(color: HrUi.muted(context)));
    }
    final brand = HrTheme.brand(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HrTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(brand),
          headingTextStyle: TextStyle(color: HrTheme.onBrand(context), fontWeight: FontWeight.w700),
          columns: [
            const DataColumn(label: Text('#')),
            for (final col in _columns) DataColumn(label: Text('${col['label']}')),
          ],
          rows: [
            for (final row in _rows)
              DataRow(cells: [
                DataCell(Text('${row['n'] ?? ''}')),
                for (final col in _columns) DataCell(Text('${row[col['key']] ?? ''}')),
              ]),
            if (_totals.isNotEmpty)
              DataRow(cells: [
                const DataCell(Text('')),
                for (final col in _columns)
                  DataCell(Text(
                    _totals.containsKey(col['key']) ? '${_totals[col['key']]}' : (col['key'] == _columns.first['key'] ? 'Total' : ''),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  )),
              ]),
          ],
        ),
      ),
    );
  }
}
