import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ss = context.read<SelfServiceState>();
      await ss.loadProfile();
      final p = ss.profile;
      if (p != null && mounted) {
        _email.text = (p['email'] ?? '').toString();
        _phone.text = (p['phone'] ?? '').toString();
        setState(() => _loaded = true);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ss = context.watch<SelfServiceState>();
    final isDark = app.isDarkMode;
    final p = ss.profile;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final card = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: !_loaded && p == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        )),
                    const SizedBox(height: 6),
                    Text('View and update your contact details',
                        style: TextStyle(color: textSecondary, fontSize: 13)),
                    const SizedBox(height: 24),
                    _row('Name', (p?['name'] ?? '').toString(), textPrimary, textSecondary),
                    _row('Code', (p?['employee_code'] ?? '').toString(), textPrimary, textSecondary),
                    _row('Designation', (p?['designation_name'] ?? '').toString(), textPrimary, textSecondary),
                    _row('Department', (p?['department_name'] ?? '').toString(), textPrimary, textSecondary),
                    _row('Station', (p?['station_name'] ?? '').toString(), textPrimary, textSecondary),
                    _row('Line manager', (p?['line_manager_name'] ?? '—').toString(), textPrimary, textSecondary),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: () async {
                        final err = await ss.saveProfile(
                          email: _email.text.trim(),
                          phone: _phone.text.trim(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err ?? 'Profile saved'),
                            backgroundColor: err == null ? AppTheme.success : AppTheme.danger,
                          ),
                        );
                      },
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color primary, Color secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: secondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
