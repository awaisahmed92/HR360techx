import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';

/// Attendance Summary tab: present / late / absent, hour gauges, calendar, daily table.
class AttendanceSummaryView extends StatefulWidget {
  const AttendanceSummaryView({super.key});

  @override
  State<AttendanceSummaryView> createState() => _AttendanceSummaryViewState();
}

class _AttendanceSummaryViewState extends State<AttendanceSummaryView> {
  late DateTime _month;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  ApiClient get _api => ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final key = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    try {
      final res = await _api.dio.get('/attendance/summary', queryParameters: {'month': key});
      final data = res.data;
      if (data is Map && data['success'] == true) {
        setState(() {
          _summary = asStringKeyedMap(data['summary']);
          _rows = ((data['rows'] as List?) ?? []).map(asStringKeyedMap).toList();
          _busy = false;
        });
        return;
      }
      setState(() {
        _error = 'Could not load attendance summary.';
        _busy = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'Could not load attendance summary.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final present = _num('present');
    final late = _num('late');
    final absent = _num('absent');
    final avg = _summary['avg_hours']?.toString() ?? '0';
    final timed = _num('timed');
    final under = timed == 0 ? 0.0 : _num('under_9') / timed;
    final mid = timed == 0 ? 0.0 : _num('between') / timed;
    final over = timed == 0 ? 0.0 : _num('over') / timed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() => _month = DateTime(_month.year, _month.month - 1));
                _load();
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Text(_monthLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
            IconButton(
              onPressed: () {
                setState(() => _month = DateTime(_month.year, _month.month + 1));
                _load();
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _kpi('Present Days', '$present', const Color(0xFF22C55E), Icons.person),
            _kpi('Late Arrivals', '$late', const Color(0xFFF59E0B), Icons.schedule),
            _kpi('Absent Days', '$absent', const Color(0xFFEC4899), Icons.person_off_outlined),
            _kpi('Avg. Daily Work Hours', avg, const Color(0xFF0EA5E9), Icons.timer_outlined),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 900;
            final gauges = Row(
              children: [
                Expanded(child: _gauge('Less than 09:00 Hrs', under, const Color(0xFF7C3AED))),
                Expanded(child: _gauge('Between 09:00 to 10:30 Hrs', mid, const Color(0xFF6366F1))),
                Expanded(child: _gauge('More than 10:30 Hrs', over, const Color(0xFF38BDF8))),
              ],
            );
            final cal = _calendar();
            if (!wide) {
              return Column(children: [gauges, const SizedBox(height: 12), cal]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: gauges),
                const SizedBox(width: 12),
                SizedBox(width: 280, child: cal),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _table(),
      ],
    );
  }

  int _num(String key) => int.tryParse('${_summary[key]}') ?? 0;

  String get _monthLabel {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${names[_month.month - 1]} ${_month.year}';
  }

  Widget _kpi(String label, String value, Color color, IconData icon) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 18)),
        ],
      ),
    );
  }

  Widget _gauge(String label, double fraction, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _GaugePainter(fraction.clamp(0, 1), color),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Text('${(fraction * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _calendar() {
    final marked = <int, String>{};
    for (final r in _rows) {
      final date = DateTime.tryParse('${r['date']}');
      if (date == null || date.month != _month.month) continue;
      marked[date.day] = '${r['status_label']}';
    }
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(_monthLabel.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final d in ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'])
                Expanded(child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var day = 1; day <= days; day++)
                Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: marked[day] == null
                          ? null
                          : (marked[day] == 'Absent' ? const Color(0xFFFDA4AF) : const Color(0xFFFBCFE8)),
                      shape: BoxShape.circle,
                    ),
                    child: Text('$day', style: const TextStyle(fontSize: 11)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _table() {
    const head = ['#', 'User', 'Date', 'Day', 'Sign In', 'Sign Out', 'Status', 'Total Time'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF8D6E63)),
          headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          columns: [for (final h in head) DataColumn(label: Text(h))],
          rows: [
            for (var i = 0; i < _rows.length; i++)
              DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text('${_rows[i]['employee_name'] ?? ''}')),
                DataCell(Text('${_rows[i]['date'] ?? ''}')),
                DataCell(Text(_day('${_rows[i]['date']}'))),
                DataCell(Text(_clock('${_rows[i]['punch_in']}'))),
                DataCell(Text(_clock('${_rows[i]['punch_out']}'))),
                DataCell(_statusChip('${_rows[i]['status_label']}')),
                DataCell(Text(_hours(_rows[i]['total_minutes']))),
              ]),
          ],
        ),
      ),
    );
  }

  String _day(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return '';
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[d.weekday - 1];
  }

  String _clock(String raw) {
    if (raw.isEmpty || raw == 'null') return '';
    final d = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (d == null) return raw;
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  String _hours(dynamic mins) {
    final n = int.tryParse('$mins') ?? 0;
    final h = n ~/ 60;
    final m = n % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Widget _statusChip(String label) {
    final absent = label == 'Absent';
    final late = label == 'Late';
    final color = absent ? const Color(0xFFEF4444) : late ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.fraction, this.color);
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = math.min(size.width, size.height) * 0.72;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(rect, math.pi, math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.fraction != fraction || old.color != color;
}
