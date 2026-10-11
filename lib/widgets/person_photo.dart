import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/network/api_client.dart';

/// Employee photo loaded through the API so the grid shows the saved file.
class PersonPhoto extends StatefulWidget {
  const PersonPhoto({super.key, this.path, this.employeeId, this.size = 64});

  final String? path;
  final int? employeeId;
  final double size;

  @override
  State<PersonPhoto> createState() => _PersonPhotoState();
}

class _PhotoGate {
  static const _max = 4;
  static int _active = 0;
  static final List<void Function()> _waiters = [];

  static Future<void> acquire() {
    if (_active < _max) {
      _active++;
      return Future.value();
    }
    final done = Completer<void>();
    _waiters.add(done.complete);
    return done.future.then((_) {
      _active++;
    });
  }

  static void release() {
    if (_active > 0) _active--;
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0)();
    }
  }
}

class _PersonPhotoState extends State<PersonPhoto> {
  static final Map<String, Uint8List> _cache = {};
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PersonPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.employeeId != widget.employeeId) {
      _load();
    }
  }

  Future<void> _load() async {
    final path = (widget.path ?? '').trim();
    final id = widget.employeeId ?? 0;
    if (path.isEmpty || id < 1) {
      if (mounted) setState(() => _bytes = null);
      return;
    }
    final key = '$id|$path';
    final cached = _cache[key];
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }
    setState(() => _loading = true);
    final token = context.read<AuthState>().session?.token;
    await _PhotoGate.acquire();
    try {
      final api = ApiClient(tokenProvider: () async => token);
      final res = await api.dio.get<List<int>>(
        '/employees/$id/photo',
        options: Options(responseType: ResponseType.bytes),
      );
      final data = res.data;
      if (data != null && data.isNotEmpty) {
        final bytes = Uint8List.fromList(data);
        _cache[key] = bytes;
        if (mounted) setState(() => _bytes = bytes);
      }
    } catch (_) {
      if (mounted) setState(() => _bytes = null);
    } finally {
      _PhotoGate.release();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ClipOval(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: const _DefaultPortraitPainter(),
      ),
    );
    if (_bytes == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _loading
            ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
            : fallback,
      );
    }
    return ClipOval(
      child: Image.memory(
        _bytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
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
