part of 'my_dashboard_view.dart';

class _WelcomeBar extends StatelessWidget {
  const _WelcomeBar({
    required this.name,
    required this.brand,
    required this.onLeave,
    required this.onApprovals,
    required this.onProfile,
    required this.showPeople,
    required this.onPeople,
  });

  final String name;
  final Color brand;
  final VoidCallback onLeave;
  final VoidCallback onApprovals;
  final VoidCallback onProfile;
  final bool showPeople;
  final VoidCallback onPeople;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          'Welcome back, $name. Here is what needs you today.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: HrTheme.text(context),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (showPeople)
              FilledButton.icon(
                onPressed: onPeople,
                style: FilledButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: HrTheme.onBrand(context),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Add person'),
              ),
            OutlinedButton.icon(
              onPressed: onLeave,
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: const Text('Request leave'),
            ),
            OutlinedButton.icon(
              onPressed: onApprovals,
              icon: const Icon(Icons.inbox_outlined, size: 18),
              label: const Text('Review requests'),
            ),
            OutlinedButton.icon(
              onPressed: onProfile,
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Open profile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({
    required this.brand,
    required this.pendingApprovals,
    required this.unread,
    required this.daysLeft,
    required this.outToday,
    required this.celebrations,
    required this.pendingLeave,
  });

  final Color brand;
  final int pendingApprovals;
  final int unread;
  final int daysLeft;
  final int outToday;
  final int celebrations;
  final int pendingLeave;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.inbox_outlined, '$pendingApprovals', 'Waiting on you'),
      (Icons.notifications_outlined, '$unread', 'Unread notices'),
      (Icons.beach_access_outlined, '$daysLeft', 'Leave days left'),
      (Icons.event_busy_outlined, '$outToday', 'Out today'),
      (Icons.celebration_outlined, '$celebrations', 'Celebrations'),
      (Icons.pending_actions_outlined, '$pendingLeave', 'Leave requests'),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1100 ? 6 : box.maxWidth >= 720 ? 3 : 2;
        const gap = 10.0;
        final width = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _AccentCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: brand.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.$1, size: 18, color: brand),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: HrTheme.text(context),
                                ),
                              ),
                              Text(
                                item.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: HrTheme.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  const _LeaveBalanceCard({
    required this.brand,
    required this.balances,
    required this.onRequest,
  });

  final Color brand;
  final List<LeaveBalanceDto> balances;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final shown = balances.take(3).toList();
    return _AccentCard(
      accent: brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_available_outlined, size: 18, color: brand),
                const SizedBox(width: 8),
                Text(
                  'Leave balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HrUi.label(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No leave balances are assigned yet.',
                  style: TextStyle(color: HrUi.muted(context)),
                ),
              )
            else
              Row(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            shown[i].name,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: HrTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${shown[i].available}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: brand,
                            ),
                          ),
                          Text(
                            'days left',
                            style: TextStyle(
                              fontSize: 11,
                              color: HrTheme.textMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Request leave'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.brand,
    required this.onOpen,
  });

  final Color brand;
  final void Function(String moduleId, String subId) onOpen;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, String, String)>[
      (Icons.flag_outlined, 'Goals', 'Reviews and targets', 'employees', 'performance'),
      (Icons.school_outlined, 'Learning', 'Courses and sessions', 'training_mod', 'training_list'),
      (Icons.receipt_long_outlined, 'Payslips', 'Salary documents', 'payroll', 'salary_payslips'),
      (Icons.emoji_events_outlined, 'Honors', 'Recognition board', 'dashboard', 'wall_of_fame'),
    ];
    return _AccentCard(
      accent: brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.grid_view_outlined, size: 18, color: brand),
                  const SizedBox(width: 8),
                  Text(
                    'My work',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: HrUi.label(context),
                    ),
                  ),
                ],
              ),
            ),
            for (final item in items)
              ListTile(
                dense: true,
                leading: Icon(item.$1, color: brand),
                title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(item.$3),
                onTap: () => onOpen(item.$4, item.$5),
              ),
          ],
        ),
      ),
    );
  }
}

class _WhosOutCard extends StatelessWidget {
  const _WhosOutCard({
    required this.brand,
    required this.people,
    required this.onOpen,
  });

  final Color brand;
  final List<LeaveDto> people;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _AccentCard(
      accent: brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy_outlined, size: 18, color: brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Away today',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: HrUi.label(context),
                    ),
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('Leave calendar')),
              ],
            ),
            const SizedBox(height: 8),
            if (people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Nobody on your team is away today.',
                  style: TextStyle(color: HrUi.muted(context)),
                ),
              )
            else
              for (final person in people.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: brand.withValues(alpha: 0.12),
                        child: Text(
                          person.employeeName.isEmpty
                              ? '?'
                              : person.employeeName[0].toUpperCase(),
                          style: TextStyle(color: brand, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.employeeName.isEmpty ? 'Team member' : person.employeeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${person.leaveType} · ${person.from} – ${person.to}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: HrTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
