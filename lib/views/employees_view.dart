import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import 'employee_form_view.dart';

/// WebHR-style Employees grid + Personal/Job/History add/edit form.
class EmployeesView extends StatefulWidget {
  const EmployeesView({super.key});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  late final EmployeeState _state;
  bool _showForm = false;
  int? _editId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state.load();
      final app = context.read<AppState>();
      if (app.consumeOpenEmployeeForm()) {
        _openAdd();
      }
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _openAdd() {
    _editId = null;
    setState(() => _showForm = true);
  }

  void _openEdit(Map<String, dynamic> row) {
    _editId = (row['employee_id'] as num?)?.toInt();
    setState(() => _showForm = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.pendingOpenEmployeeForm && !_showForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (context.read<AppState>().consumeOpenEmployeeForm()) {
          _openAdd();
        }
      });
    }
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        if (_showForm) {
          // Avoid AnimatedSwitcher measuring this with loose height.
          return EmployeeFormView(
            key: const ValueKey('employee-form'),
            state: _state,
            editId: _editId,
            onCancel: () => setState(() => _showForm = false),
            onDone: () => setState(() => _showForm = false),
          );
        }
        if (_state.busy && _state.rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_state.error != null && _state.rows.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_state.error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  style: HrTheme.filledButton(context),
                  onPressed: () => _state.load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return _buildGrid();
      },
    );
  }

  Widget _buildGrid() {
    final filtered = _state.rows.where((r) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return '${r['name']}|${r['user_name']}|${r['job_title']}|${r['department_name']}'
          .toLowerCase()
          .contains(q);
    }).toList();

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: HrUi.label(context)),
              const SizedBox(width: 8),
              Text(
                'Employees',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: HrUi.label(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statsRow(),
          const SizedBox(height: 16),
          _toolbar(),
          const SizedBox(height: 12),
          _dataTable(filtered),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final s = _state.stats;
    return LayoutBuilder(
      builder: (context, c) {
        final wrap = c.maxWidth < 900;
        final cards = [
          _statCard('Total Employees', '${s['total']}', Icons.groups_outlined, const Color(0xFF3B82F6)),
          _statCard('Active', '${s['active']}', Icons.check_circle_outline, const Color(0xFF22C55E)),
          _statCard('Inactive', '${s['inactive']}', Icons.cancel_outlined, const Color(0xFFEF4444)),
          _statCard('Male', '${s['male']}', Icons.male, const Color(0xFF14B8A6)),
          _statCard('Female', '${s['female']}', Icons.female, const Color(0xFFEC4899)),
        ];
        if (wrap) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((w) => SizedBox(width: (c.maxWidth - 12) / 2, child: w)).toList(),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Row(
      children: [
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _themeBtn(Icons.security_outlined, 'Employee Roles', () {
                context.read<AppState>().selectSub('employee_roles');
              }),
              _themeBtn(Icons.add, 'Add Record', _openAdd),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => _state.load(q: _query),
          icon: Icon(Icons.refresh, color: HrUi.muted(context)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 220,
          height: 38,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(fontSize: 13, color: HrUi.muted(context)),
              suffixIcon: Icon(Icons.search, size: 18, color: HrUi.muted(context)),
              filled: true,
              fillColor: HrUi.card(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: HrUi.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: HrUi.border(context)),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ],
    );
  }

  Widget _themeBtn(IconData icon, String label, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      style: HrTheme.filledButton(context).copyWith(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _dataTable(List<Map<String, dynamic>> rows) {
    final brand = HrTheme.brand(context);
    final onBrand = HrTheme.onBrand(context);
    final card = HrUi.card(context);
    final textColor = HrUi.label(context);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HrUi.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: HrFitDataTableHost(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(brand),
          headingTextStyle: TextStyle(
            color: onBrand,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(fontSize: 12, color: textColor),
          columnSpacing: 14,
          horizontalMargin: 10,
          columns: const [
            DataColumn(label: Text('S#')),
            DataColumn(label: Text('Employee Name')),
            DataColumn(label: Text('Job Title')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('Employee ID')),
            DataColumn(label: Text('Reports To')),
            DataColumn(label: Text('Station')),
            DataColumn(label: Text('Status')),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                color: WidgetStateProperty.all(
                  i.isOdd ? HrTheme.brandSoft(context, 0.04) : card,
                ),
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(
                    InkWell(
                      onTap: () => _openEdit(rows[i]),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: brand.withValues(alpha: 0.2),
                            child: Text(
                              _initials('${rows[i]['name']}'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: brand,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${rows[i]['name']}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text('${rows[i]['job_title'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                  DataCell(Text('${rows[i]['department_name'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                  DataCell(Text(
                    '${rows[i]['user_name'] ?? rows[i]['employee_code'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: brand),
                  )),
                  DataCell(Text('${rows[i]['reports_to'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                  DataCell(Text('${rows[i]['station_name'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                  DataCell(_statusChip((rows[i]['status'] as num?)?.toInt() ?? 0)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(int status) {
    final label = status == 2 ? 'Admin' : status > 0 ? 'Active' : 'Inactive';
    final color = status == 2
        ? const Color(0xFF7C3AED)
        : status > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
