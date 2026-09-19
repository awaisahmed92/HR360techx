/// Safe JSON coercions for PHP quirks (empty assoc array → `[]`).
Map<String, dynamic> asStringKeyedMap(dynamic raw) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
  if (raw is List) {
    final out = <String, dynamic>{};
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is Map) {
        final level = item['level'] ?? (i + 1);
        out['$level'] = Map<String, dynamic>.from(item);
      }
    }
    return out;
  }
  return {};
}
