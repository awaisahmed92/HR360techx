import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR-style Employees module dashboard.
class EmployeesDashboardView extends StatefulWidget {
  const EmployeesDashboardView({super.key});

  @override
  State<EmployeesDashboardView> createState() => _EmployeesDashboardViewState();
}

class _EmployeesDashboardViewState extends State<EmployeesDashboardView> {
  late final EmployeeState _state;

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state.load();
      context.read<AppState>().loadStatusFeed();
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final s = _state.stats;
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  Icon(Icons.home_outlined, size: 18, color: HrUi.muted(context)),
                  const SizedBox(width: 8),
                  Text(
                    'Employees Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HrUi.label(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth >= 1100 ? 6 : c.maxWidth >= 720 ? 3 : 2;
                  final gap = 12.0;
                  final w = (c.maxWidth - gap * (cols - 1)) / cols;
                  final cards = [
                    _KpiCard(label: 'Total Employees', value: '${s['total']}', icon: Icons.groups_outlined, color: const Color(0xFF3B82F6)),
                    _KpiCard(label: 'Active Employees', value: '${s['active']}', icon: Icons.person_outline, color: const Color(0xFF22C55E)),
                    _KpiCard(label: 'Inactive Employees', value: '${s['inactive']}', icon: Icons.person_off_outlined, color: const Color(0xFFEF4444)),
                    _KpiCard(label: 'Employee Job Titles', value: '${s['job_titles']}', icon: Icons.badge_outlined, color: const Color(0xFF8B5CF6)),
                    _KpiCard(label: 'Employee Types', value: '${s['types']}', icon: Icons.category_outlined, color: const Color(0xFFEAB308)),
                    _KpiCard(label: 'Employee Categories', value: '${s['categories']}', icon: Icons.folder_shared_outlined, color: const Color(0xFFEC4899)),
                  ];
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in cards) SizedBox(width: w, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth >= 980;
                  final whatsNew = _Panel(
                    title: "What's New Around?",
                    child: _WhatsNew(app: app),
                  );
                  final activity = _Panel(
                    title: 'Employees Activity Feed',
                    child: _ActivityFeed(posts: app.statusFeed),
                  );
                  final divisions = AnalyticsChartCard(
                    title: 'Departments By Divisions',
                    height: 320,
                    child: DonutChart(
                      slices: slicesFromMaps(_state.charts['divisions'] ?? []),
                    ),
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        whatsNew,
                        const SizedBox(height: 12),
                        activity,
                        const SizedBox(height: 12),
                        divisions,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: whatsNew),
                      const SizedBox(width: 12),
                      Expanded(child: activity),
                      const SizedBox(width: 12),
                      Expanded(child: divisions),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final half = c.maxWidth >= 760;
                  final gender = AnalyticsChartCard(
                    title: 'Employees By Gender',
                    child: DonutChart(slices: slicesFromMaps(_state.charts['gender'] ?? [])),
                  );
                  final depts = AnalyticsChartCard(
                    title: 'Employees By Departments',
                    child: ColumnBarChart(slices: slicesFromMaps(_state.charts['departments'] ?? [])),
                  );
                  if (!half) return gender;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: gender),
                      const SizedBox(width: 12),
                      Expanded(child: depts),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HrUi.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: HrUi.muted(context), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: HrUi.label(context),
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 320),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
          ),
          child,
        ],
      ),
    );
  }
}

class _WhatsNew extends StatelessWidget {
  const _WhatsNew({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeopleBlock(
            title: 'Upcoming Anniversaries',
            people: app.upcomingAnniversaries,
            empty: 'No upcoming anniversaries.',
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 18),
          _PeopleBlock(
            title: 'Upcoming Birthdays',
            people: app.upcomingBirthdays,
            empty: 'No upcoming birthdays.',
            icon: Icons.cake_outlined,
          ),
        ],
      ),
    );
  }
}

class _PeopleBlock extends StatelessWidget {
  const _PeopleBlock({
    required this.title,
    required this.people,
    required this.empty,
    required this.icon,
  });

  final String title;
  final List<Map<String, dynamic>> people;
  final String empty;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: HrUi.label(context))),
            ),
            Text('See More', style: TextStyle(fontSize: 11, color: HrTheme.brand(context), fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        if (people.isEmpty)
          Text(empty, style: TextStyle(color: HrUi.muted(context), fontSize: 12))
        else
          for (final p in people.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: HrTheme.brand(context).withValues(alpha: 0.14),
                    child: Text(
                      (p['name'] ?? '?').toString().isNotEmpty
                          ? (p['name'] ?? '?').toString()[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: HrTheme.brand(context), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['name'] ?? ''}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: HrUi.label(context)),
                        ),
                        Text(
                          [
                            if ((p['title'] ?? '').toString().isNotEmpty) p['title'],
                            if (p['days_until'] != null) 'in ${p['days_until']} days',
                          ].join(' · '),
                          style: TextStyle(fontSize: 11, color: HrUi.muted(context)),
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, size: 16, color: HrUi.muted(context)),
                ],
              ),
            ),
      ],
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.posts});
  final List<Map<String, dynamic>> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
        child: Text('No recent activity.', style: TextStyle(color: HrUi.muted(context))),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          for (final p in posts.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: HrTheme.brand(context).withValues(alpha: 0.14),
                    child: Text(
                      (p['author'] ?? '?').toString().isNotEmpty
                          ? (p['author'] ?? '?').toString()[0].toUpperCase()
                          : '?',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: HrTheme.brand(context)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p['author'] ?? 'Employee'}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: HrUi.label(context)),
                        ),
                        Text(
                          '${p['text'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: HrUi.muted(context)),
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
}
