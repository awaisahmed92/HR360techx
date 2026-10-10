import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../widgets/company_logo.dart';

/// Split sign-in: company, user, and password on the left, product story on the right.
class LoginView extends StatefulWidget {
  const LoginView({super.key, this.onSignUp});

  /// Opens the public sign-up form. Null hides the link.
  final VoidCallback? onSignUp;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _lockedCode = AppConfig.tenantCodeFromHost;
  final _orgCtrl = TextEditingController(text: AppConfig.tenantCodeFromHost ?? 'demo');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  String? _logoUrl;
  Timer? _brandDebounce;
  static const _prefOrg = 'hr360_login_org';
  static const _prefUser = 'hr360_login_user';
  static const _prefRemember = 'hr360_login_remember';
  static const _prefLoginLogo = 'hr360_login_logo';

  static const _blue = Color(0xFF1E4B8C);

  @override
  void initState() {
    super.initState();
    _orgCtrl.addListener(_onOrgChanged);
    _restoreRemembered();
  }

  Future<void> _restoreRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLogo = prefs.getString(_prefLoginLogo);
    String? settingsLogo;
    try {
      final raw = prefs.getString('hr360_org_settings');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw);
        if (map is Map && map['logo_url'] != null) {
          settingsLogo = map['logo_url'].toString();
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      if (prefs.getBool(_prefRemember) == true) {
        _remember = true;
        if (_lockedCode == null) {
          _orgCtrl.text = prefs.getString(_prefOrg) ?? 'demo';
        }
        _userCtrl.text = prefs.getString(_prefUser) ?? '';
      }
      final resolved = AppConfig.resolveMediaUrl(
        (cachedLogo != null && cachedLogo.isNotEmpty) ? cachedLogo : settingsLogo,
      );
      if (resolved.isNotEmpty) _logoUrl = resolved;
    });
    await _fetchBranding(_orgCtrl.text);
  }

  void _onOrgChanged() {
    _brandDebounce?.cancel();
    _brandDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchBranding(_orgCtrl.text);
    });
  }

  Future<void> _fetchBranding(String org) async {
    final sub = org.trim().toLowerCase();
    if (sub.isEmpty) {
      if (!mounted) return;
      setState(() => _logoUrl = null);
      return;
    }
    try {
      final res = await ApiClient().dio.get(
        '/auth/branding',
        queryParameters: {'subdomain': sub},
      );
      final data = res.data;
      if (data is! Map || data['success'] != true) return;
      final resolved = AppConfig.resolveMediaUrl(data['logo']?.toString());
      if (!mounted) return;
      setState(() {
        _logoUrl = resolved.isNotEmpty ? resolved : null;
      });
      final prefs = await SharedPreferences.getInstance();
      if (resolved.isNotEmpty) {
        await prefs.setString(_prefLoginLogo, resolved);
      } else {
        await prefs.remove(_prefLoginLogo);
      }
    } catch (_) {
      // keep cached / default 360 mark
    }
  }

  @override
  void dispose() {
    _brandDebounce?.cancel();
    _orgCtrl.removeListener(_onOrgChanged);
    _orgCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final org = _orgCtrl.text.trim().toLowerCase();
    final user = _userCtrl.text.trim();
    final ok = await auth.login(
      subdomain: org,
      username: user,
      password: _passCtrl.text,
      preferDemo: false,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Invalid organization or credentials.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRemember, _remember);
    if (_remember) {
      await prefs.setString(_prefOrg, org);
      await prefs.setString(_prefUser, user);
    }
    final companyLogo = AppConfig.resolveMediaUrl(auth.company?.logo);
    if (companyLogo.isNotEmpty) {
      await prefs.setString(_prefLoginLogo, companyLogo);
    }
    if (!_remember) {
      await prefs.remove(_prefOrg);
      await prefs.remove(_prefUser);
    }
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final form = _formCard(auth);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    Expanded(flex: 38, child: form),
                    const Expanded(flex: 62, child: _HrHero()),
                  ],
                )
              : form,
        ),
      ),
    );
  }

  Widget _formCard(AuthState auth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _LoginCompanyLogo(url: _logoUrl),
                    const SizedBox(width: 10),
                    const Text(
                      'HR360',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Text('Welcome Back', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Sign in to continue', style: TextStyle(color: Color(0xFF6B7280), fontSize: 15)),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Company Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _orgCtrl,
                        readOnly: _lockedCode != null,
                        enableInteractiveSelection: _lockedCode == null,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                        decoration: _fieldDecoration(_lockedCode ?? 'demo'),
                      ),
                      const SizedBox(height: 14),
                      const Text('UserName'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _userCtrl,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'UserName is required' : null,
                        decoration: _fieldDecoration('UserName'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                        decoration: _fieldDecoration(
                          'Enter your password',
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            activeColor: _blue,
                            onChanged: (value) => setState(() => _remember = value ?? true),
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: auth.busy ? null : _submit,
                          child: auth.busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Log in'),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ask your HR admin to reset your password.')),
                            );
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      if (widget.onSignUp != null)
                        Row(
                          children: [
                            const Text("Don't have an organization? ", style: TextStyle(color: Color(0xFF6B7280))),
                            TextButton(onPressed: widget.onSignUp, child: const Text('Sign up')),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const Text('© 2026 HR360. All Rights Reserved.', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ),
      ),
            ),
          ),
        );
      },
    );
  }
}

class _HrHero extends StatelessWidget {
  const _HrHero();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'People, payroll,\nand attendance\nmade simple',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 50, height: 1.15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            const Text(
              'HR360 helps companies manage employees, leave, payroll, and approvals in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 20),
            ),
            const SizedBox(height: 34),
            Container(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 290),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF4F7FB), Color(0xFFE7EEF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E4B8C).withValues(alpha: 0.15)),
              ),
              child: const Center(
                child: Icon(Icons.groups_outlined, size: 160, color: Color(0xFF1E4B8C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCompanyLogo extends StatelessWidget {
  const _LoginCompanyLogo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim() ?? '';
    final hasLogo = resolved.isNotEmpty;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E4DC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasLogo
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                resolved,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const CompanyLogo(size: 28),
              ),
            )
          : const Padding(
              padding: EdgeInsets.all(4),
              child: CompanyLogo(size: 28),
            ),
    );
  }
}

