import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/auth_state.dart';

/// WebHR-style employee login (centered white card on dark backdrop).
/// No demo toggle — authenticates against tenant DB via API.
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

  // WebHR blue button + orange company tile
  static const _blue = Color(0xFF2B7DE9);
  static const _orange = Color(0xFFE85D04);
  static const _labelW = 110.0;

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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark photo-like backdrop (WebHR style)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0B0F),
                  Color(0xFF1A1218),
                  Color(0xFF2A0E14),
                  Color(0xFF0A0A0C),
                ],
              ),
            ),
          ),
          // Soft neon wash (lower-left, like SS)
          Positioned(
            left: -20,
            bottom: 60,
            child: IgnorePointer(
              child: Text(
                'HR',
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF1744).withOpacity(0.22),
                  letterSpacing: -4,
                  height: 1,
                ),
              ),
            ),
          ),
          // Product mark — top left (like WebHR)
          Positioned(
            top: 24,
            left: 28,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              child: Material(
                color: Colors.white,
                elevation: 12,
                shadowColor: Colors.black54,
                borderRadius: BorderRadius.circular(2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Company logo tile (orange square — like SS horse logo)
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                '360',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Employee Login',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Org = subdomain (WebHR gets this from URL; we need a field locally)
                          _rowField(
                            label: 'Organization:',
                            child: TextFormField(
                              controller: _orgCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: _deco('demo'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _rowField(
                            label: 'Employee ID:',
                            child: TextFormField(
                              controller: _userCtrl,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: _deco('Employee ID'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _rowField(
                            label: 'Password:',
                            child: TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
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
                                    size: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Remember Me — left aligned under fields
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _remember,
                                    activeColor: _blue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) =>
                                        setState(() => _remember = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _remember = !_remember),
                                  child: const Text(
                                    'Remember Me',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF555555),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: auth.busy ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _blue.withOpacity(0.7),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: auth.busy
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.vpn_key, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
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
                              foregroundColor: const Color(0xFF666666),
                              textStyle: const TextStyle(fontSize: 13),
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

  /// Label left + field right (matches WebHR SS).
  Widget _rowField({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _labelW,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  InputDecoration _deco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFEEEEEE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(fontSize: 11, height: 0.9),
    );
  }
}
