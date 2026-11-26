import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/hr_grid_query.dart';

/// System logs as one Excel file per month, with the change details inside the file.
class SystemLogsView extends StatefulWidget {
  const SystemLogsView({super.key});

  @override
  State<SystemLogsView> createState() => _SystemLogsViewState();
}

class _SystemLogsViewState extends State<SystemLogsView> {
  bool _busy = true;
  String? _error;
  List<Map<String, dynamic>> _months = [];
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _ipBlocks = [];
  String _query = '';

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
        _months = [
          {
            'month': '2026-10',
            'label': 'October 2026',
            'records': 12,
            'file': 'System-Logs-October-2026.xlsx',
          },
        ];
        _attempts = const [];
        _ipBlocks = const [];
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ApiClient(tokenProvider: () async => auth.session?.token);
      final results = await Future.wait([
        api.dio.get('/system-logs/months'),
        api.dio.get('/auth/security/activity'),
      ]);
      final data = results[0].data;
      final list = data is Map ? data['months'] : null;
      final months = <Map<String, dynamic>>[];
      if (list is List) {
        for (final row in list) {
          if (row is Map) months.add(Map<String, dynamic>.from(row));
        }
      }
      final sec = results[1].data;
      final attempts = <Map<String, dynamic>>[];
      final blocks = <Map<String, dynamic>>[];
      if (sec is Map && sec['success'] == true) {
        for (final row in ((sec['attempts'] as List?) ?? const [])) {
          if (row is Map) attempts.add(Map<String, dynamic>.from(row));
        }
        for (final row in ((sec['ip_blocks'] as List?) ?? const [])) {
          if (row is Map) blocks.add(Map<String, dynamic>.from(row));
        }
      }
      if (!mounted) return;
      setState(() {
        _months = months;
        _attempts = attempts;
        _ipBlocks = blocks;
        _busy = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final body = e.response?.data;
      final msg = body is Map && body['message'] != null
          ? body['message'].toString()
          : 'Could not load system logs.';
      setState(() {
        _busy = false;
        _error = msg;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not load system logs.';
      });
    }
  }

  Future<void> _unblock(String ip) async {
    final auth = context.read<AuthState>();
    final api = ApiClient(tokenProvider: () async => auth.session?.token);
    try {
      await api.dio.post('/auth/security/unblock-ip', data: {'ip': ip});
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not unblock IP.')));
    }
  }

  Future<void> _download(Map<String, dynamic> month) async {
    final auth = context.read<AuthState>();
    if (auth.isDemo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect the API to download the Excel file.')),
      );
      return;
    }
    final key = '${month['month'] ?? ''}';
    final token = auth.session?.token ?? '';
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/system-logs/export'
      '?month=${Uri.encodeQueryComponent(key)}'
      '&access_token=${Uri.encodeQueryComponent(token)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open manually: $uri')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = hrSearchQuery(context, _query);
    final shown = _months.where((m) {
      final hay = '${m['label']} ${m['file']} ${m['records']}';
      return hrMatchesQuery(hay, query);
    }).toList();

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: HrUi.sectionTitle(context)),
              const SizedBox(width: 8),
              Text(
                'System Logs',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HrUi.sectionTitle(context),
                ),
              ),
              const Spacer(),
              HrSearchField(
                value: query,
                hint: 'Search month',
                width: 240,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _load,
                icon: Icon(Icons.refresh, color: HrUi.muted(context)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Each month is one Excel file. Download it to see who changed a record and the field values.',
            style: TextStyle(color: HrUi.muted(context), fontSize: 13),
          ),
          const SizedBox(height: 16),
          _securityPanel(),
          const SizedBox(height: 20),
          Text(
            'Monthly change logs',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: HrUi.sectionTitle(context)),
          ),
          const SizedBox(height: 10),
          hrQueryBanner(context, query, shown.length, onClear: () => setState(() => _query = '')),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _message(
              _error!,
              action: FilledButton(
                style: HrTheme.filledButton(context),
                onPressed: _load,
                child: const Text('Retry'),
              ),
            )
          else if (shown.isEmpty)
            _message(query.trim().isEmpty ? 'No system logs yet.' : 'No monthly file matches that search.')
          else
            ...shown.map((m) => _fileCard(m, query.trim().isNotEmpty)),
        ],
      ),
    );
  }

  Widget _securityPanel() {
    final suspicious = _attempts.where((a) => a['suspicious'] == true || a['success'] != true).take(25).toList();
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.security_outlined, size: 18, color: HrTheme.brand(context)),
              const SizedBox(width: 8),
              Text(
                'Login security',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: HrUi.sectionTitle(context)),
              ),
              const Spacer(),
              Text('${_ipBlocks.length} IP block(s)', style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Failed logins, account lockouts, captcha challenges, and blocked IPs.',
            style: TextStyle(color: HrUi.muted(context), fontSize: 12.5),
          ),
          if (_ipBlocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final b in _ipBlocks)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block, color: Colors.redAccent, size: 18),
                title: Text('${b['ip']}'),
                subtitle: Text('${b['reason']} · until ${b['blocked_until']}'),
                trailing: TextButton(onPressed: () => _unblock('${b['ip']}'), child: const Text('Unblock')),
              ),
          ],
          const SizedBox(height: 8),
          if (suspicious.isEmpty)
            Text('No recent failed or suspicious login activity.', style: TextStyle(color: HrUi.muted(context), fontSize: 12.5))
          else
            for (final a in suspicious)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${a['created_at']} · ${a['ip']} · ${a['subdomain']}/${a['username']} · ${a['reason']}${a['suspicious'] == true ? ' · suspicious' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: a['suspicious'] == true ? Colors.red.shade700 : HrUi.label(context),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _fileCard(Map<String, dynamic> month, bool highlighted) {
    final label = '${month['label'] ?? month['month'] ?? ''}';
    final file = '${month['file'] ?? 'System-Logs.xlsx'}';
    final records = (month['records'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: highlighted ? hrMatchRowColor : HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _download(month),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: highlighted ? const Color(0xFFF5D36A) : HrUi.border(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF217346),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.grid_on_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: HrUi.label(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        file,
                        style: TextStyle(color: HrUi.muted(context), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$records ${records == 1 ? 'entry' : 'entries'}',
                  style: TextStyle(color: HrUi.muted(context), fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: HrTheme.filledButton(context),
                  onPressed: () => _download(month),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.folder_open_outlined, size: 36, color: HrUi.muted(context)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: HrUi.muted(context))),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}
