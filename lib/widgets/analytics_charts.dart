import 'dart:math' as math;

import 'package:flutter/material.dart';

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

enum AnalyticsChartType { donut, pie, column, bar }

class AnalyticsChartCard extends StatefulWidget {
  const AnalyticsChartCard({
    super.key,
    required this.title,
    this.child,
    this.slices,
    this.initialType = AnalyticsChartType.donut,
    this.height = 300,
  }) : assert(child != null || slices != null);

  final String title;
  final Widget? child;
  final List<ChartSlice>? slices;
  final AnalyticsChartType initialType;
  final double height;

  @override
  State<AnalyticsChartCard> createState() => _AnalyticsChartCardState();
}

class _AnalyticsChartCardState extends State<AnalyticsChartCard> {
  late AnalyticsChartType _type = widget.initialType;

  static const _labels = {
    AnalyticsChartType.donut: 'Donut',
    AnalyticsChartType.pie: 'Pie',
    AnalyticsChartType.column: 'Column',
    AnalyticsChartType.bar: 'Bar',
  };

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    final body = slices == null
        ? widget.child!
        : switch (_type) {
            AnalyticsChartType.donut => DonutChart(slices: slices),
            AnalyticsChartType.pie => DonutChart(slices: slices, hole: 0),
            AnalyticsChartType.column => ColumnBarChart(slices: slices),
            AnalyticsChartType.bar => HorizontalBarChart(slices: slices),
          };

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HrUi.label(context),
                    ),
                  ),
                ),
                if (slices != null)
                  PopupMenuButton<AnalyticsChartType>(
                    tooltip: 'Chart type',
                    initialValue: _type,
                    onSelected: (value) => setState(() => _type = value),
                    itemBuilder: (_) => [
                      for (final type in AnalyticsChartType.values)
                        PopupMenuItem(
                          value: type,
                          child: Text(_labels[type]!),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_chart_outlined, size: 16, color: HrUi.muted(context)),
                          const SizedBox(width: 4),
                          Text(
                            _labels[_type]!,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HrUi.muted(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
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
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: CustomPaint(
                    size: Size(side, side),
                    painter: _DonutPainter(
                      slices: data,
                      total: total.toDouble(),
                      hole: hole,
                      sweep: sweep,
                      startAngle: startAngle,
                    ),
                  ),
                );
              },
            ),
          ),
          if (showLegend)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 10,
                runSpacing: 4,
                alignment: WrapAlignment.center,
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
            ),
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
    final maxV = data.fold<num>(0, (a, b) => math.max(a, b.value)).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const labelH = 32.0;
          const valueH = 16.0;
          final plotH = math.max(12.0, constraints.maxHeight - labelH - valueH - 8);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _YAxis(max: maxV, plotHeight: plotH),
              const SizedBox(width: 6),
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
                              SizedBox(
                                height: valueH,
                                child: Text(
                                  '${s.value.round()}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: HrUi.muted(context),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: plotH,
                                width: double.infinity,
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: math.max(4, plotH * (maxV <= 0 ? 0 : (s.value / maxV).clamp(0.06, 1))),
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: s.color ?? const Color(0xFF3B6FA8),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: labelH,
                                child: Text(
                                  s.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9.5, color: HrUi.muted(context)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HorizontalBarChart extends StatelessWidget {
  const HorizontalBarChart({super.key, required this.slices});

  final List<ChartSlice> slices;

  @override
  Widget build(BuildContext context) {
    final data = slices.where((s) => s.value > 0).toList();
    if (data.isEmpty) {
      return Center(child: Text('No data', style: TextStyle(color: HrUi.muted(context))));
    }
    final maxV = data.fold<num>(0, (a, b) => math.max(a, b.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      children: [
        for (final s in data)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: HrUi.label(context)),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: maxV <= 0 ? 0 : (s.value / maxV).clamp(0.0, 1.0).toDouble(),
                      minHeight: 12,
                      backgroundColor: (s.color ?? const Color(0xFF3B6FA8)).withValues(alpha: 0.12),
                      color: s.color ?? const Color(0xFF3B6FA8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${s.value.round()}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HrUi.muted(context)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _YAxis extends StatelessWidget {
  const _YAxis({required this.max, required this.plotHeight});
  final double max;
  final double plotHeight;

  @override
  Widget build(BuildContext context) {
    final top = max <= 0 ? 1.0 : max.ceilToDouble();
    final style = TextStyle(fontSize: 9, color: HrUi.muted(context));
    return SizedBox(
      width: 26,
      height: plotHeight + 16,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${top.round()}', style: style),
            Text('${(top / 2).round()}', style: style),
            Text('0', style: style),
          ],
        ),
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
    final filled = hole <= 0;
    final paint = Paint()
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = filled ? 0 : r * (1 - hole)
      ..strokeCap = StrokeCap.butt;

    var angle = startAngle;
    for (final s in slices) {
      final span = sweep * (s.value / total);
      paint.color = s.color ?? kChartPalette[0];
      canvas.drawArc(rect, angle, math.max(span - (filled ? 0.012 : 0), 0.001), filled, paint);
      angle += span;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.total != total;
}
