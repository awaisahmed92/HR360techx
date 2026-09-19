import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/config/app_config.dart';
import '../core/self_service/self_service_state.dart';
import '../core/util/person_name.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// My Info — clean profile header + grouped fields (skips empty rows).
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

  String _v(Map<String, dynamic>? p, String key) {
    final raw = (p?[key] ?? '').toString().trim();
    if (raw.isEmpty || raw == '-' || raw == '0') return '';
    return raw;
  }

  String _gender(dynamic g) {
    final n = (g as num?)?.toInt();
    return switch (n) { 1 => 'Male', 2 => 'Female', _ => '' };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final ss = context.watch<SelfServiceState>();
    final brand = app.brandColor;
    final p = ss.profile;
    final name = cleanDisplayName(p?['name']?.toString());
    final title = _v(p, 'designation_name');
    final photo = AppConfig.resolveMediaUrl(p?['profile_picture']?.toString());

    if (!_loaded && p == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final jobRows = <(String, String)>[
      ('Employee ID', _v(p, 'employee_code').isNotEmpty ? _v(p, 'employee_code') : _v(p, 'user_name')),
      ('Job Title', title),
      ('Department', _v(p, 'department_name')),
      ('Station', _v(p, 'station_name')),
      ('Project', _v(p, 'project_name')),
      ('Reports To', _v(p, 'line_manager_name')),
      ('Joined', _v(p, 'joining_date')),
    ].where((e) => e.$2.isNotEmpty).toList();

    final personalRows = <(String, String)>[
      ('Date of Birth', _v(p, 'date_of_birth')),
      ('Gender', _gender(p?['gender'])),
      ('Nationality', _v(p, 'nationality')),
      ('Blood Group', _v(p, 'blood_group')),
      ('Marital Status', _v(p, 'marital_status')),
      ('Religion', _v(p, 'religion')),
      ('Race', _v(p, 'race')),
      ('CNIC', _v(p, 'cnic')),
      ('SSN', _v(p, 'ssn')),
      ('Mobile', _v(p, 'mobile_number')),
      ('Office Phone', _v(p, 'office_phone')),
      ('Address', _v(p, 'address')),
      ('Grade', _v(p, 'grade')),
      ('Category', _v(p, 'employee_category')),
      ('Service Date', _v(p, 'calculated_service_date')),
    ].where((e) => e.$2.isNotEmpty).toList();

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [brand, Color.lerp(brand, Colors.black, 0.25)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person, size: 42, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'My Info' : name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.read<AppState>().openScreen(
                        moduleId: 'dashboard',
                        subId: 'account_settings',
                      ),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                  label: const Text('Account Settings', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 820;
              final job = _sectionCard(
                context,
                title: 'Employment',
                icon: Icons.work_outline,
                child: jobRows.isEmpty
                    ? _emptyHint('No employment details yet')
                    : Column(children: [for (final r in jobRows) _infoRow(r.$1, r.$2)]),
              );
              final personal = _sectionCard(
                context,
                title: 'Personal',
                icon: Icons.badge_outlined,
                child: personalRows.isEmpty
                    ? _emptyHint('No personal details yet')
                    : Column(children: [for (final r in personalRows) _infoRow(r.$1, r.$2)]),
              );
              final contact = _sectionCard(
                context,
                title: 'Contact',
                icon: Icons.contact_mail_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        style: HrTheme.filledButton(context),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final err = await ss.saveProfile(
                            email: _email.text.trim(),
                            phone: _phone.text.trim(),
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(err ?? 'Profile saved'),
                              backgroundColor: err == null ? const Color(0xFF10B981) : Colors.redAccent,
                            ),
                          );
                        },
                        child: const Text('Save contact'),
                      ),
                    ),
                  ],
                ),
              );

              if (!wide) {
                return Column(children: [job, const SizedBox(height: 14), personal, const SizedBox(height: 14), contact]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: [job, const SizedBox(height: 14), personal])),
                  const SizedBox(width: 14),
                  Expanded(child: contact),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: HrTheme.brand(context)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HrUi.label(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: HrUi.muted(context), fontSize: 13)),
      );

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: HrUi.muted(context), fontSize: 12.5)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: HrUi.label(context),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
