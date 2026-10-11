import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';

/// Major User Insights tabs: Home, My Info, HR Dashboard, HR Data, Org Chart.
class InsightTabBar extends StatelessWidget {
  const InsightTabBar({super.key});

  static const tabs = <(String, String, IconData)>[
    ('home', 'Home', Icons.home_outlined),
    ('my_info', 'My Info', Icons.person_outline),
    ('hr_dashboard', 'HR Dashboard', Icons.analytics_outlined),
    ('hr_data', 'HR Data', Icons.table_chart_outlined),
    ('wall_of_fame', 'Wall Of Fame', Icons.emoji_events_outlined),
    ('org_chart', 'Org Chart', Icons.account_tree_outlined),
    ('hr_globe', 'HR Globe', Icons.public_outlined),
    ('play_space', 'Play Space', Icons.sports_esports_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.moduleId != 'dashboard') return const SizedBox.shrink();
    final current = app.subId;

    return Material(
      color: Colors.white,
      child: Container(
        height: 44,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE6E8EE))),
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
                        color: current == tab.$1 ? const Color(0xFF8D6E63) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(tab.$3, size: 16, color: current == tab.$1 ? const Color(0xFF8D6E63) : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        tab.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: current == tab.$1 ? const Color(0xFF8D6E63) : const Color(0xFF4B5563),
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
