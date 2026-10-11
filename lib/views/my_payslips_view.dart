import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/payroll/payroll_state.dart';
import '../core/util/money.dart';
import '../theme/hr_theme.dart';
import '../widgets/company_logo.dart';
import '../widgets/hr_form_kit.dart';
import 'payroll_phase3_view.dart';

final _day = DateFormat('MMMM d, yyyy');

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
          final company = context.watch<AuthState>().company;
          return _PayslipRecord(
            slip: _ps.payslip!,
            currency: company?.currency ?? 'USD',
            companyName: company?.name ?? '',
            clientLogoUrl: AppConfig.resolveMediaUrl(company?.logo),
            canManage: context.watch<AuthState>().user?.isAdmin == true ||
                context.watch<AuthState>().permissions.all,
            onBack: () => setState(() => _openId = null),
            onPrint: () => openPayslipDocument(context, _openId!, download: false),
            onCancel: () => _change('cancel'),
            onReverse: () => _change('reverse'),
          );
        }
        final currency = context.watch<AuthState>().company?.currency ?? 'USD';
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 12),
                Expanded(child: _grid(context, currency)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _grid(BuildContext context, String currency) {
    if (_ps.busy && _ps.myPayslips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ps.myPayslips.isEmpty) {
      return Container(
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
      );
    }
    final brand = HrTheme.brand(context);
    final onBrand = HrTheme.onBrand(context);
    final money = NumberFormat('#,##0.00');
    Widget cell(String text, {bool strong = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Table(
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(1.6),
                3: FlexColumnWidth(2.1),
                4: FlexColumnWidth(1.5),
                5: FixedColumnWidth(88),
                6: FixedColumnWidth(44),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: brand),
                  children: [
                    for (final h in ['#', 'Employee', 'Pay date', 'Period', 'Net (${moneySymbol(currency).trim()})', 'Status', ''])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Text(
                          h,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: onBrand, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _ps.myPayslips.length,
                itemBuilder: (context, i) {
                  final r = _ps.myPayslips[i];
                  final id = (r['id'] as num?)?.toInt() ?? 0;
                  final net = (r['net_salary'] as num?)?.toDouble() ?? 0;
                  return ColoredBox(
                    color: i.isOdd ? brand.withValues(alpha: 0.04) : HrUi.card(context),
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(40),
                        1: FlexColumnWidth(2.2),
                        2: FlexColumnWidth(1.6),
                        3: FlexColumnWidth(2.1),
                        4: FlexColumnWidth(1.5),
                        5: FixedColumnWidth(88),
                        6: FixedColumnWidth(44),
                      },
                      children: [
                        TableRow(
                          children: [
                            cell('${i + 1}'),
                            cell('${r['employee_name'] ?? ''}', strong: true),
                            cell(_fmt(r['date'])),
                            cell(_period(r['period_start'], r['period_end'])),
                            cell(money.format(net), strong: true),
                            cell('${r['status'] ?? 'Processed'}'),
                            PopupMenuButton<String>(
                              tooltip: 'Actions',
                              padding: EdgeInsets.zero,
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _period(dynamic start, dynamic end) {
    final a = DateTime.tryParse('$start');
    final b = DateTime.tryParse('$end');
    if (a == null || b == null) return _fmt(end);
    final short = DateFormat('MMM d');
    if (a.year == b.year && a.month == b.month) {
      return '${short.format(a)} – ${b.day}, ${b.year}';
    }
    return '${short.format(a)} – ${DateFormat('MMM d, y').format(b)}';
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
    required this.companyName,
    required this.clientLogoUrl,
    required this.canManage,
    required this.onBack,
    required this.onPrint,
    required this.onCancel,
    required this.onReverse,
  });

  final Map<String, dynamic> slip;
  final String currency;
  final String companyName;
  final String clientLogoUrl;
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
    final money = NumberFormat.currency(symbol: moneySymbol(currency), decimalDigits: 2);
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
    var earn = 0.0;
    var extra = 0.0;
    var deduct = 0.0;
    for (final line in lines) {
      final allow = n(line['allowance']);
      final ded = n(line['deduction']);
      if (ded > 0) {
        deduct += ded;
      } else if ('${line['code']}'.toUpperCase() == 'BASIC') {
        earn += allow;
      } else if (allow > 0) {
        extra += allow;
      }
    }

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
              ),
              OutlinedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print_outlined, size: 16),
                label: const Text('Print Payslip'),
              ),
              if (canManage && open) OutlinedButton(onPressed: onCancel, child: const Text('Cancel Payslip')),
              if (canManage && open) OutlinedButton(onPressed: onReverse, child: const Text('Reverse Payslip')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Salary Payslip of ${emp['name'] ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 860;
              final sheet = _sheet(context, emp, lines, money, earn, extra, deduct);
              final history = _history(context);
              if (!sideBySide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [sheet, const SizedBox(height: 12), history],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: sheet),
                  const SizedBox(width: 16),
                  SizedBox(width: 280, child: history),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sheet(
    BuildContext context,
    Map<String, dynamic> emp,
    List<Map<String, dynamic>> lines,
    NumberFormat money,
    double earn,
    double extra,
    double deduct,
  ) {
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: HrUi.card(context),
        border: Border.all(color: HrUi.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const CompanyLogo(size: 40),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('HR360', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (clientLogoUrl.isNotEmpty)
                  Image.network(
                    clientLogoUrl,
                    height: 40,
                    width: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      companyName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      companyName.isEmpty ? 'Client' : companyName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          _heading('Salary Payslip Information'),
          _pair('User name', '${emp['name'] ?? '—'}'),
          _pair('Username', '${emp['user_name'] ?? '—'}'),
          _pair('Pay date', _fmt(slip['period_date'])),
          _pair('Job title', '${emp['designation'] ?? '—'}'),
          _pair('Department', '${emp['department'] ?? '—'}'),
          _pair('Station', '${emp['station'] ?? '—'}'),
          _heading('Salary Payslip Period'),
          _pair('Payslip type', 'Monthly (12)'),
          _pair('Start date', _fmt(slip['period_start'])),
          _pair('End date', _fmt(slip['period_end'])),
          _pair('Salary days', '${slip['days'] ?? '—'}'),
          _heading('Salary Items'),
          for (final line in lines)
            _pair(
              '${line['item']}',
              n(line['deduction']) > 0
                  ? '- ${money.format(n(line['deduction']))}'
                  : money.format(n(line['allowance'])),
            ),
          _pair('Gross salary', money.format(earn)),
          _pair('Additional', money.format(extra)),
          _pair('Total deductions', money.format(deduct)),
          _pair('Net salary', money.format(n(slip['net_salary']))),
          _heading('Additional Information'),
          _pair('Record added by', '${slip['created_by_name'] ?? '—'}'),
          _pair('Record added on', _fmt(slip['created_at'])),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _history(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        border: Border.all(color: HrUi.border(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Approval History', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text('Current status: ${slip['status'] ?? 'Processed'}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _fmt(dynamic raw) {
    final d = DateTime.tryParse('$raw');
    if (d == null) return '$raw'.isEmpty || '$raw' == 'null' ? '—' : '$raw';
    return _day.format(d);
  }

  Widget _heading(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF8D6E63),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _pair(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
