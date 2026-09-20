/// Country catalog for Clock Country (flag + local time).
class CountryOption {
  const CountryOption({
    required this.code,
    required this.name,
    required this.utcOffsetMinutes,
    required this.timeZoneLabel,
  });

  final String code;
  final String name;
  final int utcOffsetMinutes;
  final String timeZoneLabel;

  String get flag {
    if (code.length != 2) return '🌐';
    final upper = code.toUpperCase();
    return String.fromCharCodes(
      upper.codeUnits.map((c) => 0x1F1E6 + (c - 0x41)),
    );
  }

  String get gmtLabel {
    final sign = utcOffsetMinutes >= 0 ? '+' : '-';
    final abs = utcOffsetMinutes.abs();
    final h = (abs ~/ 60).toString().padLeft(2, '0');
    final m = (abs % 60).toString().padLeft(2, '0');
    return 'GMT$sign$h:$m';
  }

  DateTime nowLocal() => DateTime.now().toUtc().add(
        Duration(minutes: utcOffsetMinutes),
      );
}

class Countries {
  static const defaultCode = 'PK';

  static CountryOption byCode(String? code) {
    final key = (code ?? '').trim().toUpperCase();
    for (final c in all) {
      if (c.code == key) return c;
    }
    return byName(code);
  }

  static CountryOption byName(String? name) {
    final n = (name ?? '').trim().toLowerCase();
    if (n.isEmpty) return pakistan;
    for (final c in all) {
      if (c.name.toLowerCase() == n || c.code.toLowerCase() == n) return c;
    }
    return pakistan;
  }

  static const pakistan = CountryOption(
    code: 'PK',
    name: 'Pakistan',
    utcOffsetMinutes: 300,
    timeZoneLabel: '(GMT+05:00) Pakistan Standard Time',
  );

  static const all = <CountryOption>[
    CountryOption(code: 'AE', name: 'United Arab Emirates', utcOffsetMinutes: 240, timeZoneLabel: '(GMT+04:00) Gulf Standard Time'),
    CountryOption(code: 'AF', name: 'Afghanistan', utcOffsetMinutes: 270, timeZoneLabel: '(GMT+04:30) Afghanistan Time'),
    CountryOption(code: 'AR', name: 'Argentina', utcOffsetMinutes: -180, timeZoneLabel: '(GMT-03:00) Argentina Time'),
    CountryOption(code: 'AT', name: 'Austria', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'AU', name: 'Australia', utcOffsetMinutes: 600, timeZoneLabel: '(GMT+10:00) Australian Eastern Time'),
    CountryOption(code: 'BD', name: 'Bangladesh', utcOffsetMinutes: 360, timeZoneLabel: '(GMT+06:00) Bangladesh Standard Time'),
    CountryOption(code: 'BE', name: 'Belgium', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'BH', name: 'Bahrain', utcOffsetMinutes: 180, timeZoneLabel: '(GMT+03:00) Arabia Standard Time'),
    CountryOption(code: 'BR', name: 'Brazil', utcOffsetMinutes: -180, timeZoneLabel: '(GMT-03:00) Brasilia Time'),
    CountryOption(code: 'CA', name: 'Canada', utcOffsetMinutes: -300, timeZoneLabel: '(GMT-05:00) Eastern Standard Time'),
    CountryOption(code: 'CH', name: 'Switzerland', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'CN', name: 'China', utcOffsetMinutes: 480, timeZoneLabel: '(GMT+08:00) China Standard Time'),
    CountryOption(code: 'DE', name: 'Germany', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'DK', name: 'Denmark', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'EG', name: 'Egypt', utcOffsetMinutes: 120, timeZoneLabel: '(GMT+02:00) Eastern European Time'),
    CountryOption(code: 'ES', name: 'Spain', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'FR', name: 'France', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'GB', name: 'United Kingdom', utcOffsetMinutes: 0, timeZoneLabel: '(GMT+00:00) Greenwich Mean Time'),
    CountryOption(code: 'GR', name: 'Greece', utcOffsetMinutes: 120, timeZoneLabel: '(GMT+02:00) Eastern European Time'),
    CountryOption(code: 'HK', name: 'Hong Kong', utcOffsetMinutes: 480, timeZoneLabel: '(GMT+08:00) Hong Kong Time'),
    CountryOption(code: 'ID', name: 'Indonesia', utcOffsetMinutes: 420, timeZoneLabel: '(GMT+07:00) Western Indonesia Time'),
    CountryOption(code: 'IE', name: 'Ireland', utcOffsetMinutes: 0, timeZoneLabel: '(GMT+00:00) Greenwich Mean Time'),
    CountryOption(code: 'IN', name: 'India', utcOffsetMinutes: 330, timeZoneLabel: '(GMT+05:30) India Standard Time'),
    CountryOption(code: 'IT', name: 'Italy', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'JP', name: 'Japan', utcOffsetMinutes: 540, timeZoneLabel: '(GMT+09:00) Japan Standard Time'),
    CountryOption(code: 'KE', name: 'Kenya', utcOffsetMinutes: 180, timeZoneLabel: '(GMT+03:00) East Africa Time'),
    CountryOption(code: 'KR', name: 'South Korea', utcOffsetMinutes: 540, timeZoneLabel: '(GMT+09:00) Korea Standard Time'),
    CountryOption(code: 'KW', name: 'Kuwait', utcOffsetMinutes: 180, timeZoneLabel: '(GMT+03:00) Arabia Standard Time'),
    CountryOption(code: 'LK', name: 'Sri Lanka', utcOffsetMinutes: 330, timeZoneLabel: '(GMT+05:30) Sri Lanka Time'),
    CountryOption(code: 'MY', name: 'Malaysia', utcOffsetMinutes: 480, timeZoneLabel: '(GMT+08:00) Malaysia Time'),
    CountryOption(code: 'MX', name: 'Mexico', utcOffsetMinutes: -360, timeZoneLabel: '(GMT-06:00) Central Standard Time'),
    CountryOption(code: 'NG', name: 'Nigeria', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) West Africa Time'),
    CountryOption(code: 'NL', name: 'Netherlands', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'NO', name: 'Norway', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'NP', name: 'Nepal', utcOffsetMinutes: 345, timeZoneLabel: '(GMT+05:45) Nepal Time'),
    CountryOption(code: 'NZ', name: 'New Zealand', utcOffsetMinutes: 720, timeZoneLabel: '(GMT+12:00) New Zealand Standard Time'),
    CountryOption(code: 'OM', name: 'Oman', utcOffsetMinutes: 240, timeZoneLabel: '(GMT+04:00) Gulf Standard Time'),
    CountryOption(code: 'PH', name: 'Philippines', utcOffsetMinutes: 480, timeZoneLabel: '(GMT+08:00) Philippine Time'),
    pakistan,
    CountryOption(code: 'PL', name: 'Poland', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'QA', name: 'Qatar', utcOffsetMinutes: 180, timeZoneLabel: '(GMT+03:00) Arabia Standard Time'),
    CountryOption(code: 'SA', name: 'Saudi Arabia', utcOffsetMinutes: 180, timeZoneLabel: '(GMT+03:00) Arabia Standard Time'),
    CountryOption(code: 'SE', name: 'Sweden', utcOffsetMinutes: 60, timeZoneLabel: '(GMT+01:00) Central European Time'),
    CountryOption(code: 'SG', name: 'Singapore', utcOffsetMinutes: 480, timeZoneLabel: '(GMT+08:00) Singapore Time'),
    CountryOption(code: 'TH', name: 'Thailand', utcOffsetMinutes: 420, timeZoneLabel: '(GMT+07:00) Indochina Time'),
    CountryOption(code: 'TR', name: 'Turkey', utcOffsetMinutes: 180, timeZoneLabel: '(GMT+03:00) Turkey Time'),
    CountryOption(code: 'US', name: 'United States', utcOffsetMinutes: -300, timeZoneLabel: '(GMT-05:00) Eastern Standard Time'),
    CountryOption(code: 'ZA', name: 'South Africa', utcOffsetMinutes: 120, timeZoneLabel: '(GMT+02:00) South Africa Standard Time'),
  ];
}
