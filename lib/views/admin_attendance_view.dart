import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/attendance/attendance_admin_state.dart';
import '../core/auth/auth_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Admin day grid — mark Present / Absent (PHP Admin Attendance parity).
class AdminAttendanceView extends StatefulWidget {
  const AdminAttendanceView({super.key});

  @override
  State<AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends State<AdminAttendanceView> {
  late final AttendanceAdminState _state;

  @override
  void initState() {
    super.initState();
    _state = AttendanceAdminState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.loadGrid());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final parts = _state.date.split('-');
    final initial = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final d =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      await _state.loadGrid(d: d);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text('Admin Attendance',
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
                  IconButton(
                    onPressed: () => _state.loadGrid(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (_state.isOffDay)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Off day / holiday — marking still allowed.',
                      style: TextStyle(color: HrUi.muted(context))),
                ),
              if (_state.error != null)
                Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
              if (_state.busy && _state.rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
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
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final r in _state.rows)
                        DataRow(cells: [
                          DataCell(Text('${r['name']}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text('${r['employee_code'] ?? ''}')),
                          DataCell(Text('${r['department_name'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text(_timeOnly(r['punch_in']))),
                          DataCell(Text(_timeOnly(r['punch_out']))),
                          DataCell(_statusChip('${r['status_label']}', (r['status'] as num?)?.toInt() ?? 0)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final err = await _state.mark((r['employee_id'] as num).toInt(), 1);
                                  if (mounted && err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  }
                                },
                                child: const Text('P'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final err = await _state.mark((r['employee_id'] as num).toInt(), 0);
                                  if (mounted && err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  }
                                },
                                child: const Text('A', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          )),
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

  String _timeOnly(dynamic v) {
    if (v == null) return '—';
    final s = '$v';
    if (s.length >= 16) return s.substring(11, 16);
    return s;
  }

  Widget _statusChip(String label, int code) {
    final color = code == 1
        ? const Color(0xFF16A34A)
        : code == 2
            ? const Color(0xFF2563EB)
            : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
