import 'package:flutter/material.dart';

import '../core/config/app_config.dart';

/// Employee photo. A missing or broken upload shows the same default portrait.
class PersonPhoto extends StatelessWidget {
  const PersonPhoto({super.key, this.path, this.size = 64});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.resolveMediaUrl(path);
    final fallback = ClipOval(
      child: CustomPaint(
        size: Size.square(size),
        painter: const _DefaultPortraitPainter(),
      ),
    );
    if (url.isEmpty) {
      return SizedBox(width: size, height: size, child: fallback);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
      ),
    );
  }
}

class _DefaultPortraitPainter extends CustomPainter {
  const _DefaultPortraitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7EEF5), Color(0xFFD5DEE8)],
        ).createShader(rect),
    );
    final cx = size.width / 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.98),
        width: size.width * 0.92,
        height: size.height * 0.62,
      ),
      Paint()..color = const Color(0xFF8AA0B5),
    );
    canvas.drawCircle(
      Offset(cx, size.height * 0.40),
      size.width * 0.22,
      Paint()..color = const Color(0xFFF4F7FB),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
