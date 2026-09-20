import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_models.dart';
import '../network/api_client.dart';
import '../config/clock_faces.dart';

/// Organization + general + clock settings (company-scoped).
class OrgSettingsState {
  OrgSettingsState({
    this.orgCode = 'demo',
    this.orgUrl = 'https://hr360techx.com',
    this.orgName = 'HR360 Demo Org',
    this.industry = 'Technology',
    this.startingYear = '2020',
    this.contactPreferred = '',
    this.contactLast = '',
    this.contactEmail = '',
    this.contactCountry = 'United States',
    this.contactProvince = '',
    this.contactPhone = '',
    this.logoUrl,
    this.timeZone = '(GMT+05:00) Pakistan Standard Time',
    this.dateFormat = 'YYYY-MM-DD',
    this.timeFormat = '12 Hour Format',
    this.phoneFormat = '(Country Code) 999-999999',
    this.ssnFormat = '99999-9999999-9',
    this.showTimeDecimals = false,
    this.timeFieldFormat = '5',
    this.calendarStartDay = 'Monday',
    this.defaultTheme = '',
    this.employeeNameDisplay = '{Last Name}, {Preferred Name}',
    this.baseCurrency = 'PKR',
    this.currencySign = 'Rs',
    this.decimalPlaces = '2',
    this.temperatureFormat = 'Celsius (C)',
    this.noBirthdayNotifications = false,
    this.hideEmailApprovalActions = false,
    this.bypassOwnApprovals = false,
    this.clockType = 'Digital Clock',
    this.clockFaceId = ClockFaces.defaultId,
    this.clockCountry = 'PK',
  });

  String orgCode;
  String orgUrl;
  String orgName;
  String industry;
  String startingYear;
  String contactPreferred;
  String contactLast;
  String contactEmail;
  String contactCountry;
  String contactProvince;
  String contactPhone;
  String? logoUrl;

  String timeZone;
  String dateFormat;
  String timeFormat;
  String phoneFormat;
  String ssnFormat;
  bool showTimeDecimals;
  String timeFieldFormat;
  String calendarStartDay;
  String defaultTheme;
  String employeeNameDisplay;
  String baseCurrency;
  String currencySign;
  String decimalPlaces;
  String temperatureFormat;
  bool noBirthdayNotifications;
  bool hideEmailApprovalActions;
  bool bypassOwnApprovals;

  String clockType;
  String clockFaceId;
  String clockCountry;

  Map<String, dynamic> toJson() => {
        'org_code': orgCode,
        'org_url': orgUrl,
        'org_name': orgName,
        'industry': industry,
        'starting_year': startingYear,
        'contact_preferred': contactPreferred,
        'contact_last': contactLast,
        'contact_email': contactEmail,
        'contact_country': contactCountry,
        'contact_province': contactProvince,
        'contact_phone': contactPhone,
        'logo_url': logoUrl,
        'time_zone': timeZone,
        'date_format': dateFormat,
        'time_format': timeFormat,
        'phone_format': phoneFormat,
        'ssn_format': ssnFormat,
        'show_time_decimals': showTimeDecimals,
        'time_field_format': timeFieldFormat,
        'calendar_start_day': calendarStartDay,
        'default_theme': defaultTheme,
        'employee_name_display': employeeNameDisplay,
        'base_currency': baseCurrency,
        'currency_sign': currencySign,
        'decimal_places': decimalPlaces,
        'temperature_format': temperatureFormat,
        'no_birthday_notifications': noBirthdayNotifications,
        'hide_email_approval_actions': hideEmailApprovalActions,
        'bypass_own_approvals': bypassOwnApprovals,
        'clock_type': clockType,
        'clock_face_id': clockFaceId,
        'clock_country': clockCountry,
      };

  factory OrgSettingsState.fromJson(Map<String, dynamic> j) {
    final s = OrgSettingsState();
    s.orgCode = '${j['org_code'] ?? s.orgCode}';
    s.orgUrl = '${j['org_url'] ?? s.orgUrl}';
    s.orgName = '${j['org_name'] ?? s.orgName}';
    s.industry = '${j['industry'] ?? s.industry}';
    s.startingYear = '${j['starting_year'] ?? s.startingYear}';
    s.contactPreferred = '${j['contact_preferred'] ?? ''}';
    s.contactLast = '${j['contact_last'] ?? ''}';
    s.contactEmail = '${j['contact_email'] ?? ''}';
    s.contactCountry = '${j['contact_country'] ?? s.contactCountry}';
    s.contactProvince = '${j['contact_province'] ?? ''}';
    s.contactPhone = '${j['contact_phone'] ?? ''}';
    s.logoUrl = j['logo_url']?.toString();
    s.timeZone = '${j['time_zone'] ?? s.timeZone}';
    s.dateFormat = '${j['date_format'] ?? s.dateFormat}';
    s.timeFormat = '${j['time_format'] ?? s.timeFormat}';
    s.phoneFormat = '${j['phone_format'] ?? s.phoneFormat}';
    s.ssnFormat = '${j['ssn_format'] ?? s.ssnFormat}';
    s.showTimeDecimals = j['show_time_decimals'] == true;
    s.timeFieldFormat = '${j['time_field_format'] ?? s.timeFieldFormat}';
    s.calendarStartDay = '${j['calendar_start_day'] ?? s.calendarStartDay}';
    s.defaultTheme = '${j['default_theme'] ?? ''}';
    s.employeeNameDisplay = '${j['employee_name_display'] ?? s.employeeNameDisplay}';
    s.baseCurrency = '${j['base_currency'] ?? s.baseCurrency}';
    s.currencySign = '${j['currency_sign'] ?? s.currencySign}';
    s.decimalPlaces = '${j['decimal_places'] ?? s.decimalPlaces}';
    s.temperatureFormat = '${j['temperature_format'] ?? s.temperatureFormat}';
    s.noBirthdayNotifications = j['no_birthday_notifications'] == true;
    s.hideEmailApprovalActions = j['hide_email_approval_actions'] == true;
    s.bypassOwnApprovals = j['bypass_own_approvals'] == true;
    s.clockType = '${j['clock_type'] ?? s.clockType}';
    s.clockFaceId = '${j['clock_face_id'] ?? ClockFaces.defaultId}';
    s.clockCountry = '${j['clock_country'] ?? s.clockCountry}';
    return s;
  }
}

class OrgSettingsRepository {
  OrgSettingsRepository({required this.getSession});
  final AuthSession? Function() getSession;

  static const _prefKey = 'hr360_org_settings';

  ApiClient _c() => ApiClient(tokenProvider: () async => getSession()?.token);

  Future<OrgSettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(_prefKey);
    OrgSettingsState state = OrgSettingsState();
    if (local != null && local.isNotEmpty) {
      try {
        state = OrgSettingsState.fromJson(
            Map<String, dynamic>.from(jsonDecode(local) as Map));
      } catch (_) {}
    }

    final session = getSession();
    if (session != null && !session.isDemo) {
      try {
        final res = await _c().dio.get('/settings/organization');
        final data = res.data;
        if (data is Map && data['success'] == true && data['settings'] is Map) {
          state = OrgSettingsState.fromJson(
              Map<String, dynamic>.from(data['settings'] as Map));
          await prefs.setString(_prefKey, jsonEncode(state.toJson()));
        }
      } on DioException {
        // keep local
      }
    }
    return state;
  }

  Future<void> save(OrgSettingsState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(state.toJson()));
    final session = getSession();
    if (session == null || session.isDemo) return;
    try {
      await _c().dio.post('/settings/organization', data: state.toJson());
    } on DioException {
      // local still saved
    }
  }

  Future<String?> uploadLogo(List<int> bytes, String filename) async {
    final session = getSession();
    if (session == null || session.isDemo) return null;
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _c().dio.post('/uploads/company-logo', data: form);
      final data = res.data;
      if (data is Map && data['success'] == true) {
        return data['url']?.toString() ?? data['path']?.toString();
      }
    } on DioException {
      return null;
    }
    return null;
  }
}
