import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hr_theme.dart';
import 'hr_form_kit.dart';

class ChartSlice {
  const ChartSlice({required this.label, required this.value, this.color});

  final String label;
  final num value;
  final Color? color;
}

const List<Color> kChartPalette = [
  Color(0xFF3B6FA8),
  Color(0xFF2DD4BF),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFF22C55E),
  Color(0xFFEC4899),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
];

List<ChartSlice> slicesFromMaps(List<Map<String, dynamic>> rows) {
  return [
    for (var i = 0; i < rows.length; i++)
      ChartSlice(
        label: (rows[i]['name'] ?? rows[i]['label'] ?? '—').toString(),
        value: (rows[i]['count'] as num?) ?? 0,
        color: kChartPalette[i % kChartPalette.length],
      ),
  ];
}

class AnalyticsChartCard extends StatelessWidget {
  const AnalyticsChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 280,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HrUi.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HrUi.label(context),
                    ),
                  ),
                ),
                Icon(Icons.open_in_full, size: 14, color: HrUi.muted(context)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.hole = 0.58,
    this.showLegend = true,
    this.sweep = math.pi * 2,
    this.startAngle = -math.pi / 2,
  });

  final List<ChartSlice> slices;
  final double hole;
  final bool showLegend;
  final double sweep;
  final double startAngle;

  @override
  Widget build(BuildContext context) {
    final data = slices.where((s) => s.value > 0).toList();
    final total = data.fold<num>(0, (a, b) => a + b.value);
    if (data.isEmpty || total <= 0) {
      return Center(
        child: Text('No data', style: TextStyle(color: HrUi.muted(context))),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: sweep < math.pi * 1.6 ? 1.6 : 1,
                child: CustomPaint(
                  painter: _DonutPainter(
                    slices: data,
                    total: total.toDouble(),
                    hole: hole,
                    sweep: sweep,
                    startAngle: startAngle,
                  ),
                ),
              ),
            ),
          ),
          if (showLegend) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final s in data)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color ?? kChartPalette[0],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${s.label} · ${((s.value / total) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 10.5, color: HrUi.muted(context)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class HalfDonutChart extends StatelessWidget {
  const HalfDonutChart({super.key, required this.slices});

  final List<ChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    return DonutChart(
      slices: slices,
      hole: 0.62,
      sweep: math.pi,
      startAngle: math.pi,
    );
  }
}

class ColumnBarChart extends StatelessWidget {
  const ColumnBarChart({super.key, required this.slices});

  final List<ChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    final data = slices.where((s) => s.value > 0).toList();
    if (data.isEmpty) {
      return Center(
        child: Text('No data', style: TextStyle(color: HrUi.muted(context))),
      );
    }
    final maxV = data.fold<num>(0, (a, b) => math.max(a, b.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _YAxis(max: maxV.toDouble()),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final s in data)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${s.value.round()}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: HrUi.muted(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: maxV <= 0 ? 0 : (s.value / maxV).clamp(0.04, 1),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: s.color ?? const Color(0xFF3B6FA8),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9.5, color: HrUi.muted(context)),
                          ),
                        ],
                      ),
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

class _YAxis extends StatelessWidget {
  const _YAxis({required this.max});
  final double max;

  @override
  Widget build(BuildContext context) {
    final top = max <= 0 ? 1 : max.ceilToDouble();
    return SizedBox(
      width: 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${top.round()}', style: TextStyle(fontSize: 9, color: HrUi.muted(context))),
          Text('${(top / 2).round()}', style: TextStyle(fontSize: 9, color: HrUi.muted(context))),
          Text('0', style: TextStyle(fontSize: 9, color: HrUi.muted(context))),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.hole,
    required this.sweep,
    required this.startAngle,
  });

  final List<ChartSlice> slices;
  final double total;
  final double hole;
  final double sweep;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, sweep < math.pi * 1.6 ? size.height * 0.78 : size.height / 2);
    final r = math.min(size.width / 2, size.height / (sweep < math.pi * 1.6 ? 1.15 : 2)) - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * (1 - hole)
      ..strokeCap = StrokeCap.butt;

    var angle = startAngle;
    for (final s in slices) {
      final span = sweep * (s.value / total);
      paint.color = s.color ?? kChartPalette[0];
      canvas.drawArc(rect, angle, span, false, paint);
      angle += span;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.total != total;
}
