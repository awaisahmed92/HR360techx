import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> data; // Key: Metric name, Value: 0.0 to 1.0
  final Color polygonColor;
  final bool isDark;

  const RadarChartWidget({
    super.key,
    required this.data,
    this.polygonColor = AppTheme.primary,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _RadarChartPainter(
            data: data,
            polygonColor: polygonColor,
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
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 36;
    final keys = data.keys.toList();
    final count = keys.length;
    final angleStep = (math.pi * 2) / count;

    // Grid web paint
    final webPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric polygons (levels: 0.25, 0.5, 0.75, 1.0)
    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4);
      final path = Path();
      for (int i = 0; i < count; i++) {
        final angle = -math.pi / 2 + (i * angleStep);
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, webPaint);
    }

    // Draw axis lines and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label
      final labelRadius = radius + 22;
      final lx = center.dx + labelRadius * math.cos(angle);
      final ly = center.dy + labelRadius * math.sin(angle);

      final val = ((data[keys[i]] ?? 0) * 100).toInt();
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${keys[i]}\n',
            style: TextStyle(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '$val%',
            style: TextStyle(
              color: polygonColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );

      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(lx - (textPainter.width / 2), ly - (textPainter.height / 2)),
      );
    }

    // Draw Data Polygon Fill & Stroke
    final dataPath = Path();
    final fillPaint = Paint()
      ..color = polygonColor.withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = polygonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = polygonColor
      ..style = PaintingStyle.fill;

    final pointInnerPaint = Paint()
      ..color = isDark ? AppTheme.darkSurface : Colors.white
      ..style = PaintingStyle.fill;

    final points = <Offset>[];

    for (int i = 0; i < count; i++) {
      final value = (data[keys[i]] ?? 0.0).clamp(0.0, 1.0);
      final pointRadius = radius * value;
      final angle = -math.pi / 2 + (i * angleStep);
      final x = center.dx + pointRadius * math.cos(angle);
      final y = center.dy + pointRadius * math.sin(angle);
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw vertex dots
    for (final pt in points) {
      canvas.drawCircle(pt, 5, pointPaint);
      canvas.drawCircle(pt, 2.5, pointInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.polygonColor != polygonColor ||
        oldDelegate.isDark != isDark;
  }
}
