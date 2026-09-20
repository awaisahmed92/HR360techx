import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR-style HR Dashboard — six workforce analytics cards.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final EmployeeState _state;

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

        final cards = [
          AnalyticsChartCard(
            title: 'Employees By Gender',
            child: DonutChart(slices: slicesFromMaps(_state.charts['gender'] ?? [])),
          ),
          AnalyticsChartCard(
            title: 'Employees By Companies',
            child: HalfDonutChart(slices: slicesFromMaps(_state.charts['companies'] ?? [])),
          ),
          AnalyticsChartCard(
            title: 'Employees By Departments',
            child: ColumnBarChart(slices: slicesFromMaps(_state.charts['departments'] ?? [])),
          ),
          AnalyticsChartCard(
            title: 'Employees By Age Group',
            child: ColumnBarChart(slices: slicesFromMaps(_state.charts['age_groups'] ?? [])),
          ),
          AnalyticsChartCard(
            title: 'Employees By Categories',
            child: DonutChart(slices: slicesFromMaps(_state.charts['categories'] ?? [])),
          ),
          AnalyticsChartCard(
            title: 'Employees By Divisions',
            child: ColumnBarChart(slices: slicesFromMaps(_state.charts['divisions'] ?? [])),
          ),
        ];

        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text(
                'HR Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HrUi.label(context),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cols = w >= 1180 ? 3 : w >= 760 ? 2 : 1;
                  final gap = 14.0;
                  final itemW = (w - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in cards)
                        SizedBox(width: itemW, child: card),
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
