import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../network/api_client.dart';

class StatusFeedSnapshot {
  const StatusFeedSnapshot({
    required this.posts,
    this.birthdays = const [],
    this.anniversaries = const [],
    this.upcomingBirthdays = const [],
    this.upcomingAnniversaries = const [],
  });

  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> birthdays;
  final List<Map<String, dynamic>> anniversaries;
  final List<Map<String, dynamic>> upcomingBirthdays;
  final List<Map<String, dynamic>> upcomingAnniversaries;
}

class StatusFeedRepository {
  StatusFeedRepository({required this.getSession});
  final AuthSession? Function() getSession;

  ApiClient _c() => ApiClient(tokenProvider: () async => getSession()?.token);

  bool get isLive {
    final s = getSession();
    return s != null && !s.isDemo && s.token.isNotEmpty;
  }

  bool get _live => isLive;

  static List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> load() async {
    final snap = await loadSnapshot();
    return snap?.posts ?? const [];
  }

  Future<StatusFeedSnapshot?> loadSnapshot() async {
    if (!_live) return null;
    try {
      final res = await _c().dio.get('/feed');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        final celeb = data['celebrations'] is Map
            ? Map<String, dynamic>.from(data['celebrations'] as Map)
            : const <String, dynamic>{};
        return StatusFeedSnapshot(
          posts: _maps(data['posts']),
          birthdays: _maps(celeb['birthdays']),
          anniversaries: _maps(celeb['anniversaries']),
          upcomingBirthdays: _maps(celeb['upcoming_birthdays']),
          upcomingAnniversaries: _maps(celeb['upcoming_anniversaries']),
        );
      }
    } on DioException {
      // keep local cache
    }
    return null;
  }

  Future<Map<String, dynamic>?> post({
    required String text,
    required String type,
  }) async {
    if (!_live) return null;
    try {
      final res = await _c().dio.post('/feed', data: {
        'text': text,
        'type': type,
      });
      final data = res.data;
      if (data is Map && data['success'] == true && data['post'] is Map) {
        return Map<String, dynamic>.from(data['post'] as Map);
      }
    } on DioException {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> like(String postId) async {
    if (!_live) return null;
    try {
      final res = await _c().dio.post('/feed/$postId/like');
      final data = res.data;
      if (data is Map && data['success'] == true && data['post'] is Map) {
        return Map<String, dynamic>.from(data['post'] as Map);
      }
    } on DioException {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> comment({
    required String postId,
    required String text,
  }) async {
    if (!_live) return null;
    try {
      final res = await _c().dio.post('/feed/$postId/comment', data: {
        'text': text,
      });
      final data = res.data;
      if (data is Map && data['success'] == true && data['post'] is Map) {
        return Map<String, dynamic>.from(data['post'] as Map);
      }
    } on DioException {
      return null;
    }
    return null;
  }
}
