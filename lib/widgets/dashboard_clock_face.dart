import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/config/clock_faces.dart';
import '../core/config/countries.dart';

/// Circular clock face used on My Dashboard (reflects System Settings → Clock Faces).
class DashboardClockFace extends StatefulWidget {
  const DashboardClockFace({
    super.key,
    required this.face,
    required this.clockType,
    required this.country,
    required this.timeFormat,
    required this.isClockedIn,
    required this.onTap,
  });

  final ClockFaceOption face;
  final String clockType;
  final CountryOption country;
  final String timeFormat;
  final bool isClockedIn;
  final VoidCallback onTap;

  @override
  State<DashboardClockFace> createState() => _DashboardClockFaceState();
}

class _DashboardClockFaceState extends State<DashboardClockFace> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.country.nowLocal();
    final digital = widget.clockType.toLowerCase().contains('digital');
    final twelve = widget.timeFormat.contains('12');
    final time = DateFormat(digital
            ? (twelve ? 'h:mm a' : 'HH:mm')
            : (twelve ? 'h:mm' : 'HH:mm'))
        .format(now);
    final date = DateFormat('EEE, MMM d').format(now);

    return Tooltip(
      message: '${widget.country.flag} ${widget.country.name} · ${widget.country.gmtLabel}',
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.face.colors.length >= 2
                        ? widget.face.colors
                        : [
                            widget.face.colors.isNotEmpty
                                ? widget.face.colors.first
                                : const Color(0xFF0A1628),
                            widget.face.colors.isNotEmpty
                                ? widget.face.colors.first
                                : const Color(0xFF00D4FF),
                          ],
                  ),
                  border: Border.all(color: Colors.white24, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.face.colors.isNotEmpty
                              ? widget.face.colors.last
                              : const Color(0xFF00D4FF))
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(widget.face.icon,
                        size: 64, color: Colors.white.withValues(alpha: 0.12)),
                    if (!digital)
                      CustomPaint(
                        size: const Size(102, 102),
                        painter: _AnalogHandsPainter(now),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (digital)
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: twelve ? 18 : 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          )
                        else
                          const SizedBox(height: 32),
                        Text(
                          date,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            widget.isClockedIn
                                ? 'Clocked in'
                                : 'You have not clocked in today!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.isClockedIn
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFCA5A5),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.country.flag,
                    style: const TextStyle(fontSize: 15, height: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalogHandsPainter extends CustomPainter {
  _AnalogHandsPainter(this.now);
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paintH = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final paintM = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final hour = (now.hour % 12) + now.minute / 60.0;
    final minute = now.minute + now.second / 60.0;
    final hourAngle = (hour / 12) * 2 * math.pi - math.pi / 2;
    final minuteAngle = (minute / 60) * 2 * math.pi - math.pi / 2;
    canvas.drawLine(
      c,
      Offset(c.dx + 28 * math.cos(hourAngle), c.dy + 28 * math.sin(hourAngle)),
      paintH,
    );
    canvas.drawLine(
      c,
      Offset(c.dx + 40 * math.cos(minuteAngle), c.dy + 40 * math.sin(minuteAngle)),
      paintM,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalogHandsPainter oldDelegate) =>
      oldDelegate.now.minute != now.minute || oldDelegate.now.hour != now.hour;
}
