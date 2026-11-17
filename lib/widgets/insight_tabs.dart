import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../theme/hr_theme.dart';

/// Dashboard tabs. Same destinations as the reference bar, with our own names.
class InsightTabBar extends StatelessWidget {
  const InsightTabBar({super.key});

  static const tabs = <(String, String, IconData)>[
    ('home', 'My Desk', Icons.home_outlined),
    ('my_info', 'Profile', Icons.person_outline),
    ('hr_dashboard', 'People Analytics', Icons.analytics_outlined),
    ('hr_data', 'Workforce Records', Icons.table_chart_outlined),
    ('wall_of_fame', 'Honors Board', Icons.emoji_events_outlined),
    ('org_chart', 'Team Structure', Icons.account_tree_outlined),
    ('hr_globe', 'Office Map', Icons.public_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.moduleId != 'dashboard') return const SizedBox.shrink();
    final current = app.subId;

    final brand = HrTheme.brand(context);
    final idle = HrTheme.textSecondary(context);
    return Material(
      color: HrTheme.card(context),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: HrTheme.border(context))),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            for (final tab in tabs)
              InkWell(
                onTap: () => app.openScreen(moduleId: 'dashboard', subId: tab.$1),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: current == tab.$1 ? brand : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(tab.$3, size: 16, color: current == tab.$1 ? brand : idle),
                      const SizedBox(width: 6),
                      Text(
                        tab.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: current == tab.$1 ? brand : HrTheme.text(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
