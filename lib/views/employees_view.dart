import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/employees/employee_state.dart';
import '../core/uploads/upload_service.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR-style Employees grid + Add/Edit form (API-backed).
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

  final _name = TextEditingController();
  final _userName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  int? _designation;
  int? _department;
  int? _station;
  int? _project;
  int? _manager;
  int _status = 1;
  int? _gender;
  bool _allowLogin = true;

  static const _accent = Color(0xFFA67C5D);
  static const _headerBrown = Color(0xFF9A7358);

  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load());
  }

  @override
  void dispose() {
    _name.dispose();
    _userName.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _state.dispose();
    super.dispose();
  }

  void _openAdd() {
    _editId = null;
    _name.clear();
    _userName.clear();
    _email.clear();
    _password.clear();
    _code.clear();
    _designation = null;
    _department = null;
    _station = null;
    _project = null;
    _manager = null;
    _status = 1;
    _gender = null;
    _allowLogin = true;
    _photoUrl = null;
    setState(() => _showForm = true);
  }

  void _openEdit(Map<String, dynamic> row) {
    _editId = (row['employee_id'] as num?)?.toInt();
    _name.text = '${row['name'] ?? ''}';
    _userName.text = '${row['user_name'] ?? ''}';
    _email.text = '${row['email'] ?? ''}';
    _password.clear();
    _code.text = '${row['employee_code'] ?? ''}';
    _designation = _nz(row['designation']);
    _department = _nz(row['department']);
    _station = _nz(row['station']);
    _project = _nz(row['project']);
    _manager = _nz(row['line_manager']);
    _status = (row['status'] as num?)?.toInt() ?? 1;
    _gender = row['gender'] == null ? null : (row['gender'] as num?)?.toInt();
    _allowLogin = _status > 0;
    _photoUrl = AppConfig.resolveMediaUrl(row['profile_picture']?.toString());
    setState(() => _showForm = true);
  }

  int? _nz(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n > 0 ? n : null;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _userName.text.trim().isEmpty) {
      _toast('Name and Employee ID are required.');
      return;
    }
    if (_editId == null && _password.text.isEmpty) {
      _toast('Password is required for new employees.');
      return;
    }
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'user_name': _userName.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'employee_code': _code.text.trim().isEmpty ? _userName.text.trim() : _code.text.trim(),
      'status': _allowLogin ? _status : 0,
      'gender': _gender,
      'designation': _designation,
      'department': _department,
      'station': _station,
      'project': _project,
      'line_manager': _manager,
      'allow_login': _allowLogin,
    };
    if (_password.text.isNotEmpty) body['password'] = _password.text;

    final err = _editId == null
        ? await _state.create({...body, 'password': _password.text})
        : await _state.update(_editId!, body);
    if (!mounted) return;
    if (err != null) {
      _toast(err);
      return;
    }
    setState(() => _showForm = false);
    _toast(_editId == null ? 'Employee created.' : 'Employee updated.');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        if (_showForm) return _buildForm();
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
          return Wrap(spacing: 12, runSpacing: 12, children: cards.map((w) {
            return SizedBox(width: (c.maxWidth - 12) / 2, child: w);
          }).toList());
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
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
              _brownBtn(Icons.group_outlined, 'Employee Groups', () {
                _toast('Employee Groups — next iteration.');
              }),
              _brownBtn(Icons.security_outlined, 'Employee Roles', () {
                context.read<AppState>().selectSub('employee_roles');
              }),
              _brownBtn(Icons.add, '+ Add Record', _openAdd),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => _state.load(q: _query),
          icon: Icon(Icons.refresh, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 220,
          height: 38,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              suffixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ],
    );
  }

  Widget _brownBtn(IconData icon, String label, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _dataTable(List<Map<String, dynamic>> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 280,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(_headerBrown),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            dataTextStyle: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            columnSpacing: 28,
            horizontalMargin: 16,
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
                    i.isOdd ? const Color(0xFFF9FAFB) : Colors.white,
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
                              backgroundColor: _accent.withOpacity(0.2),
                              child: Text(
                                _initials('${rows[i]['name']}'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _headerBrown,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${rows[i]['name']}',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text('${rows[i]['job_title'] ?? '—'}')),
                    DataCell(Text('${rows[i]['department_name'] ?? '—'}')),
                    DataCell(
                      Text(
                        '${rows[i]['user_name'] ?? rows[i]['employee_code'] ?? ''}',
                        style: const TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ),
                    DataCell(Text('${rows[i]['reports_to'] ?? '—'}')),
                    DataCell(Text('${rows[i]['station_name'] ?? '—'}')),
                    DataCell(_statusChip((rows[i]['status'] as num?)?.toInt() ?? 0)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(int status) {
    final label = status == 2
        ? 'Admin'
        : status > 0
            ? 'Active'
            : 'Inactive';
    final color = status == 2
        ? const Color(0xFF7C3AED)
        : status > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _buildForm() {
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => setState(() => _showForm = false),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                _editId == null ? 'Add New Employee' : 'Edit Employee',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showForm = false),
                child: const Text('Back'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 800;
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _formFields()),
                        const SizedBox(width: 32),
                        SizedBox(width: 200, child: _photoBlock()),
                      ],
                    )
                  : Column(
                      children: [
                        _photoBlock(),
                        const SizedBox(height: 20),
                        _formFields(),
                      ],
                    );
            },
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: _state.busy ? null : _save,
              child: Text(_editId == null ? 'Create Employee' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBlock() {
    return Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            image: _photoUrl != null && _photoUrl!.isNotEmpty
                ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: _photoUrl == null || _photoUrl!.isEmpty
              ? Icon(Icons.person, size: 64, color: Colors.grey.shade400)
              : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            if (_editId == null) {
              _toast('Save the employee first, then upload a photo.');
              return;
            }
            final r = await UploadService(context.read<AuthState>())
                .pickAndUploadEmployeePhoto(_editId!);
            if (r.error != null) {
              _toast(r.error!);
              return;
            }
            if (r.url != null) {
              setState(() => _photoUrl = r.url);
              _toast('Photo updated.');
              await _state.load();
            }
          },
          child: const Text('Upload Photo'),
        ),
      ],
    );
  }

  Widget _formFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('Employee Information'),
        _field('Full Name *', TextField(
          controller: _name,
          decoration: _deco('Full name'),
        )),
        _field('Employee ID *', TextField(
          controller: _userName,
          decoration: _deco('Login username / Emp ID'),
        )),
        _field('Email', TextField(
          controller: _email,
          decoration: _deco('email@company.com'),
        )),
        _field(
          _editId == null ? 'Password *' : 'Password (leave blank to keep)',
          TextField(
            controller: _password,
            obscureText: true,
            decoration: _deco('Password'),
          ),
        ),
        _field('Employee Code', TextField(
          controller: _code,
          decoration: _deco('Optional code'),
        )),
        _field('Job Title', _dropdown(
          value: _designation,
          items: _state.optionList('designations'),
          onChanged: (v) => setState(() => _designation = v),
        )),
        _field('Department', _dropdown(
          value: _department,
          items: _state.optionList('departments'),
          onChanged: (v) => setState(() => _department = v),
        )),
        _field('Station', _dropdown(
          value: _station,
          items: _state.optionList('stations'),
          onChanged: (v) => setState(() => _station = v),
        )),
        _field('Project', _dropdown(
          value: _project,
          items: _state.optionList('projects'),
          onChanged: (v) => setState(() => _project = v),
        )),
        _field('Reports To', _dropdown(
          value: _manager,
          items: _state.optionList('managers'),
          onChanged: (v) => setState(() => _manager = v),
        )),
        _field('Gender', _dropdown(
          value: _gender,
          items: _state.optionList('genders'),
          onChanged: (v) => setState(() => _gender = v),
        )),
        _field('Status', _dropdown(
          value: _status,
          items: _state.optionList('statuses'),
          onChanged: (v) => setState(() => _status = v ?? 1),
          allowNull: false,
        )),
        const SizedBox(height: 8),
        _section('Employee User Information'),
        Row(
          children: [
            const Text('Allow Employee Login', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 16),
            Switch(
              value: _allowLogin,
              activeColor: _accent,
              onChanged: (v) => setState(() => _allowLogin = v),
            ),
            Text(_allowLogin ? 'On' : 'Off', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _field(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _dropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<int?> onChanged,
    bool allowNull = true,
  }) {
    return DropdownButtonFormField<int?>(
      value: value,
      isExpanded: true,
      decoration: _deco(null),
      items: [
        if (allowNull)
          const DropdownMenuItem<int?>(value: null, child: Text('—')),
        ...items.map((o) {
          final id = (o['id'] as num?)?.toInt();
          return DropdownMenuItem<int?>(
            value: id,
            child: Text('${o['name']}'),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }

  InputDecoration _deco(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF3F3F3),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }
}
