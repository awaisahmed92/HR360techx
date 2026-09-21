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
    onChange(browserWantsSignUp());
  });
}

/// True when the real browser address is the public sign-up page.
/// Prefer this over Uri.base — path URL strategy can report `/` there.
bool browserWantsSignUp() {
  final loc = html.window.location;
  final path = (loc.pathname ?? '').toLowerCase();
  final hash = loc.hash.toLowerCase();
  final search = (loc.search ?? '').toLowerCase();
  return path.contains('sign-up') ||
      path.contains('signup') ||
      hash.contains('sign-up') ||
      hash.contains('signup') ||
      search.contains('signup=1') ||
      search.contains('sign-up');
}
