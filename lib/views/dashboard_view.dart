import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/hr_form_kit.dart';

/// People Analytics — KPI pulse, workforce trend, and ratio charts.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final EmployeeState _state;
  String _section = 'overview';
  String _range = '30D';
  int _openJobs = 0;

  static const _sections = <(String, String)>[
    ('overview', 'Overview'),
    ('turnover', 'Turnover & Retention'),
    ('growth', 'Workforce Growth'),
    ('gender', 'By Gender'),
    ('geo', 'By Office'),
  ];

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state.load();
      _loadOpenJobs();
    });
  }

  Future<void> _loadOpenJobs() async {
    try {
      final api = ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);
      final res = await api.dio.get('/recruitment/jobs');
      final d = res.data;
      if (d is Map && d['success'] == true && mounted) {
        final jobs = ((d['jobs'] as List?) ?? []).whereType<Map>().map(asStringKeyedMap);
        setState(() {
          _openJobs = jobs.where((j) {
            final s = j['status'];
            if (s is num) return s.toInt() == 1;
            final t = '$s'.toLowerCase();
            return t.contains('open') || t == '1' || t == 'active';
          }).length;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        if (_state.busy && _state.charts.values.every((e) => e.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        final total = _state.stats['total'] ?? 0;
        final active = _state.stats['active'] ?? 0;
        final inactive = _state.stats['inactive'] ?? 0;
        final retention = total <= 0 ? 0.0 : (active / total) * 100;
        final growth = _state.charts['growth'] ?? [];

        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Text(
                'People Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: HrUi.label(context)),
              ),
              const SizedBox(height: 6),
              Text(
                'Workforce health across headcount, retention, and distribution.',
                style: TextStyle(color: HrUi.muted(context)),
              ),
              const SizedBox(height: 14),
              _kpiStrip(
                brand: brand,
                total: total,
                retention: retention,
                active: active,
                inactive: inactive,
                openJobs: _openJobs,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth >= 980;
                  final trend = _TrendCard(
                    brand: brand,
                    growth: growth,
                    retention: retention,
                    range: _range,
                    onRange: (r) => setState(() => _range = r),
                  );
                  final mix = AnalyticsChartCard(
                    title: 'Active vs inactive',
                    slices: [
                      ChartSlice(label: 'Active', value: active, color: brand),
                      ChartSlice(label: 'Inactive', value: inactive, color: const Color(0xFF94A3B8)),
                    ],
                    initialType: AnalyticsChartType.donut,
                    height: 280,
                  );
                  if (!wide) {
                    return Column(
                      children: [
                        trend,
                        const SizedBox(height: 14),
                        mix,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: trend),
                      const SizedBox(width: 14),
                      Expanded(flex: 3, child: mix),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in _sections)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s.$2),
                          selected: _section == s.$1,
                          selectedColor: brand.withValues(alpha: 0.16),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _section == s.$1 ? brand : HrTheme.textSecondary(context),
                          ),
                          onSelected: (_) => setState(() => _section = s.$1),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _sections.firstWhere((s) => s.$1 == _section).$2,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context)),
              ),
              const SizedBox(height: 12),
              _grid(_cards()),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiStrip({
    required Color brand,
    required int total,
    required double retention,
    required int active,
    required int inactive,
    required int openJobs,
  }) {
    final items = <(String, String, String)>[
      ('Total headcount', '$total', '$active active'),
      ('Monthly retention', '${retention.toStringAsFixed(1)}%', '$inactive inactive'),
      ('Active workforce', '$active', '${total == 0 ? 0 : ((active / total) * 100).toStringAsFixed(0)}% of total'),
      ('Open requisitions', '$openJobs', 'hiring pipeline'),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1100 ? 4 : box.maxWidth >= 700 ? 2 : 1;
        const gap = 12.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: w,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: HrUi.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HrUi.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1, style: TextStyle(color: HrTheme.textSecondary(context), fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(item.$2, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: HrTheme.text(context))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(item.$3, style: TextStyle(color: brand, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
      'growth' => [card('Workforce Growth Over Time', 'growth', AnalyticsChartType.column)],
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

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.brand,
    required this.growth,
    required this.retention,
    required this.range,
    required this.onRange,
  });

  final Color brand;
  final List<Map<String, dynamic>> growth;
  final double retention;
  final String range;
  final ValueChanged<String> onRange;

  @override
  Widget build(BuildContext context) {
    final points = growth
        .map((e) => ((e['count'] as num?) ?? 0).toDouble())
        .toList();
    final sliced = switch (range) {
      '7D' => points.length <= 7 ? points : points.sublist(points.length - 7),
      'QTD' => points,
      _ => points.length <= 12 ? points : points.sublist(points.length - 12),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Workforce trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context)),
                ),
              ),
              for (final r in ['7D', '30D', 'QTD'])
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    label: Text(r, style: const TextStyle(fontSize: 11)),
                    selected: range == r,
                    visualDensity: VisualDensity.compact,
                    selectedColor: brand.withValues(alpha: 0.16),
                    onSelected: (_) => onRange(r),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Headcount growth with retention overlay (${retention.toStringAsFixed(1)}% active).',
            style: TextStyle(color: HrUi.muted(context), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: sliced.isEmpty
                ? Center(child: Text('No growth data yet.', style: TextStyle(color: HrUi.muted(context))))
                : CustomPaint(
                    painter: _DualTrendPainter(
                      headcount: sliced,
                      retention: retention,
                      brand: brand,
                      grid: HrUi.border(context),
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legend(brand, 'Headcount'),
              const SizedBox(width: 14),
              _legend(const Color(0xFF14B8A6), 'Retention level'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _DualTrendPainter extends CustomPainter {
  _DualTrendPainter({
    required this.headcount,
    required this.retention,
    required this.brand,
    required this.grid,
  });

  final List<double> headcount;
  final double retention;
  final Color brand;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (headcount.isEmpty) return;
    final maxY = math.max(1.0, headcount.reduce(math.max));
    const minY = 0.0;
    final dx = headcount.length == 1 ? size.width : size.width / (headcount.length - 1);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Path linePath(List<double> values) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = dx * i;
        final y = size.height - ((values[i] - minY) / (maxY - minY)) * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      return path;
    }

    final headPath = linePath(headcount);
    final fill = Path.from(headPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [brand.withValues(alpha: 0.28), brand.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      headPath,
      Paint()
        ..color = brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    final retentionY = size.height - (retention.clamp(0, 100) / 100) * size.height;
    canvas.drawLine(
      Offset(0, retentionY),
      Offset(size.width, retentionY),
      Paint()
        ..color = const Color(0xFF14B8A6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DualTrendPainter oldDelegate) =>
      oldDelegate.headcount != headcount ||
      oldDelegate.retention != retention ||
      oldDelegate.brand != brand;
}
