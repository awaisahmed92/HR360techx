import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/reports/hr_reports_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Non-payroll HR reports hub (leave, workforce, attendance).
class HrReportsView extends StatefulWidget {
  const HrReportsView({super.key});

  @override
  State<HrReportsView> createState() => _HrReportsViewState();
}

class _HrReportsViewState extends State<HrReportsView> {
  late final HrReportsState _state;

  static const _tabs = [
    'Leave',
    'Balance',
    'Usage',
    'Employees',
    'Monthly Att.',
    'Att. Log',
  ];

  @override
  void initState() {
    super.initState();
    _state = HrReportsState(context.read<AuthState>());
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text('HR Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: _state.busy ? null : () => _state.load(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Run'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_tabs[i]),
                          selected: _state.tab == i,
                          onSelected: (_) => _state.setTab(i),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _filters(),
              ),
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Expanded(
                child: _state.busy
                    ? const Center(child: CircularProgressIndicator())
                    : _table(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filters() {
    final employees = (_state.options['employees'] as List?) ?? [];
    final departments = (_state.options['departments'] as List?) ?? [];
    final leaveTypes = (_state.options['leave_types'] as List?) ?? [];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_state.tab == 0 || _state.tab == 4) ...[
          _monthPicker(),
        ],
        if (_state.tab == 2 || _state.tab == 3 || _state.tab == 5) ...[
          _dateChip('From', _state.from, (d) {
            _state.from = d;
            _state.touch();
          }),
          _dateChip('To', _state.to, (d) {
            _state.to = d;
            _state.touch();
          }),
        ],
        if (_state.tab != 2)
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<int?>(
              value: _state.employeeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Employee', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...employees.whereType<Map>().map((e) {
                  final id = (e['id'] as num?)?.toInt();
                  return DropdownMenuItem(value: id, child: Text('${e['name']}', overflow: TextOverflow.ellipsis));
                }),
              ],
              onChanged: (v) {
                _state.employeeId = v;
                _state.touch();
              },
            ),
          ),
        SizedBox(
            width: 180,
            child: DropdownButtonFormField<int?>(
              value: _state.departmentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Department', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...departments.whereType<Map>().map((e) {
                  final id = (e['id'] as num?)?.toInt();
                  return DropdownMenuItem(value: id, child: Text('${e['name']}', overflow: TextOverflow.ellipsis));
                }),
              ],
              onChanged: (v) {
                _state.departmentId = v;
                _state.touch();
              },
            ),
          ),
        if (_state.tab == 0 || _state.tab == 1)
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<int?>(
              value: _state.leaveTypeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Leave type', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...leaveTypes.whereType<Map>().map((e) {
                  final id = (e['id'] as num?)?.toInt();
                  return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                }),
              ],
              onChanged: (v) {
                _state.leaveTypeId = v;
                _state.touch();
              },
            ),
          ),
        if (_state.tab == 0)
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<int?>(
              value: _state.leaveStatus,
              decoration: const InputDecoration(labelText: 'Status', isDense: true),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 0, child: Text('Pending')),
                DropdownMenuItem(value: 1, child: Text('Approved')),
                DropdownMenuItem(value: 2, child: Text('Rejected')),
              ],
              onChanged: (v) {
                _state.leaveStatus = v;
                _state.touch();
              },
            ),
          ),
        if (_state.tab == 2)
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _state.usageGroupBy,
              decoration: const InputDecoration(labelText: 'Group by', isDense: true),
              items: const [
                DropdownMenuItem(value: 'employee', child: Text('Employee')),
                DropdownMenuItem(value: 'department', child: Text('Department')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _state.usageGroupBy = v;
                _state.touch();
              },
            ),
          ),
        if (_state.tab == 3)
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: _state.employeeReportType,
              decoration: const InputDecoration(labelText: 'Type', isDense: true),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'joiner', child: Text('Joiners')),
                DropdownMenuItem(value: 'leaver', child: Text('Leavers')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _state.employeeReportType = v;
                _state.touch();
              },
            ),
          ),
      ],
    );
  }

  Widget _monthPicker() {
    final label =
        '${_state.month.year}-${_state.month.month.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _state.month,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          helpText: 'Pick any day in the month',
        );
        if (picked != null) {
          _state.month = DateTime(picked.year, picked.month);
          _state.touch();
        }
      },
      icon: const Icon(Icons.calendar_month, size: 18),
      label: Text(label),
    );
  }

  Widget _dateChip(String label, DateTime value, ValueChanged<DateTime> onPick) {
    final text =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(DateTime.now().year - 5),
          lastDate: DateTime(DateTime.now().year + 1),
        );
        if (picked != null) onPick(picked);
      },
      child: Text('$label: $text'),
    );
  }

  Widget _table() {
    if (_state.rows.isEmpty) {
      return Center(
        child: Text('No rows. Adjust filters and tap Run.',
            style: TextStyle(color: HrUi.muted(context))),
      );
    }

    final columns = _columnsForTab();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: HrFitDataTableHost(
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(HrTheme.brand(context)),
          headingTextStyle: TextStyle(
            color: HrTheme.onBrand(context),
            fontWeight: FontWeight.w700,
          ),
          columnSpacing: 14,
          horizontalMargin: 10,
          columns: columns
              .map((c) => DataColumn(label: Text(c.$1, overflow: TextOverflow.ellipsis)))
              .toList(),
          rows: _state.rows.map((r) {
            return DataRow(
              cells: columns
                  .map((c) => DataCell(Text(
                        '${r[c.$2] ?? ''}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      )))
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<(String, String)> _columnsForTab() {
    switch (_state.tab) {
      case 0:
        return const [
          ('Code', 'employee_code'),
          ('Employee', 'employee_name'),
          ('Type', 'leave_type'),
          ('From', 'from'),
          ('To', 'to'),
          ('Days', 'days'),
          ('Status', 'status_label'),
        ];
      case 1:
        return const [
          ('Code', 'employee_code'),
          ('Employee', 'employee_name'),
          ('Type', 'leave_type'),
          ('Entitled', 'entitled'),
          ('Used', 'used'),
          ('Remaining', 'remaining'),
        ];
      case 2:
        return const [
          ('Group', 'group_name'),
          ('Code', 'employee_code'),
          ('Headcount', 'headcount'),
          ('Days used', 'days_used'),
          ('Applications', 'applications'),
        ];
      case 3:
        return const [
          ('Code', 'employee_code'),
          ('Name', 'name'),
          ('Department', 'department'),
          ('Designation', 'designation'),
          ('Joined', 'joining_date'),
          ('Left', 'leaving_date'),
          ('Status', 'status_label'),
        ];
      case 4:
        return const [
          ('Code', 'employee_code'),
          ('Employee', 'employee_name'),
          ('Present', 'present'),
          ('Absent', 'absent'),
          ('Leave', 'leave'),
          ('Late', 'late'),
        ];
      default:
        return const [
          ('Date', 'date'),
          ('Code', 'employee_code'),
          ('Employee', 'employee_name'),
          ('In', 'punch_in'),
          ('Out', 'punch_out'),
          ('Late', 'late_minutes'),
          ('Status', 'status_label'),
        ];
    }
  }
}
