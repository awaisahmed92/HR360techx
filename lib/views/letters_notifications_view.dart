import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/self_service/self_service_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// Full-page notifications inbox (API-backed).
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ss = context.watch<SelfServiceState>();
    final items = ss.inboxNotifications;

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HrUi.label(context),
                    )),
                const SizedBox(width: 10),
                if (ss.unreadNotifications > 0)
                  Chip(
                    label: Text('${ss.unreadNotifications} unread'),
                    backgroundColor: HrTheme.brandSoft(context),
                    labelStyle: TextStyle(color: HrTheme.brand(context), fontWeight: FontWeight.w700),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => ss.markNotificationsRead(),
                  child: const Text('Mark all read'),
                ),
                IconButton(
                  onPressed: () => ss.loadNotifications(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(child: Text('No notifications.', style: TextStyle(color: HrUi.muted(context))))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final unread = n['read'] != true && n['is_read'] != true && n['read_at'] == null;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: unread
                              ? HrTheme.brand(context).withValues(alpha: 0.15)
                              : HrUi.border(context),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: unread ? HrTheme.brand(context) : HrUi.muted(context),
                          ),
                        ),
                        title: Text(
                          '${n['title'] ?? n['message'] ?? n['body'] ?? 'Notification'}',
                          style: TextStyle(
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${n['body'] ?? n['message'] ?? ''}\n${n['created_at'] ?? n['date'] ?? ''}',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          final id = (n['id'] as num?)?.toInt();
                          ss.markNotificationsRead(id: id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
