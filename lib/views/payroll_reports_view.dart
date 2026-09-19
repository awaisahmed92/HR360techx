import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// PHP-parity payroll reports: structure, sheet, certificate, statement.
class PayrollReportsView extends StatefulWidget {
  const PayrollReportsView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<PayrollReportsView> createState() => _PayrollReportsViewState();
}

class _PayrollReportsViewState extends State<PayrollReportsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _structure = [];
  List<Map<String, dynamic>> _sheet = [];
  int? _employeeId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.clamp(0, 3));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  ApiClient get _api {
    final auth = context.read<AuthState>();
    return ApiClient(tokenProvider: () async => auth.session?.token);
  }

  Future<void> _bootstrap() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final meta = await _api.dio.get('/payroll/meta');
      final md = meta.data;
      if (md is Map && md['success'] == true) {
        final emps = ((asStringKeyedMap(md['meta'])['employees'] as List?) ?? []);
        _employees = emps.map((e) => asStringKeyedMap(e)).toList();
        if (_employees.isNotEmpty && _employeeId == null) {
          _employeeId = (_employees.first['id'] as num?)?.toInt() ??
              (_employees.first['employee_id'] as num?)?.toInt();
        }
      }
      await Future.wait([_loadStructure(), _loadSheet()]);
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _loadStructure() async {
    final res = await _api.dio.get('/payroll/salary-structure');
    final d = res.data;
    if (d is Map && d['success'] == true) {
      _structure = ((d['rows'] as List?) ?? []).map((e) => asStringKeyedMap(e)).toList();
    }
  }

  Future<void> _loadSheet() async {
    final end = DateTime(_month.year, _month.month + 1, 0);
    final date =
        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final res = await _api.dio.get('/payroll/salary-sheet', queryParameters: {'date': date});
    final d = res.data;
    if (d is Map && d['success'] == true) {
      final sheet = d['sheet'];
      if (sheet is Map && sheet['rows'] is List) {
        _sheet = (sheet['rows'] as List).map((e) => asStringKeyedMap(e)).toList();
      } else if (sheet is List) {
        _sheet = sheet.map((e) => asStringKeyedMap(e)).toList();
      }
    }
  }

  Future<void> _openHtml(String path, Map<String, dynamic> q) async {
    final auth = context.read<AuthState>();
    final token = auth.session?.token ?? '';
    final qs = {
      ...q.map((k, v) => MapEntry(k, '$v')),
      if (token.isNotEmpty) 'access_token': token,
    };
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: qs);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Payroll Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: HrUi.label(context),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            labelColor: HrTheme.brand(context),
            tabs: const [
              Tab(text: 'Salary Structure'),
              Tab(text: 'Salary Sheet'),
              Tab(text: 'Salary Certificate'),
              Tab(text: 'Salary Statement'),
            ],
          ),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _structureTab(),
                      _sheetTab(),
                      _certificateTab(),
                      _statementTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _structureTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        HrFormSection(
          title: 'Defined salary structures',
          children: [
            if (_structure.isEmpty)
              const Text('No define-salary rows yet.')
            else
              HrFitDataTableHost(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(HrTheme.brand(context)),
                  headingTextStyle: TextStyle(color: HrTheme.onBrand(context), fontWeight: FontWeight.w600),
                  columnSpacing: 14,
                  horizontalMargin: 10,
                  columns: const [
                    DataColumn(label: Text('Employee')),
                    DataColumn(label: Text('Basic')),
                    DataColumn(label: Text('Allowances')),
                    DataColumn(label: Text('Deductions')),
                    DataColumn(label: Text('Net')),
                  ],
                  rows: _structure
                      .map(
                        (r) => DataRow(cells: [
                          DataCell(Text('${r['employee_name'] ?? r['name'] ?? r['employee_id']}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text('${r['basic_salary'] ?? 0}')),
                          DataCell(Text('${r['total_allowance'] ?? 0}')),
                          DataCell(Text('${r['total_deduction'] ?? 0}')),
                          DataCell(Text('${r['net_salary'] ?? 0}')),
                        ]),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _sheetTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _month,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) {
                  setState(() => _month = DateTime(picked.year, picked.month, 1));
                  setState(() => _busy = true);
                  await _loadSheet();
                  if (mounted) setState(() => _busy = false);
                }
              },
              icon: const Icon(Icons.calendar_month),
              label: Text('${_month.year}-${_month.month.toString().padLeft(2, '0')}'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                setState(() => _busy = true);
                await _loadSheet();
                if (mounted) setState(() => _busy = false);
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        HrFormSection(
          title: 'Salary sheet',
          children: [
            if (_sheet.isEmpty)
              const Text('No processed rows for this month.')
            else
              HrFitDataTableHost(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(HrTheme.brand(context)),
                  headingTextStyle: TextStyle(color: HrTheme.onBrand(context), fontWeight: FontWeight.w600),
                  columnSpacing: 14,
                  horizontalMargin: 10,
                  columns: const [
                    DataColumn(label: Text('Employee')),
                    DataColumn(label: Text('Days')),
                    DataColumn(label: Text('Gross')),
                    DataColumn(label: Text('Tax')),
                    DataColumn(label: Text('Net')),
                  ],
                  rows: _sheet
                      .map(
                        (r) => DataRow(cells: [
                          DataCell(Text('${r['employee_name'] ?? r['name'] ?? r['employee_id']}', overflow: TextOverflow.ellipsis)),
                          DataCell(Text('${r['days'] ?? ''}')),
                          DataCell(Text('${r['total_allowance'] ?? 0}')),
                          DataCell(Text('${r['tax_amount'] ?? 0}')),
                          DataCell(Text('${r['net_salary'] ?? 0}')),
                        ]),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _certificateTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        HrFormSection(
          title: 'Salary Certificate',
          children: [
            DropdownButtonFormField<int>(
              value: _employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: _employees
                  .map((e) {
                    final id = (e['id'] as num?)?.toInt() ??
                        (e['employee_id'] as num?)?.toInt() ??
                        0;
                    return DropdownMenuItem(
                      value: id,
                      child: Text('${e['name'] ?? e['label'] ?? id}'),
                    );
                  })
                  .where((i) => (i.value ?? 0) > 0)
                  .toList(),
              onChanged: (v) => setState(() => _employeeId = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _employeeId == null
                  ? null
                  : () => _openHtml('/payroll/salary-certificate', {
                        'employee_id': _employeeId!,
                      }),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Open Certificate'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statementTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        HrFormSection(
          title: 'Salary Statement',
          children: [
            DropdownButtonFormField<int>(
              value: _employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: _employees
                  .map((e) {
                    final id = (e['id'] as num?)?.toInt() ??
                        (e['employee_id'] as num?)?.toInt() ??
                        0;
                    return DropdownMenuItem(
                      value: id,
                      child: Text('${e['name'] ?? e['label'] ?? id}'),
                    );
                  })
                  .where((i) => (i.value ?? 0) > 0)
                  .toList(),
              onChanged: (v) => setState(() => _employeeId = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _employeeId == null
                  ? null
                  : () => _openHtml('/payroll/salary-statement', {
                        'employee_id': _employeeId!,
                      }),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Open Statement'),
            ),
          ],
        ),
      ],
    );
  }
}
