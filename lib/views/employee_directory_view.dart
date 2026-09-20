import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/employees/employee_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Searchable employee directory cards (WebHR-style).
class EmployeeDirectoryView extends StatefulWidget {
  const EmployeeDirectoryView({super.key});

  @override
  State<EmployeeDirectoryView> createState() => _EmployeeDirectoryViewState();
}

class _EmployeeDirectoryViewState extends State<EmployeeDirectoryView> {
  late final EmployeeState _state;
  String _query = '';

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
        final filtered = _state.rows.where((r) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return '${r['name']}|${r['job_title']}|${r['department_name']}|${r['email']}|${r['user_name']}'
              .toLowerCase()
              .contains(q);
        }).toList();

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
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search employees',
                        hintStyle: TextStyle(fontSize: 13, color: HrUi.muted(context)),
                        suffixIcon: Icon(Icons.search, size: 18, color: HrUi.muted(context)),
                        filled: true,
                        fillColor: HrUi.card(context),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: HrUi.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: HrUi.border(context)),
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                        for (final row in filtered)
                          SizedBox(width: w, child: _DirectoryCard(row: row)),
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

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.row});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);
    final name = '${row['name'] ?? ''}';
    final title = '${row['job_title'] ?? ''}';
    final dept = '${row['department_name'] ?? ''}';
    final email = '${row['email'] ?? ''}';
    final photo = AppConfig.resolveMediaUrl(row['profile_picture']?.toString());
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
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: brand.withValues(alpha: 0.14),
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty
                ? Text(
                    _initials(name),
                    style: TextStyle(fontWeight: FontWeight.w800, color: brand, fontSize: 18),
                  )
                : null,
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
