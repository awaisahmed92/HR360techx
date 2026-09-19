import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_state.dart';

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
  static const _prefOrg = 'hr360_login_org';
  static const _prefUser = 'hr360_login_user';
  static const _prefRemember = 'hr360_login_remember';

  static const _blue = Color(0xFF2A72B5);
  static const _orange = Color(0xFFF15A24);
  static const _fieldBg = Color(0xFFE8E8E8);
  static const _labelColor = Color(0xFF3A3A3A);
  static const _labelW = 128.0;

  @override
  void initState() {
    super.initState();
    _restoreRemembered();
  }

  Future<void> _restoreRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefRemember) != true) return;
    setState(() {
      _remember = true;
      _orgCtrl.text = prefs.getString(_prefOrg) ?? 'demo';
      _userCtrl.text = prefs.getString(_prefUser) ?? '';
    });
  }

  @override
  void dispose() {
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
    } else {
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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1E),
                  Color(0xFF2C2428),
                  Color(0xFF3A2A2E),
                  Color(0xFF151518),
                ],
              ),
            ),
          ),
          // Soft desk wash (photo-like without asset)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.35, -0.1),
                  radius: 1.15,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
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
                Text(
                  'HR360',
                  style: GoogleFonts.inter(
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
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: _orange.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '360',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Employee Login',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF444444),
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
                                  Text(
                                    'Remember Me',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF555555),
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
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.vpn_key, size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Login',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 22),
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
                              textStyle: GoogleFonts.inter(fontSize: 13.5),
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

  TextStyle get _fieldTextStyle => GoogleFonts.inter(
        fontSize: 14.5,
        color: const Color(0xFF333333),
        fontWeight: FontWeight.w500,
      );

  Widget _rowField({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _labelW,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _labelColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  InputDecoration _deco(String hint) {
    final radius = BorderRadius.circular(8);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: Colors.grey.shade500,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      isDense: false,
      filled: true,
      fillColor: _fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: _blue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
      errorStyle: const TextStyle(fontSize: 11.5, height: 1),
    );
  }
}
