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
    defaultValue: 'http://localhost/HR360techx/api',
  );

  /// When true, login accepts demo credentials without calling the API.
  /// Demo: subdomain `demo`, user `admin` / `admin123`
  static const bool allowDemoLogin = bool.fromEnvironment(
    'ALLOW_DEMO_LOGIN',
    defaultValue: true,
  );

  static const String prefsTokenKey = 'hr360_auth_token';
  static const String prefsSessionKey = 'hr360_session_json';
  static const String prefsUseDemoKey = 'hr360_use_demo';
}
