// Conditional import — only compiled for web.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import '../config/app_config.dart';
import 'session_vault_web.dart';

/// SharedPreferences on web JSON-encodes values under `flutter.<key>`.
String? peekStoredSessionJson() {
  try {
    final vault = readSessionVault();
    if (vault != null && vault.isNotEmpty) return vault;

    final ls = html.window.localStorage;
    return ls['flutter.${AppConfig.prefsSessionKey}'] ??
        ls[AppConfig.prefsSessionKey];
  } catch (_) {
    return null;
  }
}
