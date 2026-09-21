import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import 'auth_models.dart';
import 'session_vault.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  AuthSession? _session;

  AuthSession? get session => _session;
  String? get token => _session?.token;

  void hydrateFromRaw(String? raw) {
    final map = _decodeSessionMap(raw);
    if (map == null) return;
    try {
      final session = AuthSession.fromJson(map);
      if (session.token.isEmpty && !session.isDemo) return;
      _session = session;
    } catch (_) {}
  }

  Map<String, dynamic>? _decodeSessionMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      dynamic decoded = jsonDecode(raw);
      // SharedPreferences web stores strings as JSON, so one extra unwrap.
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> restoreSession() async {
    hydrateFromRaw(readSessionVault());
    if (_session != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      hydrateFromRaw(prefs.getString(AppConfig.prefsSessionKey));
      final token = prefs.getString(AppConfig.prefsTokenKey);
      if (_session == null && token != null && token.isNotEmpty) {
        hydrateFromRaw(jsonEncode({
          'token': token,
          'user': <String, dynamic>{},
          'company': <String, dynamic>{},
          'permissions': {'all': true},
          'is_demo': prefs.getBool(AppConfig.prefsUseDemoKey) == true,
        }));
      }
    } catch (_) {}
  }

  Future<AuthSession> login({
    required String subdomain,
    required String username,
    required String password,
    bool preferDemo = false,
  }) async {
    final cleanedSub = subdomain.trim().toLowerCase();
    final cleanedUser = username.trim();

    if (cleanedSub.isEmpty || cleanedUser.isEmpty || password.isEmpty) {
      throw AuthException('Company name, username and password are required.');
    }

    // Demo path — no backend required
    if (AppConfig.allowDemoLogin &&
        (preferDemo ||
            (cleanedSub == 'demo' &&
                cleanedUser.toLowerCase() == 'admin' &&
                password == 'admin123'))) {
      final session = _demoSession(cleanedSub == 'demo' ? 'demo' : cleanedSub);
      await _persist(session);
      return session;
    }

    try {
      final response = await _api.dio.post(
        '/auth/login',
        data: {
          'subdomain': cleanedSub,
          'username': cleanedUser,
          'password': password,
        },
      );

      final data = response.data;
      if (data is! Map || data['success'] != true) {
        final msg = (data is Map ? data['message'] : null)?.toString() ??
            'Login failed.';
        throw AuthException(msg);
      }

      final session = AuthSession.fromJson({
        'token': data['token'],
        'user': data['user'],
        'company': data['company'],
        'permissions': data['permissions'],
        'is_demo': false,
        'ui_prefs': data['ui_prefs'],
      });
      await _persist(session);
      return session;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw AuthException(body['message'].toString());
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw AuthException(
          'Cannot reach API at ${AppConfig.apiBaseUrl}. '
          'On local: start Apache + MySQL in XAMPP. '
          'On production: ensure Laravel is deployed and Caddy proxies /api.',
        );
      }
      throw AuthException('Network error: ${e.message}');
    }
  }

  Future<void> logout() async {
    _session = null;
    clearSessionVault();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConfig.prefsTokenKey);
      await prefs.remove(AppConfig.prefsSessionKey);
      await prefs.remove(AppConfig.prefsUseDemoKey);
    } catch (_) {}
  }

  Future<AuthSession?> refreshMe() async {
    if (_session == null || _session!.isDemo) return _session;
    try {
      final client = ApiClient(tokenProvider: () async => _session?.token);
      final response = await client.dio.get('/auth/me');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        final updated = AuthSession.fromJson({
          'token': _session!.token,
          'user': data['user'],
          'company': data['company'],
          'permissions': data['permissions'],
          'is_demo': false,
          'ui_prefs': data['ui_prefs'],
        });
        await _persist(updated);
        return updated;
      }
    } catch (_) {
      // Keep cached session on soft failure
    }
    return _session;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_session == null || _session!.isDemo) {
      throw AuthException('Password change is not available in demo mode.');
    }
    try {
      final client = ApiClient(tokenProvider: () async => _session?.token);
      final response = await client.dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw AuthException(
          (data is Map ? data['message'] : null)?.toString() ??
              'Could not change password.',
        );
      }
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw AuthException(body['message'].toString());
      }
      throw AuthException('Network error: ${e.message}');
    }
  }

  Future<void> _persist(AuthSession session) async {
    _session = session;
    final compact = jsonEncode({
      'token': session.token,
      'user': session.user.toJson(),
      'company': session.company.toJson(),
      'permissions': session.permissions.toJson(),
      'is_demo': session.isDemo,
    });
    writeSessionVault(compact);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.prefsTokenKey, session.token);
      await prefs.setString(AppConfig.prefsSessionKey, compact);
      await prefs.setBool(AppConfig.prefsUseDemoKey, session.isDemo);
    } catch (_) {
      // Vault already saved — quota / plugin failure must not drop the session.
    }
  }

  AuthSession _demoSession(String subdomain) {
    return AuthSession(
      token: 'demo-token',
      isDemo: true,
      user: const AuthUser(
        employeeId: 1,
        name: 'Demo Admin',
        userName: 'admin',
        email: 'admin@demo.local',
        designationId: 1,
        designationName: 'HR Manager',
        userStatus: 2,
        isFirstLogin: false,
        isSuperuser: false,
      ),
      company: AuthCompany(
        name: 'HR360 Demo Org',
        code: 'DEMO',
        currency: 'PKR',
        dateFormat: 'd-m-Y',
        subdomain: subdomain,
      ),
      permissions: const AuthPermissions(all: true),
    );
  }
}
