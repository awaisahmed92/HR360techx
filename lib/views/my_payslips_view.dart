import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/payroll/payroll_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import 'payroll_phase3_view.dart';

final _day = DateFormat('MMMM d, yyyy');

String _money(num value, String currency) =>
    NumberFormat.currency(symbol: '$currency ', decimalDigits: 2).format(value);

/// List of processed payslips for the signed-in user (admins see every employee).
class MyPayslipsView extends StatefulWidget {
  const MyPayslipsView({super.key});

  @override
  State<MyPayslipsView> createState() => _MyPayslipsViewState();
}

class _MyPayslipsViewState extends State<MyPayslipsView> {
  late final PayrollState _ps;
  int? _openId;

  @override
  void initState() {
    super.initState();
    _ps = PayrollState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _ps.loadMyPayslips());
  }

  @override
  void dispose() {
    _ps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ps,
      builder: (context, _) {
        if (_openId != null && _ps.payslip != null) {
          return _PayslipRecord(
            slip: _ps.payslip!,
            currency: context.watch<AuthState>().company?.currency ?? 'USD',
            canManage: context.watch<AuthState>().user?.isAdmin == true ||
                context.watch<AuthState>().permissions.all,
            onBack: () => setState(() => _openId = null),
            onPrint: () => openPayslipDocument(context, _openId!, download: false),
            onCancel: () => _change('cancel'),
            onReverse: () => _change('reverse'),
          );
        }
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Salary Payslips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HrUi.label(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Open a processed payslip to view the salary items, print it, or download it.',
                style: TextStyle(color: HrUi.muted(context), fontSize: 13),
              ),
              if (_ps.error != null) ...[
                const SizedBox(height: 8),
                Text(_ps.error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 16),
              if (_ps.busy && _ps.myPayslips.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_ps.myPayslips.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: HrUi.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HrUi.border(context)),
                  ),
                  child: Text(
                    'No payslips yet. They appear here after payroll is processed for you.',
                    style: TextStyle(color: HrUi.muted(context)),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: HrUi.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HrUi.border(context)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(HrTheme.brand(context)),
                      headingTextStyle: TextStyle(
                        color: HrTheme.onBrand(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Employee')),
                        DataColumn(label: Text('Pay date')),
                        DataColumn(label: Text('Period start')),
                        DataColumn(label: Text('Period end')),
                        DataColumn(label: Text('Net salary')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (var i = 0; i < _ps.myPayslips.length; i++)
                          _row(context, i + 1, _ps.myPayslips[i]),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  DataRow _row(BuildContext context, int index, Map<String, dynamic> r) {
    final id = (r['id'] as num?)?.toInt() ?? 0;
    final net = (r['net_salary'] as num?)?.toDouble() ?? 0;
    return DataRow(
      cells: [
        DataCell(Text('$index')),
        DataCell(Text('${r['employee_name'] ?? ''}')),
        DataCell(Text(_fmt(r['date']))),
        DataCell(Text(_fmt(r['period_start']))),
        DataCell(Text(_fmt(r['period_end']))),
        DataCell(Text(_money(net, context.watch<AuthState>().company?.currency ?? 'USD'))),
        DataCell(Text('${r['status'] ?? 'Processed'}')),
        DataCell(PopupMenuButton<String>(
          tooltip: 'Actions',
          onSelected: (value) {
            if (value == 'view') {
              _open(id);
            } else if (value == 'print') {
              openPayslipDocument(context, id, download: false);
            } else if (value == 'cancel' || value == 'reverse') {
              _change(value, id);
            }
          },
          itemBuilder: (_) {
            final manage = context.read<AuthState>().user?.isAdmin == true ||
                context.read<AuthState>().permissions.all;
            final open = '${r['slip_status'] ?? 'processed'}' == 'processed';
            return [
              const PopupMenuItem(value: 'view', child: Text('View Record')),
              const PopupMenuItem(value: 'print', child: Text('Print Payslip')),
              if (manage && open) const PopupMenuItem(value: 'cancel', child: Text('Cancel Payslip')),
              if (manage && open) const PopupMenuItem(value: 'reverse', child: Text('Reverse Payslip')),
            ];
          },
        )),
      ],
    );
  }

  String _fmt(dynamic raw) {
    final s = '$raw';
    final d = DateTime.tryParse(s);
    if (d == null) return s;
    return _day.format(d);
  }

  Future<void> _open(int id) async {
    final err = await _ps.loadPayslip(id);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _openId = id);
  }

  Future<void> _change(String action, [int? id]) async {
    final slipId = id ?? _openId ?? 0;
    if (slipId < 1) return;
    final err = await _ps.setPayslipStatus(slipId, action);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (_openId != null) {
      await _ps.loadPayslip(slipId);
    }
    if (!mounted) return;
    setState(() {});
  }

}

class _PayslipRecord extends StatelessWidget {
  const _PayslipRecord({
    required this.slip,
    required this.currency,
    required this.canManage,
    required this.onBack,
    required this.onPrint,
    required this.onCancel,
    required this.onReverse,
  });

  final Map<String, dynamic> slip;
  final String currency;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onPrint;
  final VoidCallback onCancel;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final emp = slip['employee'] is Map
        ? (slip['employee'] as Map).map((k, v) => MapEntry('$k', v))
        : <String, dynamic>{};
    final lines = ((slip['lines'] as List?) ?? []).map((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return e.map((k, v) => MapEntry('$k', v));
      return <String, dynamic>{};
    }).toList();
    final status = '${slip['slip_status'] ?? 'processed'}';
    final open = status == 'processed';
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('Print Payslip'),
              ),
              if (canManage && open) ...[
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onCancel, child: const Text('Cancel Payslip')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onReverse, child: const Text('Reverse Payslip')),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Salary Payslip of ${emp['name'] ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Current status: ${slip['status'] ?? 'Processed'}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          _block(context, 'Salary Payslip Information', [
            _pair('User name', '${emp['name'] ?? '—'}'),
            _pair('Username', '${emp['user_name'] ?? '—'}'),
            _pair('Pay date', _fmt(slip['period_date'])),
            _pair('Status', '${slip['status'] ?? 'Processed'}'),
          ]),
          _block(context, 'Salary Payslip Period', [
            _pair('Payslip type', 'Monthly (12)'),
            _pair('Start date', _fmt(slip['period_start'])),
            _pair('End date', _fmt(slip['period_end'])),
            _pair('Salary days', '${slip['days'] ?? '—'}'),
          ]),
          _block(context, 'Salary Items', [
            for (final line in lines)
              _pair(
                '${line['item']}',
                n(line['deduction']) > 0
                    ? '- ${_money(n(line['deduction']), currency)}'
                    : _money(n(line['allowance']), currency),
              ),
            _pair('Total allowance', _money(n(slip['total_allowance']), currency)),
            _pair('Total deduction', _money(n(slip['total_deduction']), currency)),
            _pair('Net salary', _money(n(slip['net_salary']), currency)),
          ]),
          _block(context, 'Additional Information', [
            _pair('Record added by', '${slip['created_by_name'] ?? '—'}'),
            _pair('Record added on', _fmt(slip['created_at'])),
            _pair('Station', '${emp['station'] ?? '—'}'),
            _pair('Department', '${emp['department'] ?? '—'}'),
            _pair('Job title', '${emp['designation'] ?? '—'}'),
          ]),
        ],
      ),
    );
  }

  String _fmt(dynamic raw) {
    final d = DateTime.tryParse('$raw');
    if (d == null) return '$raw'.isEmpty || '$raw' == 'null' ? '—' : '$raw';
    return _day.format(d);
  }

  Widget _block(BuildContext context, String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        border: Border.all(color: HrUi.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _pair(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
