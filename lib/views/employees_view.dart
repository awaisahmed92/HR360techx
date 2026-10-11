import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/hr_grid_query.dart';
import '../widgets/person_photo.dart';
import 'employee_form_view.dart';

/// HR360tech-style Employees grid + Personal/Job/History add/edit form.
class EmployeesView extends StatefulWidget {
  const EmployeesView({super.key});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  late final EmployeeState _state;
  bool _showForm = false;
  int? _editId;
  Map<String, dynamic>? _viewRow;
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
        if (_viewRow != null) {
          return _EmployeeRecordView(
            row: _viewRow!,
            state: _state,
            onBack: () => setState(() => _viewRow = null),
            onEdit: () {
              final row = _viewRow!;
              setState(() {
                _viewRow = null;
                _editId = (row['employee_id'] as num?)?.toInt();
                _showForm = true;
              });
            },
          );
        }
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
    final query = hrSearchQuery(context, _query);
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
                style: GoogleFonts.plusJakartaSans(
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
          _toolbar(query),
          const SizedBox(height: 12),
          _dataTable(_state.rows, query),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
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

  Widget _toolbar(String query) {
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
          onPressed: () {
            setState(() => _query = '');
            clearGridSearch(context);
            _state.load();
          },
          icon: Icon(Icons.refresh, color: HrUi.muted(context)),
        ),
        const SizedBox(width: 8),
        HrSearchField(
          value: query,
          onChanged: (v) => setState(() => _query = v),
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

  Widget _dataTable(List<Map<String, dynamic>> rows, String query) {
    final brand = HrTheme.brand(context);
    final onBrand = HrTheme.onBrand(context);
    final card = HrUi.card(context);
    final textColor = HrUi.label(context);

    final visible = hrQueryRows([
      for (var i = 0; i < rows.length; i++)
        DataRow(
          color: WidgetStateProperty.all(
            i.isOdd ? HrTheme.brandSoft(context, 0.04) : card,
          ),
          cells: [
            DataCell(Text('${i + 1}')),
            DataCell(
              InkWell(
                onTap: () => setState(() => _viewRow = rows[i]),
                child: Row(
                  children: [
                    PersonPhoto(
                      path: '${rows[i]['profile_picture'] ?? ''}',
                      employeeId: (rows[i]['employee_id'] as num?)?.toInt(),
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${rows[i]['name']}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: brand, fontWeight: FontWeight.w600),
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
            DataCell(
              PopupMenuButton<String>(
                tooltip: 'Actions',
                onSelected: (value) {
                  if (value == 'view') {
                    setState(() => _viewRow = rows[i]);
                  } else if (value == 'edit') {
                    _openEdit(rows[i]);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View Record')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                ],
                child: Icon(Icons.more_horiz, color: brand),
              ),
            ),
          ],
        ),
    ], query);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hrQueryBanner(context, query, visible.length, onClear: () => setState(() => _query = '')),
        Container(
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
            DataColumn(label: Text('')),
          ],
          rows: visible,
        ),
      ),
        ),
      ],
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

}

class _EmployeeRecordView extends StatefulWidget {
  const _EmployeeRecordView({
    required this.row,
    required this.state,
    required this.onBack,
    required this.onEdit,
  });

  final Map<String, dynamic> row;
  final EmployeeState state;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  State<_EmployeeRecordView> createState() => _EmployeeRecordViewState();
}

class _EmployeeRecordViewState extends State<_EmployeeRecordView> {
  Map<String, dynamic> _detail = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = (widget.row['employee_id'] as num?)?.toInt() ?? 0;
    final data = await widget.state.getById(id);
    if (!mounted) return;
    final emp = data == null ? null : data['employee'];
    setState(() {
      _detail = emp is Map ? emp.map((k, v) => MapEntry('$k', v)) : {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.row['name'] ?? ''}';
    final status = (widget.row['status'] as num?)?.toInt() ?? 0;
    final active = status > 0;
    String pick(String key, [String fallback = '—']) {
      final v = _detail[key] ?? widget.row[key];
      final s = '$v'.trim();
      if (s.isEmpty || s == 'null') return fallback;
      return s;
    }

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          if (_loading) const LinearProgressIndicator(),
          _section('Employment', [
            _line('Employment type', active ? 'Active' : 'Inactive'),
            _line('Joining date', pick('joining_date')),
            _line('Employee code', pick('employee_code')),
          ]),
          _section('User Information', [
            _line('Department', pick('department_name')),
            _line('Job title', '${widget.row['job_title'] ?? '—'}'),
            _line('Station', '${widget.row['station_name'] ?? '—'}'),
            _line('Reports to', '${widget.row['reports_to'] ?? '—'}'),
            _line('Email', pick('email')),
            _line('Phone', pick('phone', pick('contact_number'))),
            _line('Date of birth', pick('date_of_birth')),
            _line('Address', pick('address', pick('permanent_address'))),
          ]),
          _section('Login', [
            _line('Username', pick('user_name')),
            _line('Allow login', active ? 'Yes' : 'No'),
            _line('Role', status == 2 ? 'Administrator' : 'Employee'),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> lines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...lines,
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: TextStyle(color: HrUi.muted(context)))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
