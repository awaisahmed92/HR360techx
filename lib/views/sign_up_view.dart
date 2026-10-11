import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/signup_service.dart';
import '../core/config/app_config.dart';
import '../core/config/countries.dart';
import '../widgets/company_logo.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/phone_field.dart';

/// Public self sign-up. Creates an organization with its own tenant database
/// and a single admin user holding every right.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key, this.onBackToLogin});

  final VoidCallback? onBackToLogin;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with SingleTickerProviderStateMixin {
  static const _brand = Color(0xFF1E4B8C);
  static const _ink = Color(0xFF16233A);
  static const _border = Color(0xFFD5DBE5);

  final _formKey = GlobalKey<FormState>();
  final _service = SignupService();

  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();

  String? _country = 'Pakistan';
  String? _captchaToken;
  Uint8List? _captchaBytes;
  bool _captchaLoading = true;
  String _phoneCountry = 'US';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  double _progress = 0;
  DateTime? _progressStarted;
  Timer? _progressTimer;
  late final AnimationController _spin;
  String? _error;
  String? _codeHint;
  bool _codeOk = false;
  Timer? _codeDebounce;
  SignupResult? _done;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _companyCtrl.addListener(_suggestCode);
    _codeCtrl.addListener(_onCodeChanged);
    _loadCaptcha();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _spin.dispose();
    _codeDebounce?.cancel();
    _companyCtrl.removeListener(_suggestCode);
    _codeCtrl.removeListener(_onCodeChanged);
    for (final c in [
      _nameCtrl,
      _companyCtrl,
      _codeCtrl,
      _designationCtrl,
      _industryCtrl,
      _emailCtrl,
      _phoneCtrl,
      _passCtrl,
      _confirmCtrl,
      _captchaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _codeTouched = false;

  /// Offer a code derived from the company name until the user types their own.
  void _suggestCode() {
    if (_codeTouched) return;
    final slug = _slug(_companyCtrl.text);
    if (slug == _codeCtrl.text) return;
    _codeCtrl.value = TextEditingValue(
      text: slug,
      selection: TextSelection.collapsed(offset: slug.length),
    );
  }

  static String _slug(String raw) {
    final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return cleaned.length > 40 ? cleaned.substring(0, 40) : cleaned;
  }

  void _onCodeChanged() {
    _codeDebounce?.cancel();
    setState(() {
      _codeHint = null;
      _codeOk = false;
    });
    final code = _codeCtrl.text.trim();
    if (code.length < 3) return;
    _codeDebounce = Timer(const Duration(milliseconds: 500), () async {
      final problem = await _service.checkCode(code, companyName: _companyCtrl.text);
      if (!mounted || _codeCtrl.text.trim() != code) return;
      setState(() {
        _codeHint = problem;
        _codeOk = problem == null;
      });
    });
  }

  Future<void> _loadCaptcha() async {
    setState(() {
      _captchaLoading = true;
      _error = null;
    });
    try {
      final data = await _service.captcha();
      final image = data['image']?.toString() ?? '';
      final comma = image.indexOf(',');
      final bytes = comma >= 0 ? base64Decode(image.substring(comma + 1)) : null;
      if (!mounted) return;
      setState(() {
        _captchaLoading = false;
        _captchaToken = data['token']?.toString();
        _captchaBytes = bytes;
        _captchaCtrl.clear();
      });
    } on SignupException catch (e) {
      if (!mounted) return;
      setState(() {
        _captchaLoading = false;
        _captchaBytes = null;
        _error = e.message;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final token = _captchaToken;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'The verification code is still loading. Please wait.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _progress = 0;
    });
    _startProgress();
    try {
      final result = await _service.submit(
        name: _nameCtrl.text,
        companyName: _companyCtrl.text,
        companyCode: _codeCtrl.text,
        designation: _designationCtrl.text,
        industry: _industryCtrl.text,
        country: _country!,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        phone: composePhone(_phoneCountry, _phoneCtrl.text),
        captchaToken: token,
        captchaAnswer: _captchaCtrl.text,
      );
      if (!mounted) return;
      await _completeProgress();
      if (!mounted) return;
      setState(() => _done = result);
    } on SignupException catch (e) {
      _stopProgress();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Organization was not created'),
          content: SingleChildScrollView(child: Text(e.message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      await _loadCaptcha();
    } finally {
      _stopProgress();
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Creeps toward 94% while the server builds the company database.
  void _startProgress() {
    _progressStarted = DateTime.now();
    _spin.repeat();
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final started = _progressStarted;
      if (!mounted || started == null) return;
      final seconds = DateTime.now().difference(started).inMilliseconds / 1000;
      final next = 94 * (1 - math.exp(-seconds / 36));
      setState(() => _progress = next);
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _progressStarted = null;
    if (!mounted) return;
    if (_spin.isAnimating) _spin.stop();
  }

  Future<void> _completeProgress() async {
    _progressTimer?.cancel();
    _progressTimer = null;
    final start = _progress;
    final began = DateTime.now();
    final done = Completer<void>();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      final t = (DateTime.now().difference(began).inMilliseconds / 420).clamp(0.0, 1.0);
      final eased = 1 - math.pow(1 - t, 3).toDouble();
      if (!mounted) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      setState(() => _progress = start + (100 - start) * eased);
      if (t >= 1) {
        timer.cancel();
        _progressTimer = null;
        if (!done.isCompleted) done.complete();
      }
    });
    await done.future;
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  String get _progressLabel {
    if (_progress >= 100) return 'Your organization is ready';
    if (_progress < 12) return 'Checking your organization';
    if (_progress < 38) return 'Creating the company database';
    if (_progress < 70) return 'Installing HR records';
    if (_progress < 90) return 'Creating your admin account';
    return 'Finishing the setup';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          const Positioned.fill(child: _SignUpBackdrop()),
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  const Expanded(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.only(left: 72),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Let's get\nsigned up!",
                          style: TextStyle(
                            fontSize: 48,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 40 : 18,
                          28,
                          wide ? 40 : 18,
                          48,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 76,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Material(
                                color: Colors.white,
                                elevation: 2,
                                shadowColor: _brand.withValues(alpha: 0.16),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                                  child: _done == null ? _buildForm() : _buildDone(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                      const Positioned(
                        right: 16,
                        bottom: 12,
                        child: Row(
                          children: [
                            Text(
                              'Powered by ',
                              style: TextStyle(fontSize: 12.5, color: Color(0xFF7A869A)),
                            ),
                            Text(
                              'HR360 TechX',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: _OrgProgressOverlay(
                progress: _progress,
                label: _progressLabel,
                spin: _spin,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _BrandMark()),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'HR360',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Create your HR360 account',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7A90)),
            ),
          ),
          const SizedBox(height: 22),
          _field(
            controller: _nameCtrl,
            label: 'UserName *',
            validator: (v) => (v ?? '').trim().isEmpty ? 'UserName is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          _field(
            controller: _companyCtrl,
            label: 'Company Name *',
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Company name is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          _field(
            controller: _codeCtrl,
            label: 'Company Code *',
            helper: _codeHint ??
                (_codeOk
                    ? 'Available — sign in at ${AppConfig.tenantUrl(_slug(_codeCtrl.text))}.'
                    : 'Letters and digits only. This code becomes your web address.'),
            helperIsError: _codeHint != null,
            onTap: () => _codeTouched = true,
            suffix: _codeOk
                ? const Icon(Icons.check_circle, color: Color(0xFF2E9E5B), size: 20)
                : null,
            validator: (v) {
              final raw = (v ?? '').trim();
              if (raw.contains('_')) {
                return 'Underscores cannot be used. This code becomes your web address.';
              }
              final code = _slug(raw);
              if (code.length < 3) return 'At least 3 letters or digits';
              if (_codeHint != null) return _codeHint;
              return null;
            },
          ),
          _field(
            controller: _designationCtrl,
            label: 'Designation *',
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Designation is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          _field(
            controller: _industryCtrl,
            label: 'Industry *',
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Industry is required' : null,
            textCapitalization: TextCapitalization.words,
          ),
          _dropdown<String>(
            label: 'Select your country *',
            value: _country,
            items: [
              for (final c in Countries.all)
                DropdownMenuItem(
                  value: c.name,
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() {
              _country = v;
              _phoneCountry = Countries.byName(v).code;
            }),
            validator: (v) => v == null ? 'Select your country' : null,
          ),
          _field(
            controller: _emailCtrl,
            label: 'Work Email *',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          PhoneField(
            controller: _phoneCtrl,
            countryCode: _phoneCountry,
            onCountryCode: (code) => setState(() => _phoneCountry = code),
          ),
          _field(
            controller: _passCtrl,
            label: 'Password *',
            obscure: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF8A95A6),
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => (v ?? '').length < 6
                ? 'Use at least 6 characters'
                : null,
          ),
          _field(
            controller: _confirmCtrl,
            label: 'Confirm Password *',
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: const Color(0xFF8A95A6),
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) =>
                v != _passCtrl.text ? 'Passwords do not match' : null,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 168,
                  height: 56,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: _captchaLoading
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _captchaBytes == null
                          ? const Center(
                              child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF8A95A6)),
                            )
                          : Image.memory(_captchaBytes!, fit: BoxFit.cover, gaplessPlayback: true),
                ),
                IconButton(
                  tooltip: 'New code',
                  onPressed: _busy ? null : _loadCaptcha,
                  icon: const Icon(Icons.refresh, color: _brand),
                ),
              ],
            ),
          ),
          _field(
            controller: _captchaCtrl,
            label: 'Verification code *',
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v ?? '').trim().length < 4
                ? 'Type the characters shown above'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3C0C0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFC0392B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                      _busy ? 'Please wait…' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _busy ? null : widget.onBackToLogin,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B7A90),
              ),
              child: const Text('Already have an account? Sign in'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToSignIn() async {
    final code = _done?.organization.trim() ?? '';
    if (kIsWeb && code.isNotEmpty) {
      final opened = await launchUrl(
        Uri.parse(AppConfig.tenantUrl(code)),
        webOnlyWindowName: '_self',
      );
      if (opened) return;
    }
    widget.onBackToLogin?.call();
  }

  Widget _buildDone() {
    final done = _done!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.check_circle, color: Color(0xFF2E9E5B), size: 56),
        ),
        const SizedBox(height: 16),
        Text(
          '${done.companyName} is ready',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Keep these details — you need them to sign in.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7A90)),
        ),
        const SizedBox(height: 20),
        _summaryRow('Sign-in address', AppConfig.tenantUrl(done.organization)),
        _summaryRow('Company Code', done.organization),
        _summaryRow('UserName', _nameCtrl.text.trim()),
        _summaryRow('Password', 'The password you just chose'),
        const SizedBox(height: 8),
        Text(
          'Open ${AppConfig.tenantUrl(done.organization)} and sign in with your username and password.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xFF6B7A90)),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _goToSignIn,
            style: FilledButton.styleFrom(
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Go to Sign In',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A869A)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? helper,
    bool helperIsError = false,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        onTap: onTap,
        style: const TextStyle(fontSize: 14.5, color: _ink),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          helperStyle: TextStyle(
            fontSize: 11.5,
            color: helperIsError ? const Color(0xFFC0392B) : const Color(0xFF8A95A6),
          ),
          suffixIcon: suffix,
          labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
          floatingLabelStyle: const TextStyle(color: _brand),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: _outline(_border),
          enabledBorder: _outline(_border),
          focusedBorder: _outline(_brand, width: 1.6),
          errorBorder: _outline(const Color(0xFFC0392B)),
          focusedErrorBorder: _outline(const Color(0xFFC0392B), width: 1.6),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: HrDropdown<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
        style: const TextStyle(fontSize: 14.5, color: _ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
          floatingLabelStyle: const TextStyle(color: _brand),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: _outline(_border),
          enabledBorder: _outline(_border),
          focusedBorder: _outline(_brand, width: 1.6),
          errorBorder: _outline(const Color(0xFFC0392B)),
          focusedErrorBorder: _outline(const Color(0xFFC0392B), width: 1.6),
        ),
      ),
    );
  }

  OutlineInputBorder _outline(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return const CompanyLogo(size: 56);
  }
}

class _SignUpBackdrop extends StatelessWidget {
  const _SignUpBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -140,
            bottom: -160,
            child: _Blob(size: 380, color: Color(0xFFD3E8F8)),
          ),
          Positioned(
            left: 80,
            bottom: -40,
            child: _Blob(size: 200, color: Color(0xFFC5E0F6)),
          ),
          Positioned(
            right: -80,
            top: -100,
            child: _Blob(size: 260, color: Color(0xFFD7EBFA)),
          ),
        ],
      ),
    );
  }
}

class _OrgProgressOverlay extends StatelessWidget {
  const _OrgProgressOverlay({
    required this.progress,
    required this.label,
    required this.spin,
  });

  final double progress;
  final String label;
  final Animation<double> spin;

  @override
  Widget build(BuildContext context) {
    final shown = progress.clamp(0, 100).round();
    return ColoredBox(
      color: const Color(0xE616233A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 168,
                  height: 168,
                  child: AnimatedBuilder(
                    animation: spin,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _PercentRingPainter(
                          progress: progress / 100,
                          spin: spin.value,
                        ),
                        child: Center(
                          child: Text(
                            '$shown%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Creating your organization. Please keep this page open.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Color(0xFFD5DEEA),
                  ),
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: const Color(0x33FFFFFF),
                    color: const Color(0xFF7EB6F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PercentRingPainter extends CustomPainter {
  const _PercentRingPainter({required this.progress, required this.spin});

  final double progress;
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, track);

    final sweep = 2 * math.pi * progress.clamp(0, 1);
    if (sweep > 0) {
      final arc = Paint()
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: [Color(0xFF7EB6F6), Color(0xFF1E4B8C), Color(0xFF06B6D4)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);
    }

    final headAngle = -math.pi / 2 + (spin * 2 * math.pi);
    final head = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );
    canvas.drawCircle(
      head,
      7,
      Paint()..color = const Color(0xFF7EB6F6),
    );
    canvas.drawCircle(
      head,
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PercentRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.spin != spin;
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
