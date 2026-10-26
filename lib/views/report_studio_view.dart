import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/hr_grid_query.dart';

/// Left-hand report list, filters, then a generated grid.
class ReportStudioView extends StatefulWidget {
  const ReportStudioView({super.key});

  @override
  State<ReportStudioView> createState() => _ReportStudioViewState();
}

class _ReportDef {
  const _ReportDef(this.id, this.title, this.blurb, this.group, this.icon);
  final String id;
  final String title;
  final String blurb;
  final String group;
  final IconData icon;
}

class _ReportStudioViewState extends State<ReportStudioView> {
  static const _reports = [
    _ReportDef(
        'people',
        'People Register',
        'People by station, project, department, and designation.',
        'Workforce',
        Icons.people_outline),
    _ReportDef(
        'headcount',
        'Department Headcount',
        'Workforce totals grouped by department.',
        'Workforce',
        Icons.groups_outlined),
    _ReportDef(
        'new_hires',
        'New Hire Register',
        'People whose joining date falls in the selected period.',
        'Workforce',
        Icons.person_add_alt),
    _ReportDef(
        'attendance',
        'Attendance Detail',
        'Clock-in, clock-out, and worked hours by day.',
        'Time & attendance',
        Icons.schedule_outlined),
    _ReportDef(
        'attendance_summary',
        'Attendance Overview',
        'Daily present, absent, leave, and total hours.',
        'Time & attendance',
        Icons.calendar_view_week_outlined),
    _ReportDef(
        'late_starts',
        'Late Arrival Register',
        'Workdays that started after the configured grace time.',
        'Time & attendance',
        Icons.running_with_errors_outlined),
    _ReportDef(
        'open_punches',
        'Missed Clock-out Register',
        'Attendance starts that do not have an end time.',
        'Time & attendance',
        Icons.timer_off_outlined),
    _ReportDef(
        'absent_days',
        'Absence Register',
        'Days recorded as absent or unpaid.',
        'Time & attendance',
        Icons.person_off_outlined),
    _ReportDef(
        'timesheet_detail',
        'Timesheet Detail',
        'Submitted project hours and approval status.',
        'Time & attendance',
        Icons.view_timeline_outlined),
    _ReportDef(
        'timesheet_summary',
        'Timesheet Overview',
        'Total timesheet entries and hours by person.',
        'Time & attendance',
        Icons.summarize_outlined),
    _ReportDef(
        'leave_activity',
        'Leave Register',
        'Leave requests overlapping the selected period.',
        'Leave',
        Icons.event_note_outlined),
    _ReportDef(
        'leave_summary',
        'Leave Overview',
        'Requests and days grouped by leave type.',
        'Leave',
        Icons.pie_chart_outline),
    _ReportDef(
        'pay_profile',
        'Compensation Profile',
        'Annual, monthly, basic, and hourly compensation.',
        'Payroll',
        Icons.badge_outlined),
    _ReportDef(
        'processed_pay',
        'Processed Payroll Detail',
        'Generated payroll rows with earnings and deductions.',
        'Payroll',
        Icons.receipt_long_outlined),
    _ReportDef(
        'payroll_summary',
        'Payroll Overview',
        'Monthly payroll headcount, gross, deductions, and net.',
        'Payroll',
        Icons.analytics_outlined),
    _ReportDef(
        'additions',
        'Pay Additions Register',
        'Allowances and additions configured on pay structures.',
        'Payroll',
        Icons.add_circle_outline),
    _ReportDef(
        'deductions',
        'Pay Deductions Register',
        'Deductions configured on pay structures.',
        'Payroll',
        Icons.remove_circle_outline),
    _ReportDef(
        'overtime',
        'Overtime Register',
        'Overtime hours, multiplier, and approval status.',
        'Payroll',
        Icons.more_time_outlined),
    _ReportDef(
        'advances',
        'Advance Payment Register',
        'Employee advances and planned recovery periods.',
        'Payroll',
        Icons.account_balance_wallet_outlined),
    _ReportDef(
        'settlements',
        'Final Settlement Register',
        'Clearance and final payable values for leavers.',
        'Payroll',
        Icons.assignment_turned_in_outlined),
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
  bool _showTotals = true;
  bool _showCriteria = true;
  String _resultQuery = '';

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
        _columns = ((data['columns'] as List?) ?? [])
            .map((e) => asStringKeyedMap(e))
            .toList();
        _rows = ((data['rows'] as List?) ?? [])
            .map((e) => asStringKeyedMap(e))
            .toList();
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
          SizedBox(width: 290, child: _rail(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Row(
                    children: [
                      Icon(current.icon, color: HrTheme.brand(context)),
                      const SizedBox(width: 10),
                      Text(current.title,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: HrUi.label(context))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(current.blurb,
                      style: TextStyle(color: HrUi.muted(context))),
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
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.redAccent)),
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
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Report Center',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context))),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: brand.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${_reports.length}',
                      style:
                          TextStyle(color: brand, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          for (final group in const [
            'Workforce',
            'Time & attendance',
            'Leave',
            'Payroll'
          ]) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 5),
              child: Text(
                group.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w800,
                    color: HrUi.muted(context)),
              ),
            ),
            for (final report in _reports.where((item) => item.group == group))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Material(
                  color: report.id == _report ? brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(7),
                    onTap: () => setState(() {
                      _report = report.id;
                      _generated = false;
                      _rows = [];
                      _totals = {};
                      _resultQuery = '';
                      _error = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      child: Row(
                        children: [
                          Icon(report.icon,
                              size: 17,
                              color: report.id == _report
                                  ? HrTheme.onBrand(context)
                                  : HrTheme.brand(context)),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              report.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: report.id == _report
                                    ? HrTheme.onBrand(context)
                                    : HrUi.label(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
            Text('Filters',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HrTheme.heading(context))),
            const SizedBox(height: 12),
            if (_loadingOptions)
              const LinearProgressIndicator()
            else ...[
              _drop('Station', _stationId, _options['stations'],
                  (v) => _stationId = v),
              _drop('Project', _projectId, _options['projects'],
                  (v) => _projectId = v),
              _drop('Division', _divisionId, _options['divisions'],
                  (v) => _divisionId = v),
              _drop('Parent department', _parentId,
                  _options['parent_departments'], (v) => _parentId = v),
              _drop('Department', _departmentId, _options['departments'],
                  (v) => _departmentId = v),
              _drop('Employee', _employeeId, _options['employees'],
                  (v) => _employeeId = v),
              _drop('Designation', _designationId, _options['designations'],
                  (v) => _designationId = v),
              _drop(
                  'Status',
                  _status,
                  const [
                    {'id': 'active', 'name': 'Active people'},
                    {'id': 'all', 'name': 'Everyone'},
                  ],
                  (v) => _status = v ?? 'active',
                  allowEmpty: false),
              _dates(context),
            ],
            const SizedBox(height: 8),
            Divider(color: HrUi.border(context)),
            const SizedBox(height: 8),
            Text('Report options',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HrTheme.heading(context))),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show totals row'),
              value: _showTotals,
              onChanged: (value) => setState(() => _showTotals = value),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show selected criteria above results'),
              value: _showCriteria,
              onChanged: (value) => setState(() => _showCriteria = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: HrTheme.brand(context),
                foregroundColor: HrTheme.onBrand(context),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              onPressed: _busy ? null : _generate,
              child: Text(_busy ? 'Generating…' : 'Generate report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drop(
      String label, String? value, Object? raw, ValueChanged<String?> onChanged,
      {bool allowEmpty = true}) {
    final items =
        ((raw as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
              width: 160,
              child: Text(label, style: TextStyle(color: HrUi.muted(context)))),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: HrUi.pageBg(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              hint: Text(allowEmpty ? 'All' : ''),
              items: [
                if (allowEmpty)
                  const DropdownMenuItem(value: null, child: Text('All')),
                for (final item in items)
                  DropdownMenuItem(
                    value: '${item['id']}',
                    child: Text('${item['name']}',
                        overflow: TextOverflow.ellipsis),
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
          SizedBox(
              width: 160,
              child: Text('Date range',
                  style: TextStyle(color: HrUi.muted(context)))),
          _dateButton(_from, (d) => _from = d),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
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
      return Text('No rows for these filters.',
          style: TextStyle(color: HrUi.muted(context)));
    }
    final brand = HrTheme.brand(context);
    final current = _reports.firstWhere((r) => r.id == _report);
    final query = hrSearchQuery(context, _resultQuery);
    final resultRows = hrQueryRows([
      for (final row in _rows)
        DataRow(cells: [
          DataCell(Text('${row['n'] ?? ''}')),
          for (final col in _columns)
            DataCell(Text('${row[col['key']] ?? ''}')),
        ]),
    ], query);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${current.title} Report',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: HrUi.label(context))),
        if (_showCriteria) ...[
          const SizedBox(height: 4),
          Text(
            '${_ymd(_from)} to ${_ymd(_to)} · ${_status == 'active' ? 'Active people' : 'Everyone'}',
            textAlign: TextAlign.center,
            style: TextStyle(color: HrUi.muted(context), fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '${resultRows.length} records',
              style: TextStyle(color: HrUi.muted(context), fontSize: 12),
            ),
            const Spacer(),
            HrSearchField(
              width: 270,
              hint: 'Search generated report',
              value: _resultQuery,
              onChanged: (value) => setState(() => _resultQuery = value),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: HrTheme.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HrUi.border(context)),
          ),
          child: HrPagedDataTable(
            headingRowColor: WidgetStatePropertyAll(brand),
            headingTextStyle: TextStyle(
                color: HrTheme.onBrand(context), fontWeight: FontWeight.w700),
            columns: [
              const DataColumn(label: Text('#')),
              for (final col in _columns)
                DataColumn(label: Text('${col['label']}')),
            ],
            rows: [
              ...resultRows,
              if (_showTotals && _totals.isNotEmpty)
                DataRow(cells: [
                  const DataCell(Text('')),
                  for (final col in _columns)
                    DataCell(Text(
                      _totals.containsKey(col['key'])
                          ? '${_totals[col['key']]}'
                          : (col['key'] == _columns.first['key']
                              ? 'Total'
                              : ''),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    )),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}
