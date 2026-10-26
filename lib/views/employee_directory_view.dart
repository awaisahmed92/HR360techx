import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';
import '../widgets/hr_grid_query.dart';
import '../widgets/person_photo.dart';

/// Searchable employee directory cards (HR360tech-style).
class EmployeeDirectoryView extends StatefulWidget {
  const EmployeeDirectoryView({super.key});

  @override
  State<EmployeeDirectoryView> createState() => _EmployeeDirectoryViewState();
}

class _EmployeeDirectoryViewState extends State<EmployeeDirectoryView> {
  late final EmployeeState _state;
  String _query = '';
  int _page = 1;
  int _perPage = 20;

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
        if (_state.busy && _state.rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final query = hrSearchQuery(context, _query);
        final filtered = _state.rows.where((r) {
          final blob =
              '${r['name']} ${r['job_title']} ${r['department_name']} ${r['email']} ${r['user_name']} ${r['employee_code']} ${r['station_name']}';
          return hrMatchesQuery(blob, query);
        }).toList();
        final pages = filtered.isEmpty ? 1 : (filtered.length / _perPage).ceil();
        final page = _page.clamp(1, pages);
        final start = (page - 1) * _perPage;
        final end = (start + _perPage) > filtered.length ? filtered.length : start + _perPage;
        final pageRows = filtered.isEmpty ? filtered : filtered.sublist(start, end);

        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 20, color: HrUi.label(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Employee Directory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      ),
                    ),
                  ),
                  HrSearchField(
                    width: 260,
                    hint: 'Search employees',
                    value: query,
                    onChanged: (v) => setState(() {
                      _query = v;
                      _page = 1;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              hrQueryBanner(context, query, filtered.length, onClear: () => setState(() {
                _query = '';
                _page = 1;
              })),
              Text(
                '${filtered.length} people',
                style: TextStyle(color: HrUi.muted(context), fontSize: 12),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('No employees found.', style: TextStyle(color: HrUi.muted(context))),
                  ),
                )
              else
                Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 1200
                            ? 4
                            : c.maxWidth >= 880
                                ? 3
                                : c.maxWidth >= 560
                                    ? 2
                                    : 1;
                        final gap = 12.0;
                        final w = (c.maxWidth - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final row in pageRows)
                              SizedBox(width: w, child: _DirectoryCard(row: row, highlighted: query.isNotEmpty)),
                          ],
                        );
                      },
                    ),
                    _directoryPager(context, start, end, filtered.length, page, pages),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _directoryPager(BuildContext context, int start, int end, int total, int page, int pages) {
    const sizes = [10, 20, 50, 100];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text('${start + 1}–$end of $total', style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
          const SizedBox(width: 12),
          Text('Rows', style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
          const SizedBox(width: 6),
          DropdownButton<int>(
            value: _perPage,
            items: [for (final size in sizes) DropdownMenuItem(value: size, child: Text('$size'))],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _perPage = value;
                _page = 1;
              });
            },
          ),
          const Spacer(),
          IconButton(
            onPressed: page > 1 ? () => setState(() => _page = page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page / $pages', style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
          IconButton(
            onPressed: page < pages ? () => setState(() => _page = page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.row, this.highlighted = false});
  final Map<String, dynamic> row;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);
    final name = '${row['name'] ?? ''}';
    final title = '${row['job_title'] ?? ''}';
    final dept = '${row['department_name'] ?? ''}';
    final email = '${row['email'] ?? ''}';
    final status = (row['status'] as num?)?.toInt() ?? 0;
    final statusLabel = status == 2 ? 'Admin' : status > 0 ? 'Active' : 'Inactive';
    final statusColor = status == 2
        ? const Color(0xFF7C3AED)
        : status > 0
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? const Color(0xFFF5D36A) : HrUi.border(context),
          width: highlighted ? 2 : 1,
        ),
        color: highlighted ? hrMatchRowColor : HrUi.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          PersonPhoto(
            path: row['profile_picture']?.toString(),
            employeeId: (row['employee_id'] as num?)?.toInt(),
            size: 72,
          ),
          const SizedBox(height: 10),
          Text(
            name.isEmpty ? 'Employee' : name,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: HrUi.label(context)),
          ),
          if (title.isNotEmpty)
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: HrUi.muted(context))),
          if (dept.isNotEmpty)
            Text(dept, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: HrUi.muted(context))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(email, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: brand)),
          ],
        ],
      ),
    );
  }

}
