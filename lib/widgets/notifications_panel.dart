import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/self_service/self_service_state.dart';
import '../core/util/person_name.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import 'hr_form_kit.dart';

/// Bell dropdown: Read Alerts · Approvals · Post status / holiday.
class NotificationsBellButton extends StatelessWidget {
  const NotificationsBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final brand = HrTheme.brand(context);
    final ss = context.watch<SelfServiceState>();
    final app = context.watch<AppState>();
    final useLive = !context.watch<AuthState>().isDemo;
    final unread = useLive ? ss.unreadNotifications : app.unreadNotificationsCount;
    final badge = unread + ss.approvals.length + app.statusFeed.where((p) {
      final t = (p['type'] ?? '').toString();
      return t == 'holiday' || t == 'announcement';
    }).length;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        if (useLive) {
          ss.loadNotifications();
          ss.loadApprovals();
        }
        await showDialog<void>(
          context: context,
          barrierColor: Colors.black26,
          builder: (ctx) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  top: 56,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: _NotificationsPanel(
                      onClose: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCardHover,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 20, color: textPrimary),
            if (badge > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            // Always show a tiny badge like WebHR when zero (optional) — only when >0 above.
            if (badge == 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: brand.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '0',
                    style: TextStyle(
                      color: brand,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsPanel extends StatefulWidget {
  const _NotificationsPanel({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  String _tab = 'alerts'; // alerts | approvals | post
  final _postCtrl = TextEditingController();
  String _postType = 'status';

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  String _relative(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} mins ago';
    if (d.inHours < 24) return '${d.inHours} hours ago';
    if (d.inDays < 7) return '${d.inDays} days ago';
    if (d.inDays < 30) {
      final w = (d.inDays / 7).floor();
      return w > 0 ? '$w weeks ago' : '${d.inDays} days ago';
    }
    final m = (d.inDays / 30).floor();
    final w = ((d.inDays % 30) / 7).floor();
    if (m >= 1 && w > 0) return '$m month${m > 1 ? 's' : ''}, $w weeks ago';
    return '$m month${m > 1 ? 's' : ''} ago';
  }

  String _alertLine(Map<String, dynamic> n) {
    final title = (n['title'] ?? '').toString().trim();
    final body = (n['body'] ?? n['desc'] ?? '').toString().trim();
    final lower = title.toLowerCase();
    if (lower.contains('acknowledgement') ||
        lower.startsWith('approved:') ||
        lower.startsWith('rejected:') ||
        lower.startsWith('submitted:')) {
      return title;
    }
    if (body.toLowerCase().contains('acknowledgement')) return body;
    // Leave / module outcome phrasing
    if (lower.contains('approved') && body.isNotEmpty) return title;
    if (title.isNotEmpty) return title;
    return body.isNotEmpty ? body : 'Alert';
  }

  String _moduleLabel(String raw) {
    final m = raw.trim().toLowerCase();
    return switch (m) {
      'leave' || 'leaves' => 'Leaves',
      'travel' => 'Travel',
      'timesheet' => 'Timesheet',
      'resignation' || 'resignations' => 'Resignations',
      'termination' || 'terminations' => 'Termination',
      'loan' || 'loan_application' || 'loan applications' => 'Loan Applications',
      'employment_change' || 'employment change' => 'Employment Change',
      _ => raw.isEmpty
          ? 'Request'
          : raw[0].toUpperCase() + raw.substring(1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final card = isDark ? AppTheme.darkCard : Colors.white;
    final brand = HrTheme.brand(context);
    final ss = context.watch<SelfServiceState>();
    final app = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final useLive = !auth.isDemo;
    final author = cleanDisplayName(auth.user?.name).isEmpty
        ? 'User'
        : cleanDisplayName(auth.user!.name);

    final liveItems = useLive
        ? ss.inboxNotifications
        : app.notifications
            .map((n) => {
                  'id': n['id'],
                  'title': n['title'],
                  'body': n['desc'],
                  'created_at': n['time'],
                  'is_read': n['read'] == true,
                  'actor_name': n['from'] ?? '',
                })
            .toList();

    final approvals = ss.approvals;

    // Pending module approvals also appear under Read Alerts (WebHR style).
    final approvalAlerts = approvals.map((a) {
      final module = _moduleLabel(
        (a['module'] ?? a['kind'] ?? a['type'] ?? 'Request').toString(),
      );
      final who = (a['employee_name'] ?? '').toString();
      final detail = [
        if (who.isNotEmpty) who,
        (a['title'] ?? '').toString(),
        (a['summary'] ?? '').toString(),
      ].where((s) => s.trim().isNotEmpty).join(' · ');
      return {
        'title': 'Your acknowledgement is required for: ($module)',
        'body': detail,
        'created_at': (a['created_at'] ?? '').toString(),
        'is_read': false,
        'actor_name': who,
        'kind': 'approval_inbox',
        'module': module,
      };
    }).toList();

    // Holiday / announcement posts also surface as alerts.
    final feedAlerts = app.statusFeed
        .where((p) {
          final t = (p['type'] ?? '').toString();
          return t == 'holiday' || t == 'announcement';
        })
        .map((p) => {
              'title': p['type'] == 'holiday'
                  ? 'Holiday notification'
                  : 'Announcement',
              'body': (p['text'] ?? '').toString(),
              'created_at': (p['created_at'] ?? '').toString(),
              'is_read': false,
              'actor_name': (p['author'] ?? '').toString(),
              'kind': 'feed',
            })
        .toList();

    final alerts = [...approvalAlerts, ...feedAlerts, ...liveItems];

    return Container(
      width: 380,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon: Icon(Icons.close, size: 18, color: textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _tabChip('Read Alerts', 'alerts', alerts.length),
                const SizedBox(width: 6),
                _tabChip('Approvals', 'approvals', approvals.length),
                const SizedBox(width: 6),
                _tabChip('Post', 'post', 0, showBadge: false),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: border),
          Flexible(
            child: switch (_tab) {
              'approvals' => _listPane(
                  empty: 'No pending approval alerts.',
                  children: [
                    for (final a in approvals.take(12))
                      _row(
                        context,
                        avatarLetter: () {
                          final who = (a['employee_name'] ?? '').toString();
                          return who.isNotEmpty ? who[0].toUpperCase() : 'A';
                        }(),
                        title: 'Your acknowledgement is required for: (${_moduleLabel((a['module'] ?? a['kind'] ?? 'Request').toString())})',
                        subtitle: [
                          (a['employee_name'] ?? '').toString(),
                          (a['title'] ?? '').toString(),
                          (a['summary'] ?? '').toString(),
                        ].where((s) => s.trim().isNotEmpty).join(' · '),
                        time: _relative(
                            (a['created_at'] ?? a['submitted_at'] ?? '').toString()),
                        unread: true,
                        onTap: () {
                          widget.onClose();
                          app.openScreen(moduleId: 'dashboard', subId: 'approvals');
                        },
                      ),
                  ],
                ),
              'post' => _postPane(context, author: author, brand: brand),
              _ => _listPane(
                  empty: 'No alerts',
                  children: [
                    for (final n in alerts.take(20))
                      _row(
                        context,
                        avatarLetter: () {
                          final who = (n['actor_name'] ?? '').toString();
                          return who.isNotEmpty ? who[0].toUpperCase() : 'A';
                        }(),
                        title: _alertLine(n),
                        subtitle: () {
                          final body = (n['body'] ?? '').toString().trim();
                          final title = _alertLine(n);
                          if (body.isEmpty || body == title) return null;
                          if (title.toLowerCase().contains('acknowledgement')) {
                            return body;
                          }
                          return null;
                        }(),
                        time: _relative((n['created_at'] ?? '').toString()),
                        unread: n['is_read'] != true,
                        onTap: () {
                          final id = (n['id'] as num?)?.toInt();
                          if (useLive &&
                              n['kind'] != 'feed' &&
                              n['kind'] != 'approval_inbox') {
                            ss.markNotificationsRead(id: id);
                          }
                          widget.onClose();
                          app.openScreen(moduleId: 'dashboard', subId: 'approvals');
                        },
                      ),
                  ],
                ),
            },
          ),
          if (_tab != 'post')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  if (useLive) {
                    ss.markNotificationsRead();
                  } else {
                    app.markAllNotificationsRead();
                  }
                },
                child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, String id, int count, {bool showBadge = true}) {
    final on = _tab == id;
    final brand = HrTheme.brand(context);
    return InkWell(
      onTap: () => setState(() => _tab = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE8E4DF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? const Color(0xFF333333) : HrUi.muted(context),
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: on ? const Color(0xFF8B6B4A) : brand.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: on ? Colors.white : brand,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _listPane({required String empty, required List<Widget> children}) {
    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(empty, style: TextStyle(color: HrUi.muted(context))),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      shrinkWrap: true,
      children: children,
    );
  }

  Widget _row(
    BuildContext context, {
    required String avatarLetter,
    required String title,
    String? subtitle,
    required String time,
    required bool unread,
    required VoidCallback onTap,
  }) {
    final textPrimary = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: HrTheme.brandSoft(context),
              child: Text(
                avatarLetter,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: HrTheme.brand(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          time,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE11D48),
                            shape: BoxShape.circle,
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

  Widget _postPane(BuildContext context, {required String author, required Color brand}) {
    final auth = context.watch<AuthState>();
    final canBroadcast = auth.user?.isAdmin == true || auth.permissions.all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            canBroadcast
                ? 'Post a status, holiday or announcement'
                : 'Post a status update',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: HrUi.label(context),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _postCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _postType == 'holiday'
                  ? 'e.g. Office closed Friday for Eid…'
                  : _postType == 'announcement'
                      ? 'e.g. All-hands meeting at 3pm…'
                      : 'What is on your mind?',
              filled: true,
              fillColor: HrUi.fieldBg(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _typeBtn('status', Icons.chat_bubble_outline, 'Status'),
              if (canBroadcast) ...[
                _typeBtn('holiday', Icons.celebration_outlined, 'Holiday'),
                _typeBtn('announcement', Icons.campaign_outlined, 'Announce'),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: HrTheme.filledButton(context),
            onPressed: () async {
              final text = _postCtrl.text.trim();
              if (text.isEmpty) return;
              await context.read<AppState>().postStatus(
                    author: author,
                    text: text,
                    type: canBroadcast ? _postType : 'status',
                  );
              _postCtrl.clear();
              if (!mounted) return;
              setState(() => _tab = 'alerts');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _postType == 'holiday'
                        ? 'Holiday notification posted'
                        : _postType == 'announcement'
                            ? 'Announcement posted'
                            : 'Status posted',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Post notification'),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String id, IconData icon, String tip) {
    final on = _postType == id;
    final brand = HrTheme.brand(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: tip,
        onPressed: () => setState(() => _postType = id),
        icon: Icon(icon, size: 20, color: on ? brand : HrUi.muted(context)),
      ),
    );
  }
}
