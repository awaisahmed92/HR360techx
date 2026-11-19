part of 'my_dashboard_view.dart';

class _PeoplePulseBanner extends StatelessWidget {
  const _PeoplePulseBanner({
    required this.brand,
    required this.insights,
    required this.onAction,
    required this.onInsights,
  });

  final Color brand;
  final List<String> insights;
  final VoidCallback onAction;
  final VoidCallback onInsights;

  @override
  Widget build(BuildContext context) {
    final soft = Color.lerp(brand, Colors.white, 0.86)!;
    final softEdge = Color.lerp(brand, Colors.white, 0.72)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [soft, softEdge],
        ),
        border: Border.all(color: brand.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: LayoutBuilder(
        builder: (context, box) {
          final stack = box.maxWidth < 720;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's people pulse",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HrTheme.heading(context),
                ),
              ),
              const SizedBox(height: 10),
              for (final line in insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: brand, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            height: 1.35,
                            color: HrTheme.text(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: brand,
                ),
                onPressed: onAction,
                child: const Text('Take action'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: brand,
                  foregroundColor: HrTheme.onBrand(context),
                ),
                onPressed: onInsights,
                child: const Text('View insights'),
              ),
            ],
          );
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _WorkforceKpiStrip extends StatelessWidget {
  const _WorkforceKpiStrip({
    required this.brand,
    required this.headcount,
    required this.retention,
    required this.attendance,
    required this.openJobs,
    required this.pendingApprovals,
    required this.outToday,
  });

  final Color brand;
  final int headcount;
  final double retention;
  final double attendance;
  final int openJobs;
  final int pendingApprovals;
  final int outToday;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, String, Color)>[
      ('Total headcount', '$headcount', '+workforce', const Color(0xFF16A34A)),
      ('Active retention', '${retention.toStringAsFixed(1)}%', 'active share', const Color(0xFF16A34A)),
      ('Present today', '${attendance.toStringAsFixed(1)}%', '$outToday away', const Color(0xFF0EA5E9)),
      ('Open jobs', '$openJobs', pendingApprovals > 0 ? '$pendingApprovals approvals' : 'hiring', const Color(0xFF64748B)),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 1100 ? 4 : box.maxWidth >= 700 ? 2 : 1;
        const gap = 12.0;
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
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: TextStyle(color: HrTheme.textSecondary(context), fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: HrTheme.text(context),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.$4.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.$3,
                                style: TextStyle(
                                  color: item.$4,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
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

class _ApprovalQueueCard extends StatelessWidget {
  const _ApprovalQueueCard({
    required this.brand,
    required this.leavePending,
    required this.inbox,
    required this.onOpenAll,
    required this.onApproveLeave,
    required this.onRejectLeave,
  });

  final Color brand;
  final List<LeaveDto> leavePending;
  final List<Map<String, dynamic>> inbox;
  final VoidCallback onOpenAll;
  final Future<void> Function(int id) onApproveLeave;
  final Future<void> Function(int id) onRejectLeave;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final leave in leavePending.take(4)) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: brand.withValues(alpha: 0.12),
                child: Text(
                  leave.employeeName.isEmpty ? '?' : leave.employeeName[0].toUpperCase(),
                  style: TextStyle(color: brand, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.employeeName.isEmpty ? 'Team member' : leave.employeeName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${leave.leaveType} · ${leave.from} – ${leave.to}',
                      style: TextStyle(fontSize: 12, color: HrTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onApproveLeave(leave.id),
                child: Text('Approve', style: TextStyle(color: brand, fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => onRejectLeave(leave.id),
                child: const Text('Decline', style: TextStyle(color: Color(0xFFDC2626))),
              ),
            ],
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      for (final item in inbox.take(4)) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: brand.withValues(alpha: 0.12),
                child: Icon(Icons.inbox_outlined, color: brand, size: 18),
              ),
              title: Text('${item['title'] ?? item['module'] ?? 'Request'}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${item['employee_name'] ?? ''} · ${item['summary'] ?? ''}'),
            ),
          ),
        );
      }
    }

    return _AccentCard(
      accent: brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, size: 18, color: brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Approval queue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context)),
                  ),
                ),
                TextButton(onPressed: onOpenAll, child: const Text('View all')),
              ],
            ),
            const SizedBox(height: 6),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Nothing waiting for approval.', style: TextStyle(color: HrUi.muted(context))),
              )
            else
              ...rows,
          ],
        ),
      ),
    );
  }
}

class _PeopleSnapshotCard extends StatelessWidget {
  const _PeopleSnapshotCard({
    required this.brand,
    required this.people,
    required this.onOpen,
  });

  final Color brand;
  final List<Map<String, dynamic>> people;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = people.take(6).toList();
    return _AccentCard(
      accent: brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.groups_outlined, size: 18, color: brand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'People snapshot',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: HrUi.label(context)),
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('Open directory')),
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No people loaded yet.', style: TextStyle(color: HrUi.muted(context))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 52,
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final p in rows)
                      DataRow(
                        cells: [
                          DataCell(Text('${p['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700))),
                          DataCell(Text('${p['designation_name'] ?? p['job_title'] ?? '—'}')),
                          DataCell(Text('${p['department_name'] ?? '—'}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ((p['status'] as num?)?.toInt() ?? 1) > 0
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ((p['status'] as num?)?.toInt() ?? 1) > 0 ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ((p['status'] as num?)?.toInt() ?? 1) > 0
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ),
                        ],
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
