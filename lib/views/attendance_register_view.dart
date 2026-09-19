import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/attendance/attendance_admin_state.dart';
import '../core/auth/auth_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Attendance Register / Summary report for one date.
class AttendanceRegisterView extends StatefulWidget {
  const AttendanceRegisterView({super.key});

  @override
  State<AttendanceRegisterView> createState() => _AttendanceRegisterViewState();
}

class _AttendanceRegisterViewState extends State<AttendanceRegisterView> {
  late final AttendanceAdminState _state;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _state = AttendanceAdminState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.loadRegister());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final parts = _state.date.split('-');
    final initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final d =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _state.loadRegister(d: d, status: _filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.registerSummary;
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text('Attendance Register',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      )),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(_state.date),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final f in const [
                    ('all', 'All'),
                    ('present', 'Present'),
                    ('absent', 'Absent'),
                    ('leave', 'Leave'),
                  ])
                    ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) async {
                        setState(() => _filter = f.$1);
                        await _state.loadRegister(status: f.$1);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  _stat('Present', '${s['present'] ?? 0}', const Color(0xFF16A34A)),
                  _stat('Absent', '${s['absent'] ?? 0}', const Color(0xFFDC2626)),
                  _stat('Leave', '${s['leave'] ?? 0}', const Color(0xFF2563EB)),
                  _stat('Total', '${s['total'] ?? 0}', const Color(0xFF6B7280)),
                ],
              ),
              const SizedBox(height: 16),
              if (_state.error != null)
                Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
              if (_state.busy && _state.registerRows.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                HrFitDataTableHost(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(HrTheme.brand(context)),
                    headingTextStyle: TextStyle(
                      color: HrTheme.onBrand(context),
                      fontWeight: FontWeight.w600,
                    ),
                    columnSpacing: 14,
                    horizontalMargin: 10,
                    columns: const [
                      DataColumn(label: Text('Employee')),
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('In')),
                      DataColumn(label: Text('Out')),
                      DataColumn(label: Text('Minutes')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (final r in _state.registerRows)
                        DataRow(cells: [
                          DataCell(Text('${r['name']}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text('${r['employee_code'] ?? ''}')),
                          DataCell(Text('${r['department_name'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text(_time(r['punch_in']))),
                          DataCell(Text(_time(r['punch_out']))),
                          DataCell(Text('${r['total_minutes'] ?? '—'}')),
                          DataCell(Text('${r['status_label']}')),
                        ]),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  String _time(dynamic v) {
    if (v == null) return '—';
    final s = '$v';
    if (s.length >= 16) return s.substring(11, 16);
    return s;
  }
}
