import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/hr_theme.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> data; // Key: Metric name, Value: 0.0 to 1.0
  final Color? polygonColor;
  final bool isDark;

  const RadarChartWidget({
    super.key,
    required this.data,
    this.polygonColor,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = polygonColor ?? HrTheme.brand(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _RadarChartPainter(
            data: data,
            polygonColor: color,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color polygonColor;
  final bool isDark;

  _RadarChartPainter({
    required this.data,
    required this.polygonColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.75;
    final keys = data.keys.toList();
    final n = keys.length;
    if (n < 3) return;

    final angleStep = (2 * math.pi) / n;

    // Grid rings
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * angleStep;
        final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angleStep;
      final end = Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // Data polygon
    final poly = Path();
    for (var i = 0; i < n; i++) {
      final value = (data[keys[i]] ?? 0).clamp(0.0, 1.0);
      final a = -math.pi / 2 + i * angleStep;
      final r = radius * value;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
    }
    poly.close();

    canvas.drawPath(
      poly,
      Paint()
        ..color = polygonColor.withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      poly,
      Paint()
        ..color = polygonColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Labels
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * angleStep;
      final labelR = radius * 1.18;
      final p = Offset(
        center.dx + labelR * math.cos(a),
        center.dy + labelR * math.sin(a),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: keys[i],
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.polygonColor != polygonColor ||
      oldDelegate.isDark != isDark;
}
