import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Timesheet summary dashboard matching screenshot cards.
class TimesheetDashboardView extends StatelessWidget {
  const TimesheetDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final total = app.employees.length;

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Timesheet Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: HrUi.label(context),
            ),
          ),
          const SizedBox(height: 8),
          Text('Timesheet Summary',
              style: TextStyle(color: HrUi.muted(context), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: 'Total Employees', value: '$total', color: const Color(0xFF3B82F6), icon: Icons.groups),
              _StatCard(label: 'Present', value: '${app.isClockedIn ? 1 : 0}', color: const Color(0xFF22C55E), icon: Icons.how_to_reg),
              _StatCard(label: 'Absent', value: '25', color: const Color(0xFFEC4899), icon: Icons.person_remove_outlined),
              _StatCard(label: 'On Leave', value: '${app.leaveRequests.where((l) => l.status == 'Approved').length}', color: const Color(0xFFEAB308), icon: Icons.event_busy),
              const _StatCard(label: 'Travel', value: '0', color: Color(0xFF8B5CF6), icon: Icons.flight),
              const _StatCard(label: 'Holiday', value: '0', color: Color(0xFF14B8A6), icon: Icons.celebration),
              const _StatCard(label: 'Specific Days Off', value: '0', color: Color(0xFFF97316), icon: Icons.calendar_today),
              const _StatCard(label: 'Work From Home', value: '0', color: Color(0xFF1E3A8A), icon: Icons.home_work_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

/// Organizations â†’ Companies grid (WebHR-style).
class CompaniesView extends StatefulWidget {
  const CompaniesView({super.key});

  @override
  State<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<CompaniesView> {
  String _q = '';

  static final _rows = [
    {
      'code': 'HQ-001',
      'name': 'HR360 TechX Pvt Ltd',
      'status': 'Active',
      'type': 'Head Office',
      'contact': 'Frank',
      'address': 'Karachi, PK',
      'email': 'admin@hr360.local',
      'province': 'Sindh',
    },
    {
      'code': 'BR-002',
      'name': 'HR360 Lahore Branch',
      'status': 'Active',
      'type': 'Branch',
      'contact': 'Edward',
      'address': 'Lahore, PK',
      'email': 'lhr@hr360.local',
      'province': 'Punjab',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _rows
        .where((r) =>
            _q.isEmpty ||
            r.values.any((v) => v.toLowerCase().contains(_q.toLowerCase())))
        .toList();

    return HrDataGridPage(
      title: 'Companies',
      icon: Icons.business_outlined,
      columns: const [
        'S#',
        'Company Code',
        'Company Name',
        'Company Status',
        'Company Type',
        'Contact Person',
        'Address',
        'Email Address',
        'Province',
        'Action',
      ],
      onAdd: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add Company form coming soon')),
        );
      },
      onRefresh: () => setState(() {}),
      onSearch: (v) => setState(() => _q = v),
      searchHint: 'Search companiesâ€¦',
      rows: [
        for (var i = 0; i < filtered.length; i++)
          [
            Text('${i + 1}'),
            Text(filtered[i]['code']!),
            Text(filtered[i]['name']!,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(filtered[i]['status']!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            Text(filtered[i]['type']!),
            Text(filtered[i]['contact']!),
            Text(filtered[i]['address']!),
            Text(filtered[i]['email']!,
                style: const TextStyle(color: Color(0xFF2563EB))),
            Text(filtered[i]['province']!),
            Icon(Icons.more_horiz, color: HrUi.muted(context)),
          ],
      ],
    );
  }
}

/// Placeholder for modules not yet fully built.
class ModulePlaceholderView extends StatelessWidget {
  const ModulePlaceholderView({super.key, required this.title, this.icon = Icons.widgets_outlined});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: brand.withOpacity(0.15),
              child: Icon(icon, size: 36, color: brand),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: HrUi.label(context),
                )),
            const SizedBox(height: 8),
            Text('This module screen is ready in the nav â€” content coming next.',
                style: TextStyle(color: HrUi.muted(context))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: HrUi.muted(context), fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: HrUi.label(context),
                  )),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }
}


