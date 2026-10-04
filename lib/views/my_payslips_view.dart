import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/payroll/payroll_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import 'payroll_phase3_view.dart';

final _money = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 2);
final _day = DateFormat('MMMM d, yyyy');

/// List of processed payslips for the signed-in user (admins see every employee).
class MyPayslipsView extends StatefulWidget {
  const MyPayslipsView({super.key});

  @override
  State<MyPayslipsView> createState() => _MyPayslipsViewState();
}

class _MyPayslipsViewState extends State<MyPayslipsView> {
  late final PayrollState _ps;

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
        DataCell(Text(_money.format(net))),
        DataCell(Text('${r['status'] ?? 'Processed'}')),
        DataCell(TextButton(
          onPressed: id < 1 ? null : () => _open(id),
          child: const Text('View'),
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
    final p = _ps.payslip;
    if (p == null) return;
    final lines = ((p['lines'] as List?) ?? []).map((e) => asLine(e)).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payslip — ${p['employee']?['name'] ?? ''}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p['company']?['name'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Pay date: ${_fmt(p['period_date'])}'),
                Text('Employee code: ${p['employee']?['code'] ?? '—'}'),
                Text('Designation: ${p['employee']?['designation'] ?? '—'}'),
                Text('Project: ${p['project'] ?? '—'}'),
                const SizedBox(height: 12),
                const Text('Salary items', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(child: Text('${line['item']}')),
                        Text(_money.format(_num(line['allowance']))),
                        const SizedBox(width: 12),
                        Text(
                          _num(line['deduction']) == 0
                              ? ''
                              : '- ${_money.format(_num(line['deduction']))}',
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Text('Gross: ${_money.format(_num(p['total_allowance']))}'),
                Text('Tax: ${_money.format(_num(p['tax_amount']))}'),
                Text('EOBI: ${_money.format(_num(p['eobi_amount']))}'),
                Text('Loan: ${_money.format(_num(p['loan_amount']))}'),
                Text('Deductions: ${_money.format(_num(p['total_deduction']))}'),
                const SizedBox(height: 6),
                Text(
                  'Net: ${_money.format(_num(p['net_salary']))}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => openPayslipDocument(context, id, download: false),
            child: const Text('Print'),
          ),
          TextButton(
            onPressed: () => openPayslipDocument(context, id, download: true),
            child: const Text('Download'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Map<String, dynamic> asLine(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    if (e is Map) return e.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;
}
