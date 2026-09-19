import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR-style My Dashboard: hero profile, status feed, My Alerts.
class MyDashboardView extends StatefulWidget {
  const MyDashboardView({super.key});

  @override
  State<MyDashboardView> createState() => _MyDashboardViewState();
}

class _MyDashboardViewState extends State<MyDashboardView> {
  final _status = TextEditingController();
  String _alertTab = 'actions';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelfServiceState>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _status.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final auth = context.watch<AuthState>();
    final ss = context.watch<SelfServiceState>();
    final brand = HrTheme.brand(context);
    final isDark = app.isDarkMode;
    final name = auth.user?.name.isNotEmpty == true ? auth.user!.name : 'User';
    final role = auth.user?.designationName.isNotEmpty == true
        ? auth.user!.designationName
        : 'Team Member';
    final now = DateTime.now();
    final time = DateFormat('HH:mm').format(now);
    final date = DateFormat('EEE MMMM d').format(now);
    final unread = ss.unreadNotifications;
    final notifs = ss.inboxNotifications;

    return ColoredBox(
      color: isDark ? AppTheme.darkBg : const Color(0xFFF0EDE8),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Hero
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1428), Color(0xFF4A2C6A), Color(0xFF2D1B4E)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -30,
                    child: Icon(Icons.bolt, size: 180, color: Colors.white.withOpacity(0.06)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: brand,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: brand,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: HrTheme.onBrand(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => app.openScreen(
                                        moduleId: 'dashboard', subId: 'my_info'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.person_outline, size: 16),
                                    label: const Text('My Info'),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: () => app.openScreen(
                                        moduleId: 'dashboard',
                                        subId: 'account_settings'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.settings_outlined, size: 16),
                                    label: const Text('Account Settings'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Clock widget
                        InkWell(
                          onTap: app.toggleClock,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 3),
                              color: Colors.black26,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(time,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    )),
                                Text(date,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  app.isClockedIn
                                      ? 'Clocked in'
                                      : 'Not clocked in',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: app.isClockedIn
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFFCA5A5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth > 960;
              final feed = _FeedCard(controller: _status, brand: brand);
              final alerts = _AlertsCard(
                brand: brand,
                tab: _alertTab,
                onTab: (t) => setState(() => _alertTab = t),
                unread: unread,
                items: notifs,
                onAllApprovals: () =>
                    app.openScreen(moduleId: 'dashboard', subId: 'approvals'),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: feed),
                    const SizedBox(width: 16),
                    SizedBox(width: 340, child: alerts),
                  ],
                );
              }
              return Column(children: [feed, const SizedBox(height: 16), alerts]);
            },
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.controller, required this.brand});
  final TextEditingController controller;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Post Status Updates',
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
              for (final i in [
                Icons.photo_camera_outlined,
                Icons.videocam_outlined,
                Icons.emoji_events_outlined,
                Icons.emoji_emotions_outlined,
                Icons.campaign_outlined,
                Icons.favorite_outline,
              ])
                IconButton(
                  onPressed: () {},
                  icon: Icon(i, size: 20, color: HrUi.muted(context)),
                ),
              const Spacer(),
              FilledButton(
                style: HrTheme.filledButton(context),
                onPressed: () {
                  controller.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Status posted (local)')),
                  );
                },
                child: const Text('Post'),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: brand.withOpacity(0.2),
                child: Icon(Icons.person, color: brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Update',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    Text('Welcome to HR360 — your approvals & leave live here.',
                        style: TextStyle(color: HrUi.muted(context), fontSize: 12)),
                  ],
                ),
              ),
              Text('Just now',
                  style: TextStyle(color: HrUi.muted(context), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.brand,
    required this.tab,
    required this.onTab,
    required this.unread,
    required this.items,
    required this.onAllApprovals,
  });

  final Color brand;
  final String tab;
  final ValueChanged<String> onTab;
  final int unread;
  final List<Map<String, dynamic>> items;
  final VoidCallback onAllApprovals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('My Alerts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HrUi.label(context),
                  )),
              const Spacer(),
              TextButton(
                onPressed: onAllApprovals,
                child: Text('All Approvals >',
                    style: TextStyle(color: brand, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Row(
            children: [
              _pill(context, 'Actions ($unread)', tab == 'actions', () => onTab('actions')),
              const SizedBox(width: 8),
              _pill(context, 'Approvals', tab == 'approvals', () => onTab('approvals')),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('No alerts right now.',
                  style: TextStyle(color: HrUi.muted(context))),
            )
          else
            for (final n in items.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.list_alt, color: brand, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (n['title'] ?? '').toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: HrUi.label(context),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            (n['body'] ?? '').toString(),
                            style: TextStyle(color: HrUi.muted(context), fontSize: 12),
                          ),
                          Text(
                            (n['created_at'] ?? '').toString(),
                            style: TextStyle(
                              color: HrUi.muted(context).withOpacity(0.8),
                              fontSize: 11,
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
    );
  }

  Widget _pill(BuildContext context, String label, bool on, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? brand : HrUi.fieldBg(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: on ? HrTheme.onBrand(context) : HrUi.muted(context),
          ),
        ),
      ),
    );
  }
}
