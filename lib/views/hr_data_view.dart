import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/hr_grid_query.dart';

/// HR Data — job title, department, and office charts plus the user list.
class HrDataView extends StatefulWidget {
  const HrDataView({super.key});

  @override
  State<HrDataView> createState() => _HrDataViewState();
}

class _HrDataViewState extends State<HrDataView> {
  late final EmployeeState _charts;
  List<Map<String, dynamic>> _rows = [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _charts = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _charts.load();
      _loadPeople();
    });
  }

  @override
  void dispose() {
    _charts.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    try {
      final api = ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);
      final res = await api.dio.get('/insights/people');
      final data = res.data;
      if (data is Map && data['success'] == true && mounted) {
        setState(() {
          _rows = ((data['rows'] as List?) ?? []).map(asStringKeyedMap).toList();
        });
      }
    } on DioException {
      // Charts still render if the directory call fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = hrSearchQuery(context, _q);

    return AnimatedBuilder(
      animation: _charts,
      builder: (context, _) {
        final c = _charts.charts;
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('HR Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: HrUi.label(context))),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, box) {
                  final cols = box.maxWidth >= 980 ? 3 : 1;
                  const gap = 12.0;
                  final w = (box.maxWidth - gap * (cols - 1)) / cols;
                  Widget card(String title, String key, AnalyticsChartType type) => SizedBox(
                        width: w,
                        child: AnalyticsChartCard(
                          title: title,
                          slices: slicesFromMaps(c[key] ?? []),
                          initialType: type,
                          height: 260,
                        ),
                      );
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      card('Users By Job Titles', 'designations', AnalyticsChartType.donut),
                      card('Users By Departments', 'departments', AnalyticsChartType.bar),
                      card('Users By Offices', 'stations', AnalyticsChartType.donut),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Users List', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  HrSearchField(
                    value: query,
                    onChanged: (v) => setState(() => _q = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              hrQueryBanner(context, query, _rows.where((r) {
                final blob = '${r['name']} ${r['employee_code']} ${r['designation_name']} ${r['department_name']} ${r['station_name']}';
                return hrMatchesQuery(blob, query);
              }).length, onClear: () => setState(() => _q = '')),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF8D6E63)),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  columns: const [
                    DataColumn(label: Text('SN')),
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Employee ID')),
                    DataColumn(label: Text('Job Title')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Office')),
                  ],
                  rows: hrQueryRows([
                    for (var i = 0; i < _rows.length; i++)
                      DataRow(cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(Text('${_rows[i]['name'] ?? ''}')),
                        DataCell(Text('${_rows[i]['employee_code'] ?? _rows[i]['user_name'] ?? ''}')),
                        DataCell(Text('${_rows[i]['designation_name'] ?? ''}')),
                        DataCell(Text('${_rows[i]['department_name'] ?? ''}')),
                        DataCell(Text('${_rows[i]['station_name'] ?? ''}')),
                      ]),
                  ], query),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
