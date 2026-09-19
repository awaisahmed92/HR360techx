import 'package:flutter/foundation.dart';

/// Environment-aware API config for local XAMPP, production web, and mobile.
///
/// Resolution order:
/// 1. `--dart-define=API_BASE_URL=...` (CI / Docker / explicit override)
/// 2. Web: same-origin `/api` (https://hr360techx.com → https://hr360techx.com/api)
///    except Flutter debug on localhost:xxxx → XAMPP path
/// 3. Mobile release → production HTTPS API
/// 4. Mobile debug → Android emulator / iOS simulator local URLs
class AppConfig {
  AppConfig._();

  static const String _defineApi = String.fromEnvironment('API_BASE_URL');
  static const String _defineProdApi = String.fromEnvironment(
    'PROD_API_BASE_URL',
    defaultValue: 'https://hr360techx.com/api',
  );
  static const String _localXamppApi =
      'http://localhost/HR360techx/backend/public/api';

  /// Offline mock login is disabled.
  static const bool allowDemoLogin = bool.fromEnvironment(
    'ALLOW_DEMO_LOGIN',
    defaultValue: false,
  );

  /// Resolved at runtime (not a const) so web uses the current host.
  static String get apiBaseUrl => _normalize(_resolveApiBaseUrl());

  static String _resolveApiBaseUrl() {
    if (_defineApi.trim().isNotEmpty) {
      return _defineApi.trim();
    }

    if (kIsWeb) {
      return _resolveWebApi();
    }

    // Native iOS / Android
    if (kReleaseMode) {
      return _defineProdApi;
    }
    return _resolveMobileDebugApi();
  }

  static String _resolveWebApi() {
    final base = Uri.base;
    final host = base.host.toLowerCase();
    final isLoopback = host == 'localhost' || host == '127.0.0.1';

    // `flutter run -d chrome` → http://localhost:xxxxx — talk to XAMPP
    if (isLoopback && base.port != 80 && base.port != 443) {
      return _localXamppApi;
    }

    // Production or any deployed host (and local Apache on :80)
    // Same-origin /api so one Caddy can serve Flutter + reverse-proxy Laravel.
    final origin = base.origin; // e.g. https://hr360techx.com
    return '$origin/api';
  }

  static String _resolveMobileDebugApi() {
    // Override for a physical device on LAN:
    // --dart-define=API_BASE_URL=http://192.168.x.x/HR360techx/backend/public/api
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator → host machine loopback
        return 'http://10.0.2.2/HR360techx/backend/public/api';
      case TargetPlatform.iOS:
        // iOS simulator can use localhost
        return _localXamppApi;
      default:
        return _localXamppApi;
    }
  }

  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Public asset base (uploads) — strips trailing `/api` from [apiBaseUrl].
  static String get publicBaseUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api')) return base.substring(0, base.length - 4);
    return base;
  }

  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${publicBaseUrl.replaceAll(RegExp(r'/$'), '')}/${path.replaceFirst(RegExp(r'^/'), '')}';
  }

  static const String prefsTokenKey = 'hr360_auth_token';
  static const String prefsSessionKey = 'hr360_session_json';
  static const String prefsUseDemoKey = 'hr360_use_demo';
}
