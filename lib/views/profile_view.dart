import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/self_service/self_service_state.dart';
import '../core/util/json_maps.dart';
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
  Map<String, dynamic> _chain = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ss = context.read<SelfServiceState>();
      await ss.loadProfile();
      await _loadChain();
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

  Future<void> _loadChain() async {
    if (!mounted) return;
    try {
      final api = ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);
      final res = await api.dio.get('/insights/chain');
      final data = res.data;
      if (data is Map && data['success'] == true && mounted) {
        setState(() => _chain = asStringKeyedMap(data));
      }
    } catch (_) {}
  }

  String _tenure(String raw) {
    final start = DateTime.tryParse(raw);
    if (start == null) return '';
    final now = DateTime.now();
    var years = now.year - start.year;
    var months = now.month - start.month;
    var days = now.day - start.day;
    if (days < 0) {
      months -= 1;
      days += 30;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years < 0) return '';
    return '$years Year · $months Months · $days Days';
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 520;
                final identity = Row(
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
                final settings = TextButton.icon(
                  onPressed: () => context.read<AppState>().openScreen(
                        moduleId: 'dashboard',
                        subId: 'account_settings',
                      ),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                  label: const Text('Account Settings', style: TextStyle(color: Colors.white)),
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      identity,
                      settings,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: identity),
                    settings,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _insightCards(context, name, title, photo),
          const SizedBox(height: 14),
          _chainCard(context),
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

  Widget _insightCards(BuildContext context, String name, String title, String photo) {
    final managers = ((_chain['managers'] as List?) ?? []).map(asStringKeyedMap).toList();
    final team = ((_chain['team'] as List?) ?? []).map(asStringKeyedMap).toList();
    final joined = _v(context.read<SelfServiceState>().profile, 'joining_date');
    final tenure = _tenure(joined);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 860;
        final summary = [
          _mini(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFE8F0FE),
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? Text(_initials(name), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)))
                      : null,
                ),
                const SizedBox(height: 8),
                Text(name.isEmpty ? 'My Info' : name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF8D6E63), borderRadius: BorderRadius.circular(20)),
                    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => context.read<AppState>().openScreen(moduleId: 'dashboard', subId: 'org_chart'),
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('Open org chart'),
                ),
              ],
            ),
          ),
          _mini(
            title: 'Reports to',
            trailing: managers.isEmpty ? null : '${managers.length}',
            child: managers.isEmpty
                ? _emptyHint('No manager is assigned. You sit at the top of this company.')
                : Column(
                    children: [
                      for (var i = 0; i < managers.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Icon(Icons.arrow_downward, size: 14, color: Color(0xFF94A3B8)),
                          ),
                        _personTile(managers[i], role: i == managers.length - 1 ? 'Your manager' : 'Their manager'),
                      ],
                    ],
                  ),
          ),
          _mini(
            title: 'My facts',
            child: Column(
              children: [
                _fact('With the company', tenure.isEmpty ? 'Join date is not set' : tenure, Icons.timelapse),
                const SizedBox(height: 8),
                _fact('Joined', joined.isEmpty ? '—' : joined, Icons.event_available_outlined),
                const SizedBox(height: 8),
                _fact('Direct reports', '${team.length}', Icons.groups_outlined),
              ],
            ),
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!wide)
              Column(children: [for (final card in summary) Padding(padding: const EdgeInsets.only(bottom: 10), child: card)])
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final card in summary) Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: card))],
              ),
            const SizedBox(height: 12),
            _teamBoard(team),
          ],
        );
      },
    );
  }

  Widget _teamBoard(List<Map<String, dynamic>> team) {
    return _sectionCard(
      context,
      title: 'My Team',
      icon: Icons.groups_outlined,
      trailing: team.isEmpty ? null : '${team.length} direct',
      child: team.isEmpty
          ? _emptyHint('Nobody reports directly to you yet.')
          : LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 980 ? 3 : c.maxWidth >= 640 ? 2 : 1;
                const gap = 10.0;
                final width = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final person in team) SizedBox(width: width, child: _personTile(person)),
                  ],
                );
              },
            ),
    );
  }

  Widget _chainCard(BuildContext context) {
    final reports = ((_chain['reports'] as List?) ?? []).map(asStringKeyedMap).toList();
    final nested = reports.fold<int>(0, (sum, node) => sum + _treeCount(node));
    return _sectionCard(
      context,
      title: 'Reporting Chain',
      icon: Icons.account_tree_outlined,
      trailing: reports.isEmpty ? null : '$nested people',
      child: reports.isEmpty
          ? _emptyHint('No one reports to you. Your manager chain is in the card above.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Each block is someone who reports to you. People listed inside that block report to them.',
                  style: TextStyle(color: HrUi.muted(context), fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                for (final node in reports) _chainGroup(node, 0),
              ],
            ),
    );
  }

  int _treeCount(Map<String, dynamic> node) {
    final kids = ((node['children'] as List?) ?? []).map(asStringKeyedMap).toList();
    return 1 + kids.fold<int>(0, (sum, kid) => sum + _treeCount(kid));
  }

  Widget _chainGroup(Map<String, dynamic> node, int depth) {
    final kids = ((node['children'] as List?) ?? []).map(asStringKeyedMap).toList();
    return Container(
      margin: EdgeInsets.only(left: depth * 18.0, bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: depth == 0 ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _personTile(
            node,
            role: kids.isEmpty ? 'No one reports to them' : '${kids.length} report${kids.length == 1 ? '' : 's'} to them',
          ),
          if (kids.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final kid in kids)
              ((kid['children'] as List?) ?? []).isEmpty
                  ? Padding(padding: const EdgeInsets.only(bottom: 6, left: 18), child: _personTile(kid))
                  : _chainGroup(kid, depth + 1),
          ],
        ],
      ),
    );
  }

  Widget _personTile(Map<String, dynamic> person, {String? role}) {
    final name = '${person['name'] ?? ''}'.trim();
    final job = '${person['designation_name'] ?? ''}'.trim();
    final office = '${person['station_name'] ?? ''}'.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE8F0FE),
          child: Text(_initials(name), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isEmpty ? 'Employee' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                [if (job.isNotEmpty) job, if (role != null && role.isNotEmpty) role].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        if (office.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            flex: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
              child: Text(
                office,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _fact(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8D6E63)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  Widget _mini({String? title, String? trailing, required Widget child}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 180),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
                if (trailing != null)
                  Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF8D6E63))),
              ],
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    String? trailing,
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HrUi.label(context),
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8E4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8D6E63))),
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
