import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../widgets/hr_form_kit.dart';

class WallOfFameView extends StatefulWidget {
  const WallOfFameView({super.key});

  @override
  State<WallOfFameView> createState() => _WallOfFameViewState();
}

class _WallOfFameViewState extends State<WallOfFameView> {
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);
      final res = await api.dio.get('/insights/accolades');
      final data = res.data;
      if (data is Map && data['success'] == true && mounted) {
        setState(() {
          _rows = ((data['rows'] as List?) ?? []).map(asStringKeyedMap).toList();
          _busy = false;
        });
        return;
      }
    } on DioException {
      // Empty wall is a valid state.
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Wall Of Fame', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HrUi.label(context))),
          const SizedBox(height: 12),
          if (_rows.isEmpty)
            _empty('No achievements have been recorded yet.')
          else
            for (final row in _rows)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFF3E8E4),
                      child: Icon(Icons.emoji_events_outlined, color: Color(0xFF8D6E63)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${row['title']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${row['employee_name']}  ${row['date']}', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class HrGlobeView extends StatefulWidget {
  const HrGlobeView({super.key});

  @override
  State<HrGlobeView> createState() => _HrGlobeViewState();
}

class _HrGlobeViewState extends State<HrGlobeView> {
  late final EmployeeState _state;

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final offices = _state.charts['stations'] ?? [];
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('HR Globe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HrUi.label(context))),
              const SizedBox(height: 6),
              Text('People by office. Each station is a location your company works from.',
                  style: TextStyle(color: HrUi.muted(context))),
              const SizedBox(height: 16),
              if (offices.isEmpty)
                _empty('No offices are assigned yet.')
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final office in offices)
                      Container(
                        width: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.public, color: Color(0xFF2563EB)),
                            const SizedBox(height: 8),
                            Text('${office['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('${office['count']} people', style: const TextStyle(color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class PlaySpaceView extends StatefulWidget {
  const PlaySpaceView({super.key});

  @override
  State<PlaySpaceView> createState() => _PlaySpaceViewState();
}

class _PlaySpaceViewState extends State<PlaySpaceView> {
  int _left = 60;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _left = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left <= 1) {
        t.cancel();
        setState(() => _left = 0);
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.self_improvement, size: 48, color: Color(0xFF8D6E63)),
              const SizedBox(height: 12),
              const Text('One minute break', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(_left == 0 ? 'Break complete.' : '$_left',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _start, child: const Text('Start')),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _empty(String text) {
  return Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Text(text, style: const TextStyle(color: Color(0xFF6B7280))),
  );
}
