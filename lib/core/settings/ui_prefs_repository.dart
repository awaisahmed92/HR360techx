import 'package:dio/dio.dart';

import '../auth/auth_models.dart';
import '../network/api_client.dart';

class UiPrefsRepository {
  UiPrefsRepository({required this.getSession});
  final AuthSession? Function() getSession;

  ApiClient _c() => ApiClient(tokenProvider: () async => getSession()?.token);

  Future<Map<String, dynamic>?> fetch() async {
    final session = getSession();
    if (session == null || session.isDemo) return session?.uiPrefs;
    try {
      final res = await _c().dio.get('/settings/ui-prefs');
      final data = res.data;
      if (data is Map && data['success'] == true && data['prefs'] is Map) {
        return Map<String, dynamic>.from(data['prefs'] as Map);
      }
    } on DioException {
      // fall through — keep local prefs
    }
    return session.uiPrefs;
  }

  Future<void> save(Map<String, dynamic> prefs) async {
    final session = getSession();
    if (session == null || session.isDemo) return;
    try {
      await _c().dio.post('/settings/ui-prefs', data: prefs);
    } on DioException {
      // local SharedPreferences still holds the choice
    }
  }
}
