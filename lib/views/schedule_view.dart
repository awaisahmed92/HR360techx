import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/attendance/attendance_admin_state.dart';
import '../core/auth/auth_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Weekly org schedule editor (PHP Schedule.php parity).
class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late final AttendanceAdminState _state;
  final Map<int, TextEditingController> _start = {};
  final Map<int, TextEditingController> _end = {};
  final Map<int, TextEditingController> _break = {};
  final Map<int, bool> _off = {};

  @override
  void initState() {
    super.initState();
    _state = AttendanceAdminState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _state.loadSchedule();
      _bind();
    });
  }

  void _bind() {
    for (final c in [..._start.values, ..._end.values, ..._break.values]) {
      c.dispose();
    }
    _start.clear();
    _end.clear();
    _break.clear();
    _off.clear();
    for (final r in _state.schedule) {
      final id = (r['id'] as num).toInt();
      _start[id] = TextEditingController(text: '${r['start_time'] ?? '09:00'}');
      _end[id] = TextEditingController(text: '${r['end_time'] ?? '18:00'}');
      _break[id] = TextEditingController(text: '${r['break_minutes'] ?? 60}');
      _off[id] = r['is_off_day'] == true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [..._start.values, ..._end.values, ..._break.values]) {
      c.dispose();
    }
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text('Work Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      )),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                    onPressed: () async {
                      final rows = _state.schedule.map((r) {
                        final id = (r['id'] as num).toInt();
                        return {
                          'id': id,
                          'start_time': _start[id]?.text ?? '09:00',
                          'end_time': _end[id]?.text ?? '18:00',
                          'break_minutes': int.tryParse(_break[id]?.text ?? '0') ?? 0,
                          'is_off_day': _off[id] ?? false,
                        };
                      }).toList();
                      final err = await _state.saveSchedule(rows);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(err ?? 'Schedule saved')),
                      );
                      if (err == null) _bind();
                    },
                    child: const Text('Save Schedule'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Weekly hours used for late / off-day / attendance status.',
                  style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
              const SizedBox(height: 16),
              if (_state.error != null)
                Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
              if (_state.busy && _state.schedule.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                ..._state.schedule.map((r) {
                  final id = (r['id'] as num).toInt();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text('${r['day']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Checkbox(
                            value: _off[id] ?? false,
                            onChanged: (v) => setState(() => _off[id] = v ?? false),
                          ),
                          const Text('Off'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _start[id],
                              decoration: const InputDecoration(labelText: 'Start', isDense: true),
                              enabled: !(_off[id] ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _end[id],
                              decoration: const InputDecoration(labelText: 'End', isDense: true),
                              enabled: !(_off[id] ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: _break[id],
                              decoration: const InputDecoration(labelText: 'Break', isDense: true),
                              keyboardType: TextInputType.number,
                              enabled: !(_off[id] ?? false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
