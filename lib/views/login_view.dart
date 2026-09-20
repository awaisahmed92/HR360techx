import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/config/login_backgrounds.dart';
import '../core/network/api_client.dart';

/// WebHR-style employee login — wide white card, label-left gray fields.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _orgCtrl = TextEditingController(text: 'demo');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  late final ImageProvider _bgImage;
  String? _logoUrl;
  Timer? _brandDebounce;
  static const _prefOrg = 'hr360_login_org';
  static const _prefUser = 'hr360_login_user';
  static const _prefRemember = 'hr360_login_remember';
  static const _prefLoginLogo = 'hr360_login_logo';

  static const _blue = Color(0xFF2A72B5);
  static const _fieldBg = Color(0xFFE8E8E8);
  static const _labelColor = Color(0xFF3A3A3A);
  static const _labelW = 128.0;

  @override
  void initState() {
    super.initState();
    _bgImage = LoginBackgrounds.randomImage();
    _orgCtrl.addListener(_onOrgChanged);
    _restoreRemembered();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(_bgImage, context);
    });
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
        _orgCtrl.text = prefs.getString(_prefOrg) ?? 'demo';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF1A1A1E)),
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
              child: Image(
                image: _bgImage,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Image.asset(
                  LoginBackgrounds.assetPath('LoginBG29.jpg'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 28,
            left: 32,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                  child: const Icon(Icons.groups, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'HR360',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 24 : 16,
                vertical: 36,
              ),
              child: Material(
                color: Colors.white,
                elevation: 18,
                shadowColor: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wide ? 560 : 440,
                    minWidth: wide ? 520 : 0,
                    minHeight: wide ? 520 : 440,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 56 : 36,
                      wide ? 48 : 36,
                      wide ? 56 : 36,
                      wide ? 40 : 32,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LoginCompanyLogo(url: _logoUrl),
                          const SizedBox(height: 22),
                          const Text(
                            'Employee Login',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _rowField(
                            label: 'Organization:',
                            child: TextFormField(
                              controller: _orgCtrl,
                              textInputAction: TextInputAction.next,
                              style: _fieldTextStyle,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: _deco('Organization'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _rowField(
                            label: 'Employee ID:',
                            child: TextFormField(
                              controller: _userCtrl,
                              textInputAction: TextInputAction.next,
                              style: _fieldTextStyle,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: _deco('Employee ID'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _rowField(
                            label: 'Password:',
                            child: TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              style: _fieldTextStyle,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                              decoration: _deco('Password').copyWith(
                                suffixIcon: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              onTap: () => setState(() => _remember = !_remember),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: _remember,
                                      activeColor: _blue,
                                      side: BorderSide(color: Colors.grey.shade500),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (v) =>
                                          setState(() => _remember = v ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.busy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _blue.withValues(alpha: 0.7),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: auth.busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Ask your HR admin to reset your password.',
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF777777),
                              textStyle: const TextStyle(fontSize: 13.5),
                            ),
                            child: const Text('Forgot your password?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _fieldTextStyle => const TextStyle(
        fontSize: 14,
        color: Color(0xFF222222),
      );

  Widget _rowField({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _labelW,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: _labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  InputDecoration _deco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: _blue, width: 1.5),
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
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.white : const Color(0xFFF15A24),
        borderRadius: BorderRadius.circular(10),
        border: hasLogo ? Border.all(color: const Color(0xFFE8E4DC)) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF15A24).withValues(alpha: hasLogo ? 0.12 : 0.35),
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
                errorBuilder: (_, __, ___) => const _Default360Mark(),
              ),
            )
          : const _Default360Mark(),
    );
  }
}

class _Default360Mark extends StatelessWidget {
  const _Default360Mark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '360',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 22,
        letterSpacing: -0.5,
      ),
    );
  }
}
