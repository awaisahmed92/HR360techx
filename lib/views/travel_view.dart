import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/self_service/self_service_repository.dart';
import '../core/self_service/self_service_state.dart';
import '../widgets/hr_form_kit.dart';
import '../theme/hr_theme.dart';

class TravelView extends StatefulWidget {
  const TravelView({super.key});

  @override
  State<TravelView> createState() => _TravelViewState();
}

class _TravelViewState extends State<TravelView> {
  bool _showForm = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadTravel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    if (_showForm) {
      return TravelAddForm(
        onBack: () => setState(() => _showForm = false),
        onSaved: () async {
          setState(() => _showForm = false);
          await ss.loadTravel();
        },
      );
    }

    final filtered = ss.travels.where((t) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return '${t['employee_name']}${t['purpose']}${t['request_no']}'
          .toLowerCase()
          .contains(q);
    }).toList();

    return HrDataGridPage(
      title: 'Travels',
      icon: Icons.flight_takeoff_rounded,
      onAdd: () => setState(() => _showForm = true),
      onRefresh: () => ss.loadTravel(),
      onSearch: (v) => setState(() => _query = v),
      columns: const [
        'S#',
        'Employee',
        'Travel Purpose',
        'Travel Start Date',
        'Travel End Date',
        'Approval Status',
        'Reference Number',
        '',
      ],
      rows: [
        for (var i = 0; i < filtered.length; i++)
          [
            Text('${i + 1}'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 16, color: HrUi.muted(context)),
                const SizedBox(width: 6),
                Text((filtered[i]['employee_name'] ?? '').toString()),
              ],
            ),
            Text((filtered[i]['purpose'] ?? '').toString()),
            Text((filtered[i]['start_date'] ?? '').toString()),
            Text((filtered[i]['end_date'] ?? '').toString()),
            HrStatusPill(
              label: (filtered[i]['status_label'] ?? 'Pending').toString(),
              pending: (filtered[i]['status'] as num?)?.toInt() == 0,
            ),
            Text((filtered[i]['reference_number'] ?? filtered[i]['request_no'] ?? '')
                .toString()),
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, size: 18),
              onSelected: (v) async {
                final id = filtered[i]['id'] as int;
                if (v == 'approve') {
                  final err = await ss.travelAct('approve', id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err ?? 'Approved')),
                  );
                } else if (v == 'reject') {
                  final err = await ss.travelAct('reject', id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err ?? 'Rejected')),
                  );
                }
              },
              itemBuilder: (_) => [
                if (filtered[i]['can_approve'] == true) ...[
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                  const PopupMenuItem(value: 'reject', child: Text('Reject')),
                ],
                const PopupMenuItem(value: 'view', child: Text('View')),
              ],
            ),
          ],
      ],
    );
  }
}

class _DestRow {
  final place = TextEditingController();
  String? mode;
  String? arrangement;
  DateTime? date;

  void dispose() => place.dispose();
}

class TravelAddForm extends StatefulWidget {
  const TravelAddForm({super.key, required this.onBack, required this.onSaved});

  final VoidCallback onBack;
  final Future<void> Function() onSaved;

  @override
  State<TravelAddForm> createState() => _TravelAddFormState();
}

class _TravelAddFormState extends State<TravelAddForm> {
  final _purpose = TextEditingController();
  final _expected = TextEditingController();
  final _actual = TextEditingController();

  String _ref = '';
  int? _employeeId;
  String? _travelType;
  DateTime? _start;
  DateTime? _end;
  List<Map<String, dynamic>> _employees = [];
  List<String> _types = [];
  List<String> _modes = [];
  List<String> _arrangements = [];
  final List<_DestRow> _dests = [_DestRow()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final auth = context.read<AuthState>();
    final ss = context.read<SelfServiceState>();
    final repo = SelfServiceRepository(getSession: () => ss.sessionOrNull);
    try {
      final meta = await repo.fetchTravelMeta();
      final emps = await repo.fetchEmployees();
      if (!mounted) return;
      setState(() {
        _ref = (meta['next_reference'] ?? '').toString();
        _types = ((meta['travel_types'] as List?) ?? []).map((e) => e.toString()).toList();
        _modes = ((meta['travel_modes'] as List?) ?? []).map((e) => e.toString()).toList();
        _arrangements =
            ((meta['arrangement_types'] as List?) ?? []).map((e) => e.toString()).toList();
        _employees = emps;
        _employeeId = auth.user?.employeeId;
        _travelType = _types.isNotEmpty ? _types.first : null;
        _start = DateTime.now();
        _end = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ref = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        _types = const ['Domestic', 'International', 'Local', 'Site Visit'];
        _modes = const ['Road', 'Air', 'Rail', 'Bus', 'Other'];
        _arrangements = const ['Company Arranged', 'Self Arranged', 'Client Arranged'];
        _employeeId = auth.user?.employeeId;
        _travelType = 'Domestic';
        _start = DateTime.now();
        _end = DateTime.now();
        _employees = [
          {
            'id': auth.user?.employeeId ?? 1,
            'name': auth.user?.name ?? 'Me',
          }
        ];
      });
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    _expected.dispose();
    _actual.dispose();
    for (final d in _dests) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HrFormShell(
      moduleTitle: 'Travels',
      moduleIcon: Icons.flight_takeoff_rounded,
      formTitle: 'Add New Travel',
      onBack: widget.onBack,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(onPressed: _saving ? null : widget.onBack, child: const Text('Cancel')),
          const SizedBox(width: 10),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Travel'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HrFormSection(
            title: 'Travel Information',
            children: [
              HrFormRow(
                label: 'Reference Number',
                showInfo: false,
                child: Text(_ref.isEmpty ? '—' : _ref,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              HrFormRow(
                label: 'Employee',
                required: true,
                child: HrDropdown<int>(
                  value: _employeeId,
                  hint: 'Select employee',
                  items: _employees
                      .map((e) => DropdownMenuItem(
                            value: (e['id'] as num).toInt(),
                            child: Text((e['name'] ?? '').toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _employeeId = v),
                ),
              ),
              HrFormRow(
                label: 'Travel Type',
                child: HrDropdown<String>(
                  value: _travelType,
                  hint: 'Select type',
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _travelType = v),
                ),
              ),
              HrFormRow(
                label: 'Purpose of Visit',
                required: true,
                child: TextFormField(
                  controller: _purpose,
                  style: hrFieldTextStyle(context),
                  decoration: hrFieldDecoration(context, hint: 'Purpose of Visit'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          HrFormSection(
            title: 'Travel Duration',
            children: [
              HrFormRow(
                label: 'Travel Start Date',
                child: _dateBox(_start, (d) => setState(() => _start = d)),
              ),
              HrFormRow(
                label: 'Travel End Date',
                child: _dateBox(_end, (d) => setState(() => _end = d)),
              ),
            ],
          ),
          HrFormSection(
            title: 'Travel Budget',
            children: [
              HrFormRow(
                label: 'Expected Travel Budget',
                child: TextField(
                  controller: _expected,
                  keyboardType: TextInputType.number,
                  style: hrFieldTextStyle(context),
                  decoration: hrFieldDecoration(context, hint: 'Expected Travel Budget'),
                ),
              ),
              HrFormRow(
                label: 'Actual Travel Budget',
                child: TextField(
                  controller: _actual,
                  keyboardType: TextInputType.number,
                  style: hrFieldTextStyle(context),
                  decoration: hrFieldDecoration(context, hint: 'Actual Travel Budget'),
                ),
              ),
            ],
          ),
          HrFormSection(
            title: 'Travel Destinations (Optional)',
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: HrUi.border(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      color: HrUi.header(context),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: Text('S#', style: TextStyle(color: HrUi.onHeader(context), fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 3, child: Text('Place of Visit', style: TextStyle(color: HrUi.onHeader(context), fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Travel Mode', style: TextStyle(color: HrUi.onHeader(context), fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Arrangement Type', style: TextStyle(color: HrUi.onHeader(context), fontWeight: FontWeight.w700, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Travel Date', style: TextStyle(color: HrUi.onHeader(context), fontWeight: FontWeight.w700, fontSize: 12))),
                          const SizedBox(width: 36),
                        ],
                      ),
                    ),
                    for (var i = 0; i < _dests.length; i++) _destRow(i),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _dests.add(_DestRow())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add destination row'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _destRow(int i) {
    final d = _dests[i];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: HrUi.border(context))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${i + 1}', style: TextStyle(color: HrUi.label(context))),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: d.place,
              style: TextStyle(color: HrUi.label(context), fontSize: 13),
              decoration: hrFieldDecoration(context, hint: 'Place of Visit'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: HrDropdown<String>(
              value: d.mode,
              hint: 'Select Mode',
              items: _modes
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => d.mode = v),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: HrDropdown<String>(
              value: d.arrangement,
              hint: 'Arrangement',
              items: _arrangements
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => d.arrangement = v),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: d.date ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => d.date = picked);
              },
              child: InputDecorator(
                decoration: hrFieldDecoration(context, 
                  hint: 'Date',
                  suffix: const Icon(Icons.calendar_today, size: 16),
                ),
                child: Text(
                  d.date == null ? 'Select' : DateFormat('yyyy-MM-dd').format(d.date!),
                  style: hrFieldTextStyle(context).copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _dests.length == 1
                ? null
                : () => setState(() {
                      _dests.removeAt(i).dispose();
                    }),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(DateTime? value, ValueChanged<DateTime> onPick) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: hrFieldDecoration(context, 
          suffix: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Select date' : DateFormat('yyyy-MM-dd').format(value),
          style: hrFieldTextStyle(context),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_employeeId == null || _purpose.text.trim().isEmpty || _start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee, purpose and dates are required')),
      );
      return;
    }
    setState(() => _saving = true);
    final ss = context.read<SelfServiceState>();
    final err = await ss.applyTravel({
      'employee_id': _employeeId,
      'travel_type': _travelType,
      'purpose': _purpose.text.trim(),
      'start_date': DateFormat('yyyy-MM-dd').format(_start!),
      'end_date': DateFormat('yyyy-MM-dd').format(_end!),
      'expected_budget': double.tryParse(_expected.text) ?? 0,
      'actual_budget': double.tryParse(_actual.text) ?? 0,
      'destinations': _dests
          .map((d) => {
                'place_of_visit': d.place.text.trim(),
                'travel_mode': d.mode,
                'arrangement_type': d.arrangement,
                'travel_date':
                    d.date == null ? null : DateFormat('yyyy-MM-dd').format(d.date!),
              })
          .toList(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Travel saved'), backgroundColor: Color(0xFF10B981)),
    );
    await widget.onSaved();
  }
}
