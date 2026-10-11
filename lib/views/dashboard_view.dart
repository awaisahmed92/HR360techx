import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/hr_form_kit.dart';

/// HR Dashboard — ratio menu on the left, workforce charts on the right.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final EmployeeState _state;
  String _section = 'overview';

  static const _sections = <(String, String)>[
    ('overview', 'Overview'),
    ('turnover', 'Turnover & Retention'),
    ('growth', 'Users Growth Over Time'),
    ('gender', 'Users By Gender'),
    ('geo', 'Geographic Map'),
  ];

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        if (_state.busy && _state.charts.values.every((e) => e.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        final charts = ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              _section == 'overview' ? 'HR Dashboard' : _sections.firstWhere((s) => s.$1 == _section).$2,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HrUi.label(context)),
            ),
            const SizedBox(height: 14),
            _grid(_cards()),
          ],
        );
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: LayoutBuilder(
            builder: (context, box) {
              final side = _sectionList(vertical: box.maxWidth >= 800);
              if (box.maxWidth < 800) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 52, child: side),
                    const Divider(height: 1),
                    Expanded(child: charts),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 230, child: side),
                  const VerticalDivider(width: 1),
                  Expanded(child: charts),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionList({required bool vertical}) {
    final tiles = [
      for (final s in _sections)
        vertical
            ? ListTile(
                dense: true,
                selected: _section == s.$1,
                selectedTileColor: const Color(0xFFF3E8E4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: Text(s.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onTap: () => setState(() => _section = s.$1),
              )
            : Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s.$2),
                  selected: _section == s.$1,
                  onSelected: (_) => setState(() => _section = s.$1),
                ),
              ),
    ];
    if (!vertical) {
      return ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: tiles);
    }
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text('HR Ratios', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ...tiles,
        ],
      ),
    );
  }

  List<Widget> _cards() {
    final c = _state.charts;
    AnalyticsChartCard card(String title, String key, AnalyticsChartType type) => AnalyticsChartCard(
          title: title,
          slices: slicesFromMaps(c[key] ?? []),
          initialType: type,
        );
    return switch (_section) {
      'turnover' => [card('Turnover & Retention', 'status', AnalyticsChartType.column)],
      'growth' => [card('Users Growth Over Time', 'growth', AnalyticsChartType.column)],
      'gender' => [card('Users By Gender', 'gender', AnalyticsChartType.donut)],
      'geo' => [card('Users By Offices', 'stations', AnalyticsChartType.column)],
      _ => [
          card('Users By Gender', 'gender', AnalyticsChartType.donut),
          card('Users By Companies', 'companies', AnalyticsChartType.pie),
          card('Users By Departments', 'departments', AnalyticsChartType.column),
          card('Users By Age Group', 'age_groups', AnalyticsChartType.column),
          card('Users By Categories', 'categories', AnalyticsChartType.donut),
          card('Users By Offices', 'stations', AnalyticsChartType.column),
          card('Users By User Types', 'types', AnalyticsChartType.bar),
          card('Users By Nationality', 'nationalities', AnalyticsChartType.column),
          card('Users By Job Titles', 'designations', AnalyticsChartType.donut),
        ],
    };
  }

  Widget _grid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 980 ? 3 : box.maxWidth >= 640 ? 2 : 1;
        const gap = 14.0;
        final itemW = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: itemW, child: card)],
        );
      },
    );
  }
}
