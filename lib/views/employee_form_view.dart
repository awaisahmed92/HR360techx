import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/employees/employee_state.dart';
import '../core/uploads/upload_service.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Lean Add/Edit employee: Personal → Job → History.
/// Account toggles live under the settings (gear) control.
class EmployeeFormView extends StatefulWidget {
  const EmployeeFormView({
    super.key,
    required this.state,
    this.editId,
    required this.onDone,
    required this.onCancel,
  });

  final EmployeeState state;
  final int? editId;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<EmployeeFormView> createState() => _EmployeeFormViewState();
}

class _EmployeeFormViewState extends State<EmployeeFormView> {
  Color get _accent => HrTheme.brand(context);
  int _step = 0;
  bool _loading = false;
  int? _editId;
  String? _photoUrl;

  // Account / identity
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _father = TextEditingController();
  final _userName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _cnic = TextEditingController();
  final _contact = TextEditingController();
  final _dob = TextEditingController();
  final _mobile = TextEditingController();
  int? _gender;
  String? _blood;
  String? _marital;
  String? _salutation;
  String? _visa;

  // Settings (gear)
  bool _allowLogin = true;
  bool _allowMobileLogin = false;
  bool _showOrganogram = true;
  bool _excludeReports = false;
  bool _notActively = false;
  bool _notifyEmail = true;
  final _notActiveReason = TextEditingController();

  // License / passport
  final _passportNo = TextEditingController();
  final _passportExpiry = TextEditingController();
  final _passportCountry = TextEditingController();
  final _dlNo = TextEditingController();
  final _dlExpiry = TextEditingController();

  // Weekday / address
  bool _weekdaySame = true;
  final _permAddress = TextEditingController();
  final _permCity = TextEditingController();
  final _permProvince = TextEditingController();
  final _permPostal = TextEditingController();
  final _permCountry = TextEditingController();
  final _weekAddress = TextEditingController();
  final _weekCity = TextEditingController();
  final _weekProvince = TextEditingController();
  final _weekPostal = TextEditingController();
  final _weekCountry = TextEditingController();

  // Emergency
  final _emgName = TextEditingController();
  final _emgRel = TextEditingController();
  final _emgPhone = TextEditingController();
  final _emgPhone2 = TextEditingController();
  final _emgEmail = TextEditingController();

  // Job
  int? _designation;
  int? _department;
  int? _station;
  int? _project;
  int? _manager;
  int? _employeeType;
  int? _payrollType;
  int _status = 1;
  final _joining = TextEditingController();
  final _probation = TextEditingController();
  final _contractEnd = TextEditingController();
  final _leaving = TextEditingController();
  final _eobi = TextEditingController();
  final _sessi = TextEditingController();

  // History
  final _totalExp = TextEditingController();
  final List<_EduRow> _edu = [];
  final List<_ExpRow> _exp = [];

  /// Field key → error message (required fields only).
  final Map<String, String> _fieldErrors = {};

  static const _emailRe = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

  void _clearFieldError(String key) {
    if (_fieldErrors.remove(key) != null) setState(() {});
  }

  bool _validateRequired() {
    final errors = <String, String>{};
    final code = _code.text.trim().isNotEmpty ? _code.text.trim() : _userName.text.trim();
    final email = _email.text.trim();
    final lastName = _surname.text.trim();
    final dob = _dob.text.trim();

    if (code.isEmpty) {
      errors['code'] = 'Employee Code is mandatory';
    }
    if (email.isEmpty) {
      errors['email'] = 'Email Address is mandatory';
    } else if (!RegExp(_emailRe).hasMatch(email)) {
      errors['email'] = 'Enter a valid email address';
    }
    if (_editId == null && _password.text.isEmpty) {
      errors['password'] = 'Password is mandatory';
    }
    if (lastName.isEmpty) {
      errors['surname'] = 'Last Name is mandatory';
    }
    if (dob.isEmpty) {
      errors['dob'] = 'Date of Birth is mandatory';
    }

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
      if (errors.isNotEmpty) _step = 0;
    });

    if (errors.isNotEmpty) {
      _toast('Please fill the highlighted mandatory fields.');
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _editId = widget.editId;
    _edu.add(_EduRow());
    _exp.add(_ExpRow());
    if (_editId != null) {
      _loadDetail();
    } else {
      _loadNextCode();
    }
  }

  Future<void> _loadNextCode() async {
    final code = await widget.state.fetchNextEmployeeCode();
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      setState(() {
        _userName.text = code;
        _code.text = code;
      });
    }
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final data = await widget.state.getById(_editId!);
    if (!mounted) return;
    if (data == null) {
      setState(() => _loading = false);
      return;
    }
    _fill(asMap(data['employee']));
    _edu
      ..clear()
      ..addAll(((data['education'] as List?) ?? []).map((x) => _EduRow.fromMap(asMap(x))));
    if (_edu.isEmpty) _edu.add(_EduRow());
    _exp
      ..clear()
      ..addAll(((data['experience'] as List?) ?? []).map((x) => _ExpRow.fromMap(asMap(x))));
    if (_exp.isEmpty) _exp.add(_ExpRow());
    setState(() => _loading = false);
  }

  Map<String, dynamic> asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry('$k', val));
    return {};
  }

  void _fill(Map<String, dynamic> e) {
    _name.text = '${e['name'] ?? ''}';
    _surname.text = '${e['surname'] ?? ''}';
    _father.text = '${e['father_name'] ?? ''}';
    _userName.text = '${e['user_name'] ?? ''}';
    _email.text = '${e['email'] ?? ''}';
    _code.text = '${e['employee_code'] ?? ''}';
    _cnic.text = '${e['cnic'] ?? ''}';
    _contact.text = '${e['contact_number'] ?? e['phone'] ?? ''}';
    _dob.text = '${e['date_of_birth'] ?? ''}';
    _mobile.text = '${e['mobile_number'] ?? ''}';
    _gender = _nz(e['gender']);
    _blood = e['blood_group']?.toString();
    _marital = e['marital_status']?.toString();
    _salutation = e['salutation']?.toString();
    _visa = e['visa_sponsorship']?.toString();
    _passportNo.text = '${e['passport_number'] ?? ''}';
    _passportExpiry.text = '${e['passport_expiry'] ?? ''}';
    _passportCountry.text = '${e['passport_country'] ?? ''}';
    _dlNo.text = '${e['driving_license'] ?? ''}';
    _dlExpiry.text = '${e['driving_license_expiry'] ?? ''}';
    _notActiveReason.text = '${e['not_actively_reason'] ?? ''}';
    _permAddress.text = '${e['permanent_address'] ?? e['address'] ?? ''}';
    _permCity.text = '${e['permanent_city'] ?? ''}';
    _permProvince.text = '${e['permanent_province'] ?? ''}';
    _permPostal.text = '${e['permanent_postal'] ?? ''}';
    _permCountry.text = '${e['permanent_country'] ?? ''}';
    _weekAddress.text = '${e['weekday_address'] ?? ''}';
    _weekCity.text = '${e['weekday_city'] ?? ''}';
    _weekProvince.text = '${e['weekday_province'] ?? ''}';
    _weekPostal.text = '${e['weekday_postal'] ?? ''}';
    _weekCountry.text = '${e['weekday_country'] ?? ''}';
    _weekdaySame = (e['weekday_same_as_permanent'] as num?)?.toInt() != 0;
    _emgName.text = '${e['emg_name'] ?? ''}';
    _emgRel.text = '${e['emg_relationship'] ?? ''}';
    _emgPhone.text = '${e['emg_phone'] ?? ''}';
    _emgPhone2.text = '${e['emg_phone2'] ?? ''}';
    _emgEmail.text = '${e['emg_email'] ?? ''}';
    _allowMobileLogin = (e['allow_mobile_login'] as num?)?.toInt() == 1;
    _showOrganogram = (e['show_in_organogram'] as num?)?.toInt() != 0;
    _excludeReports = (e['exclude_from_reports'] as num?)?.toInt() == 1;
    _notActively = (e['not_actively_working'] as num?)?.toInt() == 1;
    _notifyEmail = (e['notify_by_email'] as num?)?.toInt() != 0;
    _designation = _nz(e['designation']);
    _department = _nz(e['department']);
    _station = _nz(e['station']);
    _project = _nz(e['project']);
    _manager = _nz(e['line_manager']);
    _employeeType = _nz(e['employee_type']);
    _payrollType = _nz(e['payroll_type']);
    _status = (e['status'] as num?)?.toInt() ?? 1;
    _allowLogin = _status > 0;
    _joining.text = '${e['joining_date'] ?? ''}';
    _probation.text = '${e['probation_end_date'] ?? ''}';
    _contractEnd.text = '${e['contract_end_date'] ?? ''}';
    _leaving.text = '${e['leaving_date'] ?? e['exit_date'] ?? ''}';
    _eobi.text = '${e['eobi'] ?? ''}';
    _sessi.text = '${e['sessi'] ?? ''}';
    _totalExp.text = '${e['total_experience'] ?? ''}';
    _photoUrl = AppConfig.resolveMediaUrl(e['profile_picture']?.toString());
  }

  int? _nz(dynamic v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n > 0 ? n : null;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _surname, _father, _userName, _email, _password, _code, _cnic, _contact, _dob,
      _mobile, _notActiveReason, _passportNo, _passportExpiry, _passportCountry, _dlNo, _dlExpiry,
      _permAddress, _permCity, _permProvince, _permPostal, _permCountry,
      _weekAddress, _weekCity, _weekProvince, _weekPostal, _weekCountry,
      _emgName, _emgRel, _emgPhone, _emgPhone2, _emgEmail,
      _joining, _probation, _contractEnd, _leaving, _eobi, _sessi, _totalExp,
    ]) {
      c.dispose();
    }
    for (final e in _edu) {
      e.dispose();
    }
    for (final e in _exp) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_validateRequired()) return;

    final code = _code.text.trim().isNotEmpty ? _code.text.trim() : _userName.text.trim();
    final email = _email.text.trim();
    final lastName = _surname.text.trim();
    final dob = _dob.text.trim();
    final firstName = _name.text.trim();
    final displayName = firstName.isNotEmpty ? firstName : lastName;

    final body = <String, dynamic>{
      'name': displayName,
      'surname': lastName,
      'father_name': _father.text.trim(),
      'employee_code': code,
      // Login id follows employee code for new records (server may still auto-allocate if blank)
      if (_editId == null) 'user_name': code,
      if (_editId != null && _userName.text.trim().isNotEmpty) 'user_name': _userName.text.trim(),
      'email': email,
      'cnic': _cnic.text.trim(),
      'contact_number': _contact.text.trim(),
      'mobile_number': _mobile.text.trim(),
      'date_of_birth': dob,
      'gender': _gender,
      'blood_group': _blood,
      'marital_status': _marital,
      'salutation': _salutation,
      'visa_sponsorship': _visa,
      'passport_number': _passportNo.text.trim(),
      'passport_expiry': _emptyNull(_passportExpiry.text),
      'passport_country': _passportCountry.text.trim(),
      'driving_license': _dlNo.text.trim(),
      'driving_license_expiry': _emptyNull(_dlExpiry.text),
      'permanent_address': _permAddress.text.trim(),
      'permanent_city': _permCity.text.trim(),
      'permanent_province': _permProvince.text.trim(),
      'permanent_postal': _permPostal.text.trim(),
      'permanent_country': _permCountry.text.trim(),
      'weekday_same_as_permanent': _weekdaySame ? 1 : 0,
      'weekday_address': _weekAddress.text.trim(),
      'weekday_city': _weekCity.text.trim(),
      'weekday_province': _weekProvince.text.trim(),
      'weekday_postal': _weekPostal.text.trim(),
      'weekday_country': _weekCountry.text.trim(),
      'emg_name': _emgName.text.trim(),
      'emg_relationship': _emgRel.text.trim(),
      'emg_phone': _emgPhone.text.trim(),
      'emg_phone2': _emgPhone2.text.trim(),
      'emg_email': _emgEmail.text.trim(),
      'not_actively_reason': _notActively ? _notActiveReason.text.trim() : null,
      'designation': _designation,
      'department': _department,
      'station': _station,
      'project': _project,
      'line_manager': _manager,
      'employee_type': _employeeType,
      'payroll_type': _payrollType,
      'status': _allowLogin ? _status : 0,
      'allow_login': _allowLogin,
      'allow_mobile_login': _allowMobileLogin ? 1 : 0,
      'show_in_organogram': _showOrganogram ? 1 : 0,
      'exclude_from_reports': _excludeReports ? 1 : 0,
      'not_actively_working': _notActively ? 1 : 0,
      'notify_by_email': _notifyEmail ? 1 : 0,
      'joining_date': _emptyNull(_joining.text),
      'probation_end_date': _emptyNull(_probation.text),
      'contract_end_date': _emptyNull(_contractEnd.text),
      'leaving_date': _emptyNull(_leaving.text),
      'eobi': _eobi.text.trim(),
      'sessi': _sessi.text.trim(),
      'total_experience': _totalExp.text.trim(),
      'education': _edu.map((e) => e.toJson()).toList(),
      'experience': _exp.map((e) => e.toJson()).toList(),
    };
    if (_password.text.isNotEmpty) body['password'] = _password.text;

    setState(() => _loading = true);
    String? err;
    if (_editId == null) {
      final r = await widget.state.createReturningId({...body, 'password': _password.text});
      err = r.error;
      if (r.id != null) {
        _editId = r.id;
        if (r.code != null && r.code!.isNotEmpty) {
          _userName.text = r.code!;
          _code.text = r.code!;
        }
      }
    } else {
      err = await widget.state.update(_editId!, body);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      _toast(err);
      return;
    }
    _toast('Employee saved.');
    widget.onDone();
  }

  String? _emptyNull(String v) => v.trim().isEmpty ? null : v.trim();

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget toggle(String title, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(fontSize: 12, color: HrUi.muted(context))),
                value: value,
                activeThumbColor: _accent,
                onChanged: (v) {
                  setLocal(() => onChanged(v));
                  setState(() {});
                },
              );
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings_outlined, color: _accent),
                  const SizedBox(width: 8),
                  const Text('Employee Settings'),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      toggle('Allow Employee Login', _allowLogin, (v) => _allowLogin = v,
                          subtitle: 'Can sign in to the HR portal'),
                      toggle('Allow Mobile Login', _allowMobileLogin, (v) => _allowMobileLogin = v),
                      toggle('Notifications By Email', _notifyEmail, (v) => _notifyEmail = v),
                      toggle('Show In Organogram', _showOrganogram, (v) => _showOrganogram = v),
                      toggle('Exclude from Reports / Dashboard', _excludeReports, (v) => _excludeReports = v),
                      toggle('Not Actively Working', _notActively, (v) => _notActively = v),
                      if (_notActively) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notActiveReason,
                          decoration: _deco(hint: 'Reason'),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _accent),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _editId != null && _name.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;
          final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0;
          return SizedBox(
            width: w,
            height: h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(
                    children: [
                      IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.arrow_back)),
                      Expanded(
                        child: Text(
                          _editId == null ? 'Add New Employee' : 'Edit Employee',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: HrUi.label(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Tooltip(
                        message: 'Employee settings',
                        child: IconButton(
                          onPressed: _openSettings,
                          icon: Icon(Icons.settings_outlined, color: _accent),
                        ),
                      ),
                      TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                  child: _stepHeader(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    children: [
                      if (_step == 0) _personalStep(),
                      if (_step == 1) _jobStep(),
                      if (_step == 2) _historyStep(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (_step > 0)
                            OutlinedButton(
                              onPressed: () => setState(() => _step--),
                              child: const Text('Back'),
                            ),
                          const Spacer(),
                          if (_step < 2)
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: _accent),
                              onPressed: () => setState(() => _step++),
                              child: const Text('Next'),
                            )
                          else
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: _accent),
                              onPressed: _loading ? null : _save,
                              child: Text(_editId == null ? 'Create Employee' : 'Save Changes'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stepHeader() {
    const labels = ['Personal', 'Job', 'History'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: _step > i - 1 ? _accent : Colors.grey.shade300,
              ),
            ),
          InkWell(
            onTap: () => setState(() => _step = i),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _step >= i ? _accent : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  child: _step > i
                      ? const Icon(Icons.check, size: 16)
                      : Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontWeight: _step == i ? FontWeight.w700 : FontWeight.w500,
                    color: _step >= i ? HrUi.label(context) : HrUi.muted(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  HrFormSection(title: 'Login & Identity', children: [
                    _grid([
                      HrFormRow(
                        label: 'Employee ID',
                        child: TextField(
                          controller: _userName,
                          readOnly: true,
                          enabled: false,
                          decoration: _deco(hint: 'Auto').copyWith(
                            filled: true,
                            fillColor: HrUi.fieldBg(context),
                            suffixIcon: Icon(Icons.lock_outline, size: 16, color: HrUi.muted(context)),
                          ),
                        ),
                      ),
                      _tf('Employee Code *', _code, errorKey: 'code'),
                      _tf('Email Address *', _email, errorKey: 'email'),
                      _tf(
                        _editId == null ? 'Password *' : 'Password (optional)',
                        _password,
                        obscure: true,
                        errorKey: _editId == null ? 'password' : null,
                      ),
                    ]),
                  ]),
                  HrFormSection(title: 'Personal Information', children: [
                    _grid([
                      _strDd(
                        'Salutation',
                        _salutation,
                        (widget.state.options['salutations'] as List?)?.map((e) => '$e').toList() ??
                            ['Mr', 'Mrs', 'Ms', 'Dr'],
                        (v) => setState(() => _salutation = v),
                      ),
                      _tf('First Name', _name),
                      _tf('Last Name *', _surname, errorKey: 'surname'),
                      _tf('Father Name', _father),
                      _dateField('Date of Birth *', _dob, errorKey: 'dob'),
                      _dd('Gender', _gender, widget.state.optionList('genders'), (v) => setState(() => _gender = v)),
                      _strDd(
                        'Blood Group',
                        _blood,
                        (widget.state.options['blood_groups'] as List?)?.map((e) => '$e').toList() ?? [],
                        (v) => setState(() => _blood = v),
                      ),
                      _strDd('Marital Status', _marital, ['Single', 'Married', 'Divorced', 'Widowed'],
                          (v) => setState(() => _marital = v)),
                      _tf('CNIC', _cnic),
                      _tf('Contact Number', _contact),
                      _tf('Mobile Number', _mobile),
                    ]),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 20),
            _photoBlock(),
          ],
        ),
        HrFormSection(title: 'Driving License', children: [
          _grid([
            _tf('License Number', _dlNo),
            _dateField('Expiration', _dlExpiry),
          ]),
        ]),
        HrFormSection(title: 'Passport', children: [
          _grid([
            _tf('Passport Number', _passportNo),
            _dateField('Expiration', _passportExpiry),
            _tf('Issuance Country', _passportCountry),
          ]),
        ]),
        HrFormSection(title: 'Weekday Contact Information', children: [
          _grid([
            _tf('Address', _permAddress),
            _tf('City', _permCity),
            _tf('Province', _permProvince),
            _tf('Postal Code', _permPostal),
            _tf('Country', _permCountry),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Weekday contact same as permanent'),
            value: _weekdaySame,
            activeThumbColor: _accent,
            onChanged: (v) => setState(() => _weekdaySame = v),
          ),
          if (!_weekdaySame)
            _grid([
              _tf('Weekday Address', _weekAddress),
              _tf('City', _weekCity),
              _tf('Province', _weekProvince),
              _tf('Postal Code', _weekPostal),
              _tf('Country', _weekCountry),
            ]),
        ]),
        HrFormSection(title: 'Emergency Contact', children: [
          _grid([
            _tf('Contact Person', _emgName),
            _tf('Relationship', _emgRel),
            _tf('Phone', _emgPhone),
            _tf('Phone 2', _emgPhone2),
            _tf('Email', _emgEmail),
          ]),
        ]),
        HrFormSection(title: 'Visa Sponsorship', children: [
          _grid([
            _strDd(
              'Visa Sponsorship',
              _visa,
              (widget.state.options['visa_options'] as List?)?.map((e) => '$e').toList() ??
                  ['None', 'Required', 'Sponsored'],
              (v) => setState(() => _visa = v),
            ),
          ]),
        ]),
      ],
    );
  }

  Widget _jobStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrFormSection(title: 'Job Details', children: [
          _grid([
            _dd('Station', _station, widget.state.optionList('stations'), (v) => setState(() => _station = v)),
            _dd('Department', _department, widget.state.optionList('departments'), (v) => setState(() => _department = v)),
            _dd('Job Title', _designation, widget.state.optionList('designations'), (v) => setState(() => _designation = v)),
            _dd('Employee Type', _employeeType, widget.state.optionList('employee_types'),
                (v) => setState(() => _employeeType = v)),
            _dd('Project', _project, widget.state.optionList('projects'), (v) => setState(() => _project = v)),
            _dd('Payroll Type', _payrollType, widget.state.optionList('payroll_types'),
                (v) => setState(() => _payrollType = v)),
            _dd('Reports To', _manager, widget.state.optionList('managers'), (v) => setState(() => _manager = v)),
            _dd('Status', _status, widget.state.optionList('statuses'), (v) => setState(() => _status = v ?? 1)),
            _dateField('Joining Date', _joining),
            _dateField('Probation End', _probation),
            _dateField('Contract End', _contractEnd),
            if (_status == 0) _dateField('Leaving Date', _leaving),
            _tf('EOBI #', _eobi),
            _tf('SESSI #', _sessi),
          ]),
        ]),
      ],
    );
  }

  Widget _historyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrFormSection(title: 'Education', children: [
          for (var i = 0; i < _edu.length; i++) _eduCard(i),
          TextButton.icon(
            onPressed: () => setState(() => _edu.add(_EduRow())),
            icon: const Icon(Icons.add),
            label: const Text('Add Education'),
          ),
        ]),
        HrFormSection(title: 'Experience', children: [
          _tf('Total Experience (years)', _totalExp),
          for (var i = 0; i < _exp.length; i++) _expCard(i),
          TextButton.icon(
            onPressed: () => setState(() => _exp.add(_ExpRow())),
            icon: const Icon(Icons.add),
            label: const Text('Add Experience'),
          ),
        ]),
      ],
    );
  }

  Widget _photoBlock() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            image: _photoUrl != null && _photoUrl!.isNotEmpty
                ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: _photoUrl == null || _photoUrl!.isEmpty
              ? Icon(Icons.person, size: 52, color: Colors.grey.shade400)
              : null,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            if (_editId == null) {
              _toast('Save employee first, then upload photo.');
              return;
            }
            final r = await UploadService(context.read<AuthState>()).pickAndUploadEmployeePhoto(_editId!);
            if (r.error != null) {
              _toast(r.error!);
              return;
            }
            if (r.url != null) setState(() => _photoUrl = r.url);
          },
          child: const Text('Upload Photo'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _openSettings,
          icon: Icon(Icons.settings_outlined, size: 16, color: _accent),
          label: Text('Settings', style: TextStyle(color: _accent)),
        ),
      ],
    );
  }

  Widget _eduCard(int i) {
    final row = _edu[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: HrUi.border(context)),
          borderRadius: BorderRadius.circular(8),
          color: HrUi.card(context),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('Education ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_edu.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      _edu.removeAt(i).dispose();
                    }),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
              ],
            ),
            _grid([
              _dd('Degree', row.degreeId, widget.state.optionList('degrees'), (v) => setState(() => row.degreeId = v)),
              _tf('Institute', row.institute),
              _tf('Field', row.field),
              _dateField('From', row.from),
              _dateField('To', row.to),
              _tf('Grade', row.grade),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _expCard(int i) {
    final row = _exp[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: HrUi.border(context)),
          borderRadius: BorderRadius.circular(8),
          color: HrUi.card(context),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text('Experience ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_exp.length > 1)
                  IconButton(
                    onPressed: () => setState(() {
                      _exp.removeAt(i).dispose();
                    }),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
              ],
            ),
            _grid([
              _tf('Company', row.company),
              _tf('Location', row.location),
              _tf('Position', row.position),
              _dateField('From', row.from),
              _dateField('To', row.to),
              _tf('Reason for leaving', row.reason),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(builder: (context, c) {
      final maxW = c.maxWidth.isFinite && c.maxWidth > 0 ? c.maxWidth : 360.0;
      final cols = maxW > 900 ? 3 : (maxW > 560 ? 2 : 1);
      final cellW = ((maxW - (cols - 1) * 16) / cols).clamp(160.0, maxW);
      return Wrap(
        spacing: 16,
        runSpacing: 4,
        children: children.map((w) => SizedBox(width: cellW, child: w)).toList(),
      );
    });
  }

  Widget _tf(String label, TextEditingController c, {bool obscure = false, String? errorKey}) {
    final err = errorKey == null ? null : _fieldErrors[errorKey];
    return HrFormRow(
      label: label,
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: _deco(errorText: err),
        onChanged: errorKey == null
            ? null
            : (_) {
                if (_fieldErrors.containsKey(errorKey)) _clearFieldError(errorKey);
              },
      ),
    );
  }

  Widget _dateField(String label, TextEditingController c, {String? errorKey}) {
    final err = errorKey == null ? null : _fieldErrors[errorKey];
    return HrFormRow(
      label: label,
      child: TextField(
        controller: c,
        readOnly: true,
        decoration: _deco(hint: 'YYYY-MM-DD', errorText: err).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              Icons.calendar_today,
              size: 18,
              color: err != null ? Colors.red : null,
            ),
            onPressed: () async {
              final now = DateTime.now();
              DateTime? initial;
              try {
                if (c.text.isNotEmpty) initial = DateTime.parse(c.text);
              } catch (_) {}
              final picked = await showDatePicker(
                context: context,
                initialDate: initial ?? DateTime(now.year - 25),
                firstDate: DateTime(1950),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                c.text =
                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                if (errorKey != null) _clearFieldError(errorKey);
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _dd(String label, int? value, List<Map<String, dynamic>> items, ValueChanged<int?> onChanged) {
    final safe = value != null && items.any((e) => (e['id'] as num?)?.toInt() == value) ? value : null;
    return HrFormRow(
      label: label,
      child: DropdownButtonFormField<int>(
        value: safe,
        isExpanded: true,
        decoration: _deco(),
        items: [
          const DropdownMenuItem(value: null, child: Text('—')),
          ...items.map((e) {
            final id = (e['id'] as num?)?.toInt();
            return DropdownMenuItem(value: id, child: Text('${e['name'] ?? e['label'] ?? id}'));
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _strDd(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return HrFormRow(
      label: label,
      child: DropdownButtonFormField<String>(
        value: value != null && items.contains(value) ? value : null,
        isExpanded: true,
        decoration: _deco(),
        items: [
          const DropdownMenuItem(value: null, child: Text('—')),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _deco({String? hint, String? errorText}) {
    final hasError = errorText != null && errorText.isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: hasError ? Colors.red : HrUi.border(context),
        width: hasError ? 1.6 : 1,
      ),
    );
    return InputDecoration(
      hintText: hint,
      isDense: true,
      errorText: hasError ? errorText : null,
      errorStyle: const TextStyle(fontSize: 11, height: 1.1),
      errorMaxLines: 2,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: hasError ? Colors.red : _accent,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );
  }
}

class _EduRow {
  _EduRow();
  factory _EduRow.fromMap(Map<String, dynamic> m) {
    final r = _EduRow()
      ..degreeId = (m['degree_id'] as num?)?.toInt()
      ..institute.text = '${m['institute'] ?? ''}'
      ..field.text = '${m['field'] ?? ''}'
      ..from.text = '${m['from'] ?? ''}'
      ..to.text = '${m['to'] ?? ''}'
      ..grade.text = '${m['grade'] ?? ''}';
    return r;
  }

  int? degreeId;
  final institute = TextEditingController();
  final field = TextEditingController();
  final from = TextEditingController();
  final to = TextEditingController();
  final grade = TextEditingController();

  void dispose() {
    institute.dispose();
    field.dispose();
    from.dispose();
    to.dispose();
    grade.dispose();
  }

  Map<String, dynamic> toJson() => {
        'degree_id': degreeId,
        'institute': institute.text.trim(),
        'field': field.text.trim(),
        'from': from.text.trim().isEmpty ? null : from.text.trim(),
        'to': to.text.trim().isEmpty ? null : to.text.trim(),
        'grade': grade.text.trim(),
      };
}

class _ExpRow {
  _ExpRow();
  factory _ExpRow.fromMap(Map<String, dynamic> m) {
    final r = _ExpRow()
      ..company.text = '${m['company'] ?? ''}'
      ..location.text = '${m['location'] ?? ''}'
      ..position.text = '${m['position'] ?? ''}'
      ..from.text = '${m['from'] ?? ''}'
      ..to.text = '${m['to'] ?? ''}'
      ..reason.text = '${m['reason'] ?? ''}';
    return r;
  }

  final company = TextEditingController();
  final location = TextEditingController();
  final position = TextEditingController();
  final from = TextEditingController();
  final to = TextEditingController();
  final reason = TextEditingController();

  void dispose() {
    company.dispose();
    location.dispose();
    position.dispose();
    from.dispose();
    to.dispose();
    reason.dispose();
  }

  Map<String, dynamic> toJson() => {
        'company': company.text.trim(),
        'location': location.text.trim(),
        'position': position.text.trim(),
        'from': from.text.trim().isEmpty ? null : from.text.trim(),
        'to': to.text.trim().isEmpty ? null : to.text.trim(),
        'reason': reason.text.trim(),
      };
}
