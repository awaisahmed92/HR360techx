// Web-only file, selected by a conditional import. Mobile never compiles this.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Keeps the address bar on /sign-up or / so a refresh opens the same screen.
void setBrowserPath(String path) {
  final current = html.window.location.pathname ?? '/';
  if (current == path) return;
  html.window.history.pushState(null, '', path);
}

void listenBrowserPath(void Function(bool signUp) onChange) {
  html.window.onPopState.listen((_) {
    final path = (html.window.location.pathname ?? '').toLowerCase();
    onChange(path.contains('sign-up') || path.contains('signup'));
  });
}
