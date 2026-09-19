/// Runtime config for HR360 Flutter client.
///
/// Point [apiBaseUrl] at your XAMPP CI4 public folder.
/// Example (Windows XAMPP): http://localhost/hr/public
class AppConfig {
  AppConfig._();

  /// Base URL of the PHP API (no trailing slash).
  /// Override via `--dart-define=API_BASE_URL=https://scfnew.example.com`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost/HR360techx/backend/public/api',
  );

  /// Offline mock login is disabled. Always authenticate against tenant DB via API.
  static const bool allowDemoLogin = bool.fromEnvironment(
    'ALLOW_DEMO_LOGIN',
    defaultValue: false,
  );

  /// Public asset base (uploads) — strips trailing `/api` from [apiBaseUrl].
  static String get publicBaseUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api')) return base.substring(0, base.length - 4);
    if (base.endsWith('/api/')) return base.substring(0, base.length - 5);
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
