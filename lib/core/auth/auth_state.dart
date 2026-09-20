import 'package:flutter/foundation.dart';

import 'auth_models.dart';
import 'auth_service.dart';
import 'session_peek.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService() {
    _hydrateSync();
  }

  final AuthService _service;
  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  String? _error;
  bool _busy = false;

  void _hydrateSync() {
    _service.hydrateFromRaw(peekStoredSessionJson());
    _session = _service.session;
    if (_session != null) {
      _status = AuthStatus.authenticated;
    }
  }

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  AuthUser? get user => _session?.user;
  AuthCompany? get company => _session?.company;
  AuthPermissions get permissions =>
      _session?.permissions ?? const AuthPermissions();
  String? get error => _error;
  bool get busy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isDemo => _session?.isDemo == true;

  Future<void> bootstrap() async {
    await _service.restoreSession();
    _session = _service.session;
    _status = _session != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
    if (_session != null && _session!.isDemo == false) {
      final refreshed = await _service.refreshMe();
      if (refreshed != null) {
        _session = refreshed;
        notifyListeners();
      }
    }
  }

  Future<bool> login({
    required String subdomain,
    required String username,
    required String password,
    bool preferDemo = false,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _session = await _service.login(
        subdomain: subdomain,
        username: username,
        password: password,
        preferDemo: preferDemo,
      );
      _status = AuthStatus.authenticated;
      _busy = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _status = AuthStatus.unauthenticated;
      _busy = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _session = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  bool canViewModule(String module) => permissions.canViewModule(module);

  bool canView(String module, String screen) =>
      permissions.canView(module, screen);
}
