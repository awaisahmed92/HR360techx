/// Formats person names without leading commas when surname is empty.
String formatPersonName({String? first, String? surname, String? combined}) {
  var f = (first ?? '').trim();
  var s = (surname ?? '').trim();
  f = f.replaceFirst(RegExp(r'^,+\s*'), '');
  s = s.replaceFirst(RegExp(r'^,+\s*'), '');

  if (f.isEmpty && s.isEmpty) {
    final c = (combined ?? '').trim().replaceFirst(RegExp(r'^,+\s*'), '');
    return c;
  }
  if (s.isNotEmpty && f.isNotEmpty) return '$s, $f';
  return f.isNotEmpty ? f : s;
}

String cleanDisplayName(String? raw) {
  if (raw == null) return '';
  return raw.trim().replaceFirst(RegExp(r'^,+\s*'), '');
}
