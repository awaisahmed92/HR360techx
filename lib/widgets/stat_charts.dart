import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';

// -------------------------------------------------------------
// 1. Department Distribution Bar Chart
// -------------------------------------------------------------
class DepartmentBarChart extends StatelessWidget {
  final bool isDark;

  const DepartmentBarChart({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final depts = [
      {'name': 'Engineering', 'count': 42, 'color': HrTheme.brand(context)},
      {'name': 'Product', 'count': 18, 'color': AppTheme.accent},
      {'name': 'Design', 'count': 14, 'color': AppTheme.cyan},
      {'name': 'HR & Talent', 'count': 12, 'color': AppTheme.success},
      {'name': 'Marketing', 'count': 16, 'color': AppTheme.warning},
      {'name': 'Operations', 'count': 10, 'color': const Color(0xFFEC4899)},
    ];

    const maxCount = 45;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: depts.map((d) {
            final count = d['count'] as int;
            final color = d['color'] as Color;
            final name = d['name'] as String;
            final percent = count / maxCount;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '$count Members',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.75)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// 2. Attendance Trend Wave Chart
// -------------------------------------------------------------
class AttendanceTrendChart extends StatelessWidget {
  final bool isDark;

  const AttendanceTrendChart({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);
    final brandLight = HrTheme.brandLight(context);
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _TrendChartPainter(
        isDark: isDark,
        brand: brand,
        brandLight: brandLight,
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final bool isDark;
  final Color brand;
  final Color brandLight;

  _TrendChartPainter({
    required this.isDark,
    required this.brand,
    required this.brandLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      0.82, 0.88, 0.94, 0.91, 0.96, 0.98, 0.95, 0.99
    ];
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Today'];

    final widthStep = size.width / (points.length - 1);
    final h = size.height - 24;

    final path = Path();
    final fillPath = Path();

    final List<Offset> offsets = [];

    for (int i = 0; i < points.length; i++) {
      final x = i * widthStep;
      final y = h - (points[i] - 0.7) / 0.3 * (h - 20);
      final pt = Offset(x, y);
      offsets.add(pt);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        final prev = offsets[i - 1];
        final cx1 = prev.dx + (pt.dx - prev.dx) / 2;
        final cy1 = prev.dy;
        final cx2 = prev.dx + (pt.dx - prev.dx) / 2;
        final cy2 = pt.dy;
        path.cubicTo(cx1, cy1, cx2, cy2, pt.dx, pt.dy);
        fillPath.cubicTo(cx1, cy1, cx2, cy2, pt.dx, pt.dy);
      }
    }

    fillPath.lineTo(size.width, h);
    fillPath.close();

    // Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          brand.withOpacity(0.35),
          brand.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = brandLight
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Draw dots and day labels
    final dotPaint = Paint()..color = brand;
    final dotInner = Paint()..color = Colors.white;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < offsets.length; i++) {
      final pt = offsets[i];
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 2, dotInner);

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pt.dx - (textPainter.width / 2), h + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => oldDelegate.isDark != isDark;
}
