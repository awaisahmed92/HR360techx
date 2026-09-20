import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_state.dart';
import '../core/config/clock_faces.dart';
import '../core/config/countries.dart';
import '../core/settings/org_settings_repository.dart';
import '../theme/brand_themes.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_controls.dart';
import '../widgets/hr_form_kit.dart';

/// System Settings hub (WebHR-style): organization, general, clock faces, etc.
class SystemSettingsView extends StatefulWidget {
  const SystemSettingsView({super.key});

  @override
  State<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<SystemSettingsView> {
  static const _nav = [
    'Organization Details',
    'General Settings',
    'Rename Fields',
    'System Administrators',
    'Dashboard Widgets',
    'Clock Faces',
    'Interface Language',
    'IP Restrictions',
    'Security',
    'Mobile App',
    'Cut off Date',
  ];

  String _navItem = 'Organization Details';
  bool _loaded = false;
  bool _uploadingLogo = false;

  final _orgName = TextEditingController();
  final _startingYear = TextEditingController();
  final _contactPreferred = TextEditingController();
  final _contactLast = TextEditingController();
  final _contactEmail = TextEditingController();
  final _contactProvince = TextEditingController();
  final _contactPhone = TextEditingController();
  final _currencySign = TextEditingController();
  final _decimalPlacesCtrl = TextEditingController();

  static const _industries = [
    'Agribusiness',
    'Technology',
    'Healthcare',
    'Finance',
    'Manufacturing',
    'Education',
    'Retail',
    'Other',
  ];

  static const _provinces = [
    'Alabama',
    'California',
    'New York',
    'Texas',
    'Sindh',
    'Punjab',
    'KPK',
    'Balochistan',
    'Ontario',
    'Other',
  ];

  static const _timeZones = [
    '(GMT-08:00) Pacific Standard Time',
    '(GMT-05:00) Eastern Standard Time',
    '(GMT+00:00) Greenwich Mean Time',
    '(GMT+01:00) Central European Time',
    '(GMT+04:00) Gulf Standard Time',
    '(GMT+05:00) Pakistan Standard Time',
    '(GMT+05:30) India Standard Time',
  ];

  static const _dateFormats = [
    'YYYY-MM-DD',
    'DD/MM/YYYY',
    'MM/DD/YYYY',
    'DD-MMM-YYYY',
  ];

  static const _timeFormats = ['12 Hour Format', '24 Hour Format'];

  static const _phoneFormats = [
    '(Country Code) 999-999999',
    '+1 (999) 999-9999',
    '+92 999 9999999',
    '999-999-9999',
  ];

  static const _ssnFormats = [
    '99999-9999999-9',
    '999-99-9999',
    'AA999999A',
  ];

  static const _timeFieldFormats = ['1', '2', '3', '4', '5', '6'];

  static const _weekDays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const _nameDisplays = [
    '{Last Name}, {Preferred Name}',
    '{Preferred Name} {Last Name}',
    '{Preferred Name}',
    '{Last Name}, {First Name}',
  ];

  static const _currencies = ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'INR', 'CAD'];

  static const _temperatureFormats = ['Celsius (C)', 'Fahrenheit (F)'];

  static const _clockTypes = ['Analog Clock', 'Digital Clock'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    await app.loadOrgSettings();
    if (!mounted) return;
    _syncFromSettings(app.orgSettings);
    setState(() => _loaded = true);
  }

  void _syncFromSettings(OrgSettingsState s) {
    _orgName.text = s.orgName;
    _startingYear.text = s.startingYear;
    _contactPreferred.text = s.contactPreferred;
    _contactLast.text = s.contactLast;
    _contactEmail.text = s.contactEmail;
    _contactProvince.text = s.contactProvince;
    _contactPhone.text = s.contactPhone;
    _currencySign.text = s.currencySign;
    _decimalPlacesCtrl.text = s.decimalPlaces;
  }

  void _applyOrgDetailsToSettings(OrgSettingsState s) {
    s.orgName = _orgName.text.trim();
    s.startingYear = _startingYear.text.trim();
    s.contactPreferred = _contactPreferred.text.trim();
    s.contactLast = _contactLast.text.trim();
    s.contactEmail = _contactEmail.text.trim();
    s.contactProvince = _contactProvince.text.trim();
    s.contactPhone = _contactPhone.text.trim();
  }

  void _applyGeneralToSettings(OrgSettingsState s) {
    s.currencySign = _currencySign.text.trim().isEmpty ? '\$' : _currencySign.text.trim();
    s.decimalPlaces = _decimalPlacesCtrl.text.trim().isEmpty ? '0' : _decimalPlacesCtrl.text.trim();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    if (_navItem == 'Organization Details') {
      _applyOrgDetailsToSettings(app.orgSettings);
    }
    if (_navItem == 'General Settings') {
      _applyGeneralToSettings(app.orgSettings);
    }
    final err = await app.saveOrgSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Settings saved'),
        backgroundColor: err == null ? const Color(0xFF10B981) : Colors.redAccent,
      ),
    );
  }

  bool get _hasSave =>
      _navItem == 'Organization Details' ||
      _navItem == 'General Settings' ||
      _navItem == 'Clock Faces';

  @override
  void dispose() {
    for (final c in [
      _orgName,
      _startingYear,
      _contactPreferred,
      _contactLast,
      _contactEmail,
      _contactProvince,
      _contactPhone,
      _currencySign,
      _decimalPlacesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = app.orgSettings;

    if (!_loaded) {
      return ColoredBox(
        color: HrUi.pageBg(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return HrSettingsShell(
      title: 'System Settings',
      navItems: _nav,
      selectedNav: _navItem,
      onNav: (item) => setState(() => _navItem = item),
      onSave: _hasSave ? _save : null,
      child: switch (_navItem) {
        'Organization Details' => _OrganizationDetailsPanel(
            settings: settings,
            orgName: _orgName,
            startingYear: _startingYear,
            contactPreferred: _contactPreferred,
            contactLast: _contactLast,
            contactEmail: _contactEmail,
            contactProvince: _contactProvince,
            contactPhone: _contactPhone,
            industries: _industries,
            provinces: _provinces,
            uploadingLogo: _uploadingLogo,
            onIndustry: (v) => setState(() => settings.industry = v),
            onCountry: (v) => setState(() => settings.contactCountry = v),
            onProvince: (v) => setState(() {
              settings.contactProvince = v;
              _contactProvince.text = v;
            }),
            onUploadLogo: () => _pickLogo(app),
          ),
        'General Settings' => _GeneralSettingsPanel(
            settings: settings,
            currencySign: _currencySign,
            decimalPlaces: _decimalPlacesCtrl,
            onChanged: () => setState(() {}),
          ),
        'Clock Faces' => _ClockFacesPanel(
            settings: settings,
            clockTypes: _clockTypes,
            selectedFaceId: settings.clockFaceId,
            onClockType: (v) => setState(() => settings.clockType = v),
            onClockCountry: (code) {
              final country = Countries.byCode(code);
              setState(() {
                settings.clockCountry = country.code;
                settings.timeZone = country.timeZoneLabel;
              });
              app.setClockCountry(country.code);
            },
            onPickFace: (id) {
              setState(() => settings.clockFaceId = id);
              app.setClockFace(id);
            },
          ),
        'Rename Fields' ||
        'System Administrators' ||
        'Dashboard Widgets' ||
        'Interface Language' ||
        'IP Restrictions' ||
        'Security' ||
        'Mobile App' ||
        'Cut off Date' =>
          const _ComingSoonPanel(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Future<void> _pickLogo(AppState app) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() => _uploadingLogo = true);

    String? logoUrl;
    if (file.bytes != null) {
      logoUrl = await app.uploadOrgLogo(file.bytes!, file.name);
    }

    if (!mounted) return;
    setState(() {
      _uploadingLogo = false;
      app.orgSettings.logoUrl = logoUrl ?? file.path ?? app.orgSettings.logoUrl;
    });

    if (logoUrl == null && file.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload logo'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await app.saveOrgSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logo updated'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim();
    final hasRemote = url != null && url.isNotEmpty && url.startsWith('http');

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5C00),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasRemote
          ? Image.network(url, fit: BoxFit.cover, width: 72, height: 72)
          : const Text(
              '360',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Coming soon',
      style: TextStyle(color: HrUi.muted(context), fontSize: 14),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: HrUi.sectionTitle(context),
        ),
      ),
    );
  }
}

List<DropdownMenuItem<String>> _dropdownItems(List<String> values) =>
    values.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList();

List<DropdownMenuItem<String>> _countryFlagItems({required bool useCode}) {
  return [
    for (final c in Countries.all)
      DropdownMenuItem(
        value: useCode ? c.code : c.name,
        child: Row(
          children: [
            Text(c.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
            Text(
              c.gmtLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A8478)),
            ),
          ],
        ),
      ),
  ];
}

class _OrganizationDetailsPanel extends StatelessWidget {
  const _OrganizationDetailsPanel({
    required this.settings,
    required this.orgName,
    required this.startingYear,
    required this.contactPreferred,
    required this.contactLast,
    required this.contactEmail,
    required this.contactProvince,
    required this.contactPhone,
    required this.industries,
    required this.provinces,
    required this.uploadingLogo,
    required this.onIndustry,
    required this.onCountry,
    required this.onProvince,
    required this.onUploadLogo,
  });

  final OrgSettingsState settings;
  final TextEditingController orgName;
  final TextEditingController startingYear;
  final TextEditingController contactPreferred;
  final TextEditingController contactLast;
  final TextEditingController contactEmail;
  final TextEditingController contactProvince;
  final TextEditingController contactPhone;
  final List<String> industries;
  final List<String> provinces;
  final bool uploadingLogo;
  final ValueChanged<String> onIndustry;
  final ValueChanged<String> onCountry;
  final ValueChanged<String> onProvince;
  final VoidCallback onUploadLogo;

  @override
  Widget build(BuildContext context) {
    final logoUrl = settings.logoUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrFormRow(
          label: 'Organization Code',
          showInfo: false,
          child: Text(
            settings.orgCode,
            style: TextStyle(
              color: HrUi.label(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        HrFormRow(
          label: 'Organization Url',
          showInfo: false,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                final uri = Uri.tryParse(settings.orgUrl);
                if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text(settings.orgUrl),
            ),
          ),
        ),
        HrFormRow(
          label: 'Organization Name',
          required: true,
          child: TextField(
            controller: orgName,
            decoration: hrFieldDecoration(context, hint: 'Organization Name'),
          ),
        ),
        HrFormRow(
          label: 'Industry',
          child: HrDropdown<String>(
            value: settings.industry,
            items: _dropdownItems(industries),
            onChanged: (v) {
              if (v != null) onIndustry(v);
            },
          ),
        ),
        HrFormRow(
          label: 'Organization Starting Year',
          child: TextField(
            controller: startingYear,
            keyboardType: TextInputType.number,
            decoration: hrFieldDecoration(context, hint: 'e.g. 2020'),
          ),
        ),
        const _SectionHeader('Contact Person'),
        HrFormRow(
          label: 'Preferred Name',
          child: TextField(
            controller: contactPreferred,
            decoration: hrFieldDecoration(context),
          ),
        ),
        HrFormRow(
          label: 'Last Name',
          child: TextField(
            controller: contactLast,
            decoration: hrFieldDecoration(context),
          ),
        ),
        HrFormRow(
          label: 'Email Address',
          child: TextField(
            controller: contactEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: hrFieldDecoration(context),
          ),
        ),
        HrFormRow(
          label: 'Country',
          child: HrDropdown<String>(
            value: Countries.byName(settings.contactCountry).name,
            items: _countryFlagItems(useCode: false),
            onChanged: (v) {
              if (v != null) onCountry(v);
            },
          ),
        ),
        HrFormRow(
          label: 'Province',
          child: HrDropdown<String>(
            value: provinces.contains(settings.contactProvince)
                ? settings.contactProvince
                : (settings.contactProvince.isEmpty ? null : 'Other'),
            hint: 'Select province',
            items: _dropdownItems(provinces),
            onChanged: (v) {
              if (v != null) onProvince(v);
            },
          ),
        ),
        if (!provinces.contains(settings.contactProvince) &&
            settings.contactProvince.isNotEmpty)
          HrFormRow(
            label: 'Province (Other)',
            child: TextField(
              controller: contactProvince,
              decoration: hrFieldDecoration(context),
            ),
          ),
        HrFormRow(
          label: 'Phone Number',
          child: TextField(
            controller: contactPhone,
            keyboardType: TextInputType.phone,
            decoration: hrFieldDecoration(context),
          ),
        ),
        const _SectionHeader('Organization Logo'),
        HrFormRow(
          label: 'Logo',
          showInfo: false,
          child: Row(
            children: [
              _LogoPreview(logoUrl: logoUrl),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: uploadingLogo ? null : onUploadLogo,
                icon: uploadingLogo
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(uploadingLogo ? 'Uploading…' : 'Upload Logo'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneralSettingsPanel extends StatelessWidget {
  const _GeneralSettingsPanel({
    required this.settings,
    required this.currencySign,
    required this.decimalPlaces,
    required this.onChanged,
  });

  final OrgSettingsState settings;
  final TextEditingController currencySign;
  final TextEditingController decimalPlaces;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader('Date & Time'),
        HrFormRow(
          label: 'Default Time Zone',
          child: HrDropdown<String>(
            value: settings.timeZone,
            items: _dropdownItems(_SystemSettingsViewState._timeZones),
            onChanged: (v) {
              if (v == null) return;
              settings.timeZone = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Date Formats',
          child: HrDropdown<String>(
            value: settings.dateFormat,
            items: _dropdownItems(_SystemSettingsViewState._dateFormats),
            onChanged: (v) {
              if (v == null) return;
              settings.dateFormat = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Time Formats',
          child: HrDropdown<String>(
            value: settings.timeFormat,
            items: _dropdownItems(_SystemSettingsViewState._timeFormats),
            onChanged: (v) {
              if (v == null) return;
              settings.timeFormat = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Phone Number Format',
          child: HrDropdown<String>(
            value: settings.phoneFormat,
            items: _dropdownItems(_SystemSettingsViewState._phoneFormats),
            onChanged: (v) {
              if (v == null) return;
              settings.phoneFormat = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Social Security Number (SSN) Format',
          child: HrDropdown<String>(
            value: settings.ssnFormat,
            items: _dropdownItems(_SystemSettingsViewState._ssnFormats),
            onChanged: (v) {
              if (v == null) return;
              settings.ssnFormat = v;
              onChanged();
            },
          ),
        ),
        HrToggleRow(
          label: 'Show Total Time as Decimals',
          value: settings.showTimeDecimals,
          onChanged: (v) {
            settings.showTimeDecimals = v;
            onChanged();
          },
        ),
        HrFormRow(
          label: 'Time Field Format',
          child: HrDropdown<String>(
            value: settings.timeFieldFormat,
            items: _dropdownItems(_SystemSettingsViewState._timeFieldFormats),
            onChanged: (v) {
              if (v == null) return;
              settings.timeFieldFormat = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Calendar Start Day',
          child: HrDropdown<String>(
            value: settings.calendarStartDay,
            items: _dropdownItems(_SystemSettingsViewState._weekDays),
            onChanged: (v) {
              if (v == null) return;
              settings.calendarStartDay = v;
              onChanged();
            },
          ),
        ),
        const _SectionHeader('User Interface (UI)'),
        HrFormRow(
          label: 'Default Theme',
          child: HrDropdown<String>(
            value: settings.defaultTheme.isEmpty
                ? BrandThemes.defaultId
                : settings.defaultTheme,
            items: BrandThemes.all
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              settings.defaultTheme = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Employee Name Display',
          child: HrDropdown<String>(
            value: settings.employeeNameDisplay,
            items: _dropdownItems(_SystemSettingsViewState._nameDisplays),
            onChanged: (v) {
              if (v == null) return;
              settings.employeeNameDisplay = v;
              onChanged();
            },
          ),
        ),
        const _SectionHeader('Currency'),
        HrFormRow(
          label: 'Base Currency',
          child: HrDropdown<String>(
            value: settings.baseCurrency,
            items: _dropdownItems(_SystemSettingsViewState._currencies),
            onChanged: (v) {
              if (v == null) return;
              settings.baseCurrency = v;
              onChanged();
            },
          ),
        ),
        HrFormRow(
          label: 'Base Currency Sign',
          child: TextField(
            controller: currencySign,
            onChanged: (_) => onChanged(),
            decoration: hrFieldDecoration(context, hint: '\$'),
          ),
        ),
        HrFormRow(
          label: 'Number of Decimal Places',
          child: TextField(
            controller: decimalPlaces,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
            decoration: hrFieldDecoration(context, hint: '0'),
          ),
        ),
        const _SectionHeader('Temperature'),
        HrFormRow(
          label: 'Temperature Format',
          child: HrDropdown<String>(
            value: settings.temperatureFormat,
            items: _dropdownItems(_SystemSettingsViewState._temperatureFormats),
            onChanged: (v) {
              if (v == null) return;
              settings.temperatureFormat = v;
              onChanged();
            },
          ),
        ),
        const _SectionHeader('Notifications'),
        HrToggleRow(
          label: 'Do Not Send Birthday Notifications',
          value: settings.noBirthdayNotifications,
          onChanged: (v) {
            settings.noBirthdayNotifications = v;
            onChanged();
          },
        ),
        HrToggleRow(
          label: 'Hide Email Approval Actions',
          value: settings.hideEmailApprovalActions,
          onChanged: (v) {
            settings.hideEmailApprovalActions = v;
            onChanged();
          },
        ),
        const _SectionHeader('Approvals'),
        HrToggleRow(
          label: 'Bypass Approvals For Own Records',
          value: settings.bypassOwnApprovals,
          onChanged: (v) {
            settings.bypassOwnApprovals = v;
            onChanged();
          },
        ),
      ],
    );
  }
}

class _ClockFacesPanel extends StatelessWidget {
  const _ClockFacesPanel({
    required this.settings,
    required this.clockTypes,
    required this.selectedFaceId,
    required this.onClockType,
    required this.onClockCountry,
    required this.onPickFace,
  });

  final OrgSettingsState settings;
  final List<String> clockTypes;
  final String selectedFaceId;
  final ValueChanged<String> onClockType;
  final ValueChanged<String> onClockCountry;
  final ValueChanged<String> onPickFace;

  @override
  Widget build(BuildContext context) {
    final clockCountry = Countries.byCode(
      settings.clockCountry.isNotEmpty
          ? settings.clockCountry
          : settings.contactCountry,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrFormRow(
          label: 'Clock Types',
          child: HrDropdown<String>(
            value: settings.clockType,
            items: _dropdownItems(clockTypes),
            onChanged: (v) {
              if (v != null) onClockType(v);
            },
          ),
        ),
        HrFormRow(
          label: 'Clock Country',
          child: HrDropdown<String>(
            value: clockCountry.code,
            items: _countryFlagItems(useCode: true),
            onChanged: (v) {
              if (v != null) onClockCountry(v);
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Clock Faces',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: HrUi.label(context),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 18,
          runSpacing: 20,
          children: [
            for (final face in ClockFaces.all)
              _ClockFaceTile(
                face: face,
                selected: face.id == selectedFaceId,
                onTap: () => onPickFace(face.id),
              ),
          ],
        ),
      ],
    );
  }
}

class _ClockFaceTile extends StatelessWidget {
  const _ClockFaceTile({
    required this.face,
    required this.selected,
    required this.onTap,
  });

  final ClockFaceOption face;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: face.colors,
                    ),
                    border: selected
                        ? Border.all(color: Colors.white, width: 3)
                        : Border.all(color: HrUi.border(context), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(face.icon, color: Colors.white.withValues(alpha: 0.92), size: 32),
                ),
                if (selected)
                  Positioned(
                    top: 2,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 16, color: HrTheme.brand(context)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              face.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: HrUi.label(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
