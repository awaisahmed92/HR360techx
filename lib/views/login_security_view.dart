import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/network/api_client.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/hr_grid_query.dart';

/// Organization settings: tabbed grids for login attempts, suspicious activity,
/// account locks, and IP blocks.
class LoginSecurityView extends StatefulWidget {
  const LoginSecurityView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LoginSecurityView> createState() => _LoginSecurityViewState();
}

class _LoginSecurityViewState extends State<LoginSecurityView> {
  static const _tabs = [
    'Overview',
    'Login Attempts',
    'Suspicious',
    'Account Locks',
    'IP Blocks',
  ];

  int _tab = 0;
  bool _busy = true;
  String? _error;
  String _query = '';
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _ipBlocks = [];
  List<Map<String, dynamic>> _locks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthState>();
    if (auth.isDemo) {
      setState(() {
        _busy = false;
        _error = null;
        _attempts = [
          {
            'created_at': '2026-11-26 10:12:00',
            'ip': '203.0.113.10',
            'username': 'admin',
            'success': false,
            'reason': 'bad_password',
            'suspicious': true,
            'user_agent': 'Chrome / Windows',
          },
          {
            'created_at': '2026-11-26 09:40:00',
            'ip': '203.0.113.10',
            'username': 'admin',
            'success': false,
            'reason': 'rate_limited',
            'suspicious': true,
            'user_agent': 'Chrome / Windows',
          },
          {
            'created_at': '2026-11-26 09:01:00',
            'ip': '198.51.100.22',
            'username': 'admin',
            'success': true,
            'reason': 'ok',
            'suspicious': false,
            'user_agent': 'Chrome / Windows',
          },
          {
            'created_at': '2026-11-25 18:22:00',
            'ip': '192.0.2.55',
            'username': 'hr.manager',
            'success': false,
            'reason': 'bad_password',
            'suspicious': false,
            'user_agent': 'Safari / macOS',
          },
        ];
        _ipBlocks = [
          {
            'ip': '203.0.113.10',
            'reason': 'Repeated failed logins',
            'blocked_until': '2026-11-26 12:00:00',
          },
        ];
        _locks = [
          {
            'username': 'admin',
            'fail_count': 5,
            'locked_until': '2026-11-26 11:00:00',
          },
        ];
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ApiClient(tokenProvider: () async => auth.session?.token);
      final res = await api.dio.get('/auth/security/activity');
      final data = res.data;
      final attempts = <Map<String, dynamic>>[];
      final blocks = <Map<String, dynamic>>[];
      final locks = <Map<String, dynamic>>[];
      if (data is Map && data['success'] == true) {
        for (final row in ((data['attempts'] as List?) ?? const [])) {
          if (row is Map) attempts.add(Map<String, dynamic>.from(row));
        }
        for (final row in ((data['ip_blocks'] as List?) ?? const [])) {
          if (row is Map) blocks.add(Map<String, dynamic>.from(row));
        }
        for (final row in ((data['account_locks'] as List?) ?? const [])) {
          if (row is Map) locks.add(Map<String, dynamic>.from(row));
        }
      }
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _ipBlocks = blocks;
        _locks = locks;
        _busy = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      final msg = body is Map && body['message'] != null
          ? body['message'].toString()
          : 'Could not load login security activity.';
      setState(() {
        _busy = false;
        _error = msg;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not load login security activity.';
      });
    }
  }

  Future<void> _unblock(String ip) async {
    final auth = context.read<AuthState>();
    final api = ApiClient(tokenProvider: () async => auth.session?.token);
    try {
      await api.dio.post('/auth/security/unblock-ip', data: {'ip': ip});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unblocked $ip')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not unblock IP.')),
      );
    }
  }

  Future<void> _unlock(String username) async {
    final auth = context.read<AuthState>();
    final api = ApiClient(tokenProvider: () async => auth.session?.token);
    try {
      await api.dio.post('/auth/security/unlock-account', data: {
        'username': username,
        'subdomain': auth.company?.subdomain,
      });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unlocked $username')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not unlock account.')),
      );
    }
  }

  List<Map<String, dynamic>> get _suspiciousAttempts =>
      _attempts.where((a) => a['suspicious'] == true).toList();

  List<Map<String, dynamic>> get _failedAttempts =>
      _attempts.where((a) => a['success'] != true).toList();

  List<Map<String, dynamic>> get _successAttempts =>
      _attempts.where((a) => a['success'] == true).toList();

  List<Map<String, dynamic>> _searchRows(List<Map<String, dynamic>> rows) {
    final q = hrSearchQuery(context, _query);
    if (q.isEmpty) return rows;
    return rows.where((a) {
      final hay =
          '${a['created_at']} ${a['ip']} ${a['username']} ${a['reason']} ${a['user_agent']} ${a['blocked_until']} ${a['locked_until']} ${a['fail_count']}';
      return hrMatchesQuery(hay, q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.embedded ? Colors.transparent : HrUi.pageBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 0 : 24,
              widget.embedded ? 0 : 16,
              widget.embedded ? 0 : 24,
              0,
            ),
            child: Row(
              children: [
                if (!widget.embedded) ...[
                  Icon(Icons.security_outlined, size: 18, color: HrUi.sectionTitle(context)),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.embedded ? 'Login security' : 'Login Security',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: widget.embedded ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: HrUi.sectionTitle(context),
                  ),
                ),
                const Spacer(),
                HrSearchField(
                  value: hrSearchQuery(context, _query),
                  hint: 'Search grids',
                  width: 220,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _load,
                  icon: Icon(Icons.refresh, color: HrUi.muted(context)),
                ),
              ],
            ),
          ),
          if (!widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Text(
                'Monitor login attempts, suspicious activity, locked accounts, and blocked IPs for this organization.',
                style: TextStyle(color: HrUi.muted(context), fontSize: 13),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(
              widget.embedded ? 0 : 24,
              12,
              widget.embedded ? 0 : 24,
              0,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_tabLabel(i)),
                      selected: _tab == i,
                      selectedColor: HrTheme.brand(context),
                      labelStyle: TextStyle(
                        color: _tab == i ? HrTheme.onBrand(context) : HrUi.label(context),
                        fontWeight: FontWeight.w600,
                      ),
                      checkmarkColor: HrTheme.onBrand(context),
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                widget.embedded ? 0 : 24,
                0,
                widget.embedded ? 0 : 24,
                widget.embedded ? 0 : 24,
              ),
              child: _busy
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorPane()
                      : switch (_tab) {
                          0 => _overviewTab(),
                          1 => _attemptsGrid(_searchRows(_attempts), includeSuspiciousCol: true),
                          2 => _attemptsGrid(_searchRows(_suspiciousAttempts), includeSuspiciousCol: false),
                          3 => _locksGrid(_searchRows(_locks)),
                          _ => _blocksGrid(_searchRows(_ipBlocks)),
                        },
            ),
          ),
        ],
      ),
    );
  }

  String _tabLabel(int i) {
    final count = switch (i) {
      0 => null,
      1 => _attempts.length,
      2 => _suspiciousAttempts.length,
      3 => _locks.length,
      _ => _ipBlocks.length,
    };
    if (count == null) return _tabs[i];
    return '${_tabs[i]} ($count)';
  }

  Widget _errorPane() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: TextStyle(color: HrUi.muted(context))),
          const SizedBox(height: 10),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _overviewTab() {
    return ListView(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _statCard('Login attempts', '${_attempts.length}', HrTheme.brand(context), Icons.login),
            _statCard('Failed', '${_failedAttempts.length}', Colors.orange.shade700, Icons.cancel_outlined),
            _statCard('Suspicious', '${_suspiciousAttempts.length}', Colors.red.shade700, Icons.warning_amber_rounded),
            _statCard('Successful', '${_successAttempts.length}', Colors.green.shade700, Icons.check_circle_outline),
            _statCard('Account locks', '${_locks.length}', Colors.deepOrange, Icons.lock_outline),
            _statCard('IP blocks', '${_ipBlocks.length}', Colors.blueGrey, Icons.block),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Why this matters',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: HrUi.sectionTitle(context),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'HR admins can spot brute-force attempts, unlock staff accounts after lockouts, and clear blocked IPs without waiting for support.',
          style: TextStyle(color: HrUi.muted(context), fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_locks.isNotEmpty) ...[
          _quickSection(
            'Active account locks',
            child: _locksGrid(_locks.take(5).toList(), compact: true),
          ),
          const SizedBox(height: 12),
        ],
        if (_ipBlocks.isNotEmpty) ...[
          _quickSection(
            'Active IP blocks',
            child: _blocksGrid(_ipBlocks.take(5).toList(), compact: true),
          ),
          const SizedBox(height: 12),
        ],
        _quickSection(
          'Latest suspicious activity',
          child: _attemptsGrid(
            _suspiciousAttempts.take(8).toList(),
            includeSuspiciousCol: false,
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _quickSection(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: HrUi.sectionTitle(context),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 260, child: child),
      ],
    );
  }

  Widget _statCard(String label, String value, Color accent, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: HrUi.muted(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attemptsGrid(
    List<Map<String, dynamic>> rows, {
    required bool includeSuspiciousCol,
    bool compact = false,
  }) {
    if (rows.isEmpty) return _empty('No login attempts in this view.');
    final columns = <DataColumn>[
      const DataColumn(label: Text('When')),
      const DataColumn(label: Text('User')),
      const DataColumn(label: Text('IP')),
      const DataColumn(label: Text('Result')),
      const DataColumn(label: Text('Reason')),
      if (includeSuspiciousCol) const DataColumn(label: Text('Flag')),
      const DataColumn(label: Text('Device / browser')),
    ];
    return _gridShell(
      compact: compact,
      child: HrPagedDataTable(
        headingRowColor: WidgetStateProperty.all(HrTheme.brand(context)),
        headingTextStyle: TextStyle(
          color: HrTheme.onBrand(context),
          fontWeight: FontWeight.w600,
        ),
        columnSpacing: 16,
        horizontalMargin: 12,
        columns: columns,
        rows: [
          for (final a in rows)
            DataRow(
              color: a['suspicious'] == true
                  ? WidgetStateProperty.all(Colors.red.withValues(alpha: 0.06))
                  : null,
              cells: [
                DataCell(Text('${a['created_at'] ?? ''}', style: const TextStyle(fontSize: 12.5))),
                DataCell(Text('${a['username'] ?? '—'}')),
                DataCell(Text('${a['ip'] ?? ''}')),
                DataCell(_resultChip(a['success'] == true, a['suspicious'] == true)),
                DataCell(Text('${a['reason'] ?? '—'}', overflow: TextOverflow.ellipsis)),
                if (includeSuspiciousCol)
                  DataCell(
                    a['suspicious'] == true
                        ? Text('Suspicious', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 12))
                        : Text('—', style: TextStyle(color: HrUi.muted(context))),
                  ),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      '${a['user_agent'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: HrUi.muted(context)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _locksGrid(List<Map<String, dynamic>> rows, {bool compact = false}) {
    if (rows.isEmpty) return _empty('No locked accounts right now.');
    return _gridShell(
      compact: compact,
      child: HrPagedDataTable(
        headingRowColor: WidgetStateProperty.all(HrTheme.brand(context)),
        headingTextStyle: TextStyle(
          color: HrTheme.onBrand(context),
          fontWeight: FontWeight.w600,
        ),
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('Username')),
          DataColumn(label: Text('Fail count')),
          DataColumn(label: Text('Locked until')),
          DataColumn(label: Text('Action')),
        ],
        rows: [
          for (final lock in rows)
            DataRow(cells: [
              DataCell(Text('${lock['username'] ?? ''}')),
              DataCell(Text('${lock['fail_count'] ?? 0}')),
              DataCell(Text('${lock['locked_until'] ?? ''}')),
              DataCell(
                TextButton(
                  onPressed: () => _unlock('${lock['username']}'),
                  child: const Text('Unlock'),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _blocksGrid(List<Map<String, dynamic>> rows, {bool compact = false}) {
    if (rows.isEmpty) return _empty('No blocked IPs right now.');
    return _gridShell(
      compact: compact,
      child: HrPagedDataTable(
        headingRowColor: WidgetStateProperty.all(HrTheme.brand(context)),
        headingTextStyle: TextStyle(
          color: HrTheme.onBrand(context),
          fontWeight: FontWeight.w600,
        ),
        columnSpacing: 18,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('IP address')),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Blocked until')),
          DataColumn(label: Text('Action')),
        ],
        rows: [
          for (final b in rows)
            DataRow(cells: [
              DataCell(Text('${b['ip'] ?? ''}')),
              DataCell(Text('${b['reason'] ?? ''}', overflow: TextOverflow.ellipsis)),
              DataCell(Text('${b['blocked_until'] ?? ''}')),
              DataCell(
                TextButton(
                  onPressed: () => _unblock('${b['ip']}'),
                  child: const Text('Unblock'),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _gridShell({required Widget child, bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: compact
          ? SingleChildScrollView(child: child)
          : child,
    );
  }

  Widget _resultChip(bool success, bool suspicious) {
    final label = suspicious ? 'Suspicious' : (success ? 'Success' : 'Failed');
    final color = suspicious
        ? Colors.red.shade700
        : (success ? Colors.green.shade700 : Colors.orange.shade800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Text(text, style: TextStyle(color: HrUi.muted(context))),
    );
  }
}
