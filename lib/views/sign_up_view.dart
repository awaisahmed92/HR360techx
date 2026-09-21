import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/signup_service.dart';
import '../core/config/countries.dart';

/// Public self sign-up. Creates an organization with its own tenant database
/// and a single admin user holding every right.
class SignUpView extends StatefulWidget {
  const SignUpView({super.key, this.onBackToLogin});

  final VoidCallback? onBackToLogin;

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  static const _brand = Color(0xFF3B8FD9);
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

  String? _country = 'Pakistan';
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;
  String? _codeHint;
  bool _codeOk = false;
  Timer? _codeDebounce;
  SignupResult? _done;

  @override
  void initState() {
    super.initState();
    _companyCtrl.addListener(_suggestCode);
    _codeCtrl.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
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
      final problem = await _service.checkCode(code);
      if (!mounted || _codeCtrl.text.trim() != code) return;
      setState(() {
        _codeHint = problem;
        _codeOk = problem == null;
      });
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
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
        phone: _phoneCtrl.text,
      );
      if (!mounted) return;
      setState(() => _done = result);
    } on SignupException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB),
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
                                elevation: 8,
                                shadowColor: const Color(0xFF3B8FD9).withValues(alpha: 0.16),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                    ? 'Available — this is what you type at login.'
                    : 'Lowercase letters and digits. You sign in with this code.'),
            helperIsError: _codeHint != null,
            onTap: () => _codeTouched = true,
            suffix: _codeOk
                ? const Icon(Icons.check_circle, color: Color(0xFF2E9E5B), size: 20)
                : null,
            validator: (v) {
              final code = _slug(v ?? '');
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
            onChanged: (v) => setState(() => _country = v),
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
          _field(
            controller: _phoneCtrl,
            label: 'Mobile Number',
            keyboardType: TextInputType.phone,
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
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign Up',
                      style: TextStyle(
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
        _summaryRow('Company Name', done.organization),
        _summaryRow('UserName', _nameCtrl.text.trim()),
        _summaryRow('Password', 'The password you just chose'),
        const SizedBox(height: 8),
        const Text(
          'Use these three values on the login screen.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xFF6B7A90)),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: widget.onBackToLogin,
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
      child: DropdownButtonFormField<T>(
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
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5EB0F0), Color(0xFF2F7FC4)],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        '360',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
    );
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
