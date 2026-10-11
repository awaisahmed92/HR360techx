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
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ApiClient(tokenProvider: () async => auth.session?.token);
      final res = await api.dio.get('/system-logs/months');
      final data = res.data;
      final list = data is Map ? data['months'] : null;
      final months = <Map<String, dynamic>>[];
      if (list is List) {
        for (final row in list) {
          if (row is Map) months.add(Map<String, dynamic>.from(row));
        }
      }
      if (!mounted) return;
      setState(() {
        _months = months;
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
