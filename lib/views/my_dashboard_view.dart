import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import '../core/auth/auth_state.dart';
import '../core/config/profile_backgrounds.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/dashboard_clock_face.dart';
import '../widgets/hr_form_kit.dart';

/// WebHR-style My Dashboard: hero profile, status feed, My Alerts, celebrations.
class MyDashboardView extends StatefulWidget {
  const MyDashboardView({super.key});

  @override
  State<MyDashboardView> createState() => _MyDashboardViewState();
}

class _MyDashboardViewState extends State<MyDashboardView> {
  final _status = TextEditingController();
  String _alertTab = 'actions';
  String _celebScope = 'today';
  String _celebTab = 'birthdays';
  late final ImageProvider _bannerImage;
  String _postType = 'status';
  Timer? _feedPoll;

  @override
  void initState() {
    super.initState();
    _bannerImage = ProfileBackgrounds.randomImage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ss = context.read<SelfServiceState>();
      ss.loadNotifications();
      ss.loadApprovals();
      context.read<AppState>().loadStatusFeed();
    });
    _feedPoll = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!mounted) return;
      context.read<AppState>().loadStatusFeed();
    });
  }

  @override
  void dispose() {
    _feedPoll?.cancel();
    _status.dispose();
    super.dispose();
  }

  String _relative(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} mins ago';
    if (d.inHours < 24) return '${d.inHours} hours ago';
    if (d.inDays < 7) return '${d.inDays} days ago';
    if (d.inDays < 30) return '${(d.inDays / 7).floor()} weeks ago';
    final months = (d.inDays / 30).floor();
    final weeks = ((d.inDays % 30) / 7).floor();
    if (months >= 1) {
      return weeks > 0
          ? '$months month${months > 1 ? 's' : ''}, $weeks weeks ago'
          : '$months month${months > 1 ? 's' : ''} ago';
    }
    return DateFormat('d MMM yyyy').format(dt);
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
    final notifs = ss.inboxNotifications;
    final approvals = ss.approvals;
    final actionCount = notifs.where((n) => n['is_read'] != true).length;
    final approvalCount = approvals.length;

    final canBroadcast =
        auth.user?.isAdmin == true || auth.permissions.all;

    final feed = _FeedCard(
      controller: _status,
      brand: brand,
      postType: _postType,
      onType: (t) => setState(() => _postType = t),
      canBroadcast: canBroadcast,
      author: name,
      authorTitle: role,
      posts: app.statusFeed,
      relative: _relative,
      onLike: (id) => app.toggleFeedLike(postId: id, userName: name),
      onComment: (id, text) =>
          app.addFeedComment(postId: id, author: name, text: text),
    );
    final alerts = _AlertsCard(
      brand: brand,
      tab: _alertTab,
      onTab: (t) => setState(() => _alertTab = t),
      actionCount: actionCount,
      approvalCount: approvalCount,
      notifications: notifs,
      approvals: approvals,
      relative: _relative,
      onAllApprovals: () =>
          app.openScreen(moduleId: 'dashboard', subId: 'approvals'),
    );
    final celebrations = _CelebrationsCard(
      brand: brand,
      scope: _celebScope,
      tab: _celebTab,
      onScope: (s) => setState(() => _celebScope = s),
      onTab: (t) => setState(() => _celebTab = t),
      birthdays: _celebScope == 'today'
          ? app.birthdaysToday
          : app.upcomingBirthdays,
      anniversaries: _celebScope == 'today'
          ? app.anniversariesToday
          : app.upcomingAnniversaries,
    );

    return ColoredBox(
      color: isDark ? AppTheme.darkBg : const Color(0xFFF0EDE8),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _HeroBanner(
            bannerImage: _bannerImage,
            brand: brand,
            name: name,
            role: role,
            app: app,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              if (!wide) {
                return Column(
                  children: [
                    feed,
                    const SizedBox(height: 16),
                    alerts,
                    const SizedBox(height: 16),
                    celebrations,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: feed),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        alerts,
                        const SizedBox(height: 16),
                        celebrations,
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.bannerImage,
    required this.brand,
    required this.name,
    required this.role,
    required this.app,
  });

  final ImageProvider bannerImage;
  final Color brand;
  final String name;
  final String role;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: bannerImage,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Image.asset(
                ProfileBackgrounds.assetPath('Profile922.png'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF1A1A1E),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xB3000000),
                    Color(0x66000000),
                    Color(0x99000000),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
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
                  DashboardClockFace(
                    face: app.selectedClockFace,
                    clockType: app.orgSettings.clockType,
                    country: app.selectedClockCountry,
                    timeFormat: app.orgSettings.timeFormat,
                    isClockedIn: app.isClockedIn,
                    onTap: app.toggleClock,
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

/// Rounded card with a colored top strip. Flutter forbids borderRadius on
/// borders whose sides have different colors — this avoids that paint crash.
class _AccentCard extends StatelessWidget {
  const _AccentCard({
    required this.child,
    this.accent,
  });

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accent != null) ColoredBox(color: accent!, child: const SizedBox(height: 3)),
          child,
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.controller,
    required this.brand,
    required this.postType,
    required this.onType,
    this.canBroadcast = false,
    required this.author,
    required this.authorTitle,
    required this.posts,
    required this.relative,
    required this.onLike,
    required this.onComment,
  });

  final TextEditingController controller;
  final Color brand;
  final String postType;
  final ValueChanged<String> onType;
  final bool canBroadcast;
  final String author;
  final String authorTitle;
  final List<Map<String, dynamic>> posts;
  final String Function(String?) relative;
  final ValueChanged<String> onLike;
  final void Function(String postId, String text) onComment;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    IconData typeIcon(String t) {
      switch (t) {
        case 'holiday':
          return Icons.celebration_outlined;
        case 'announcement':
          return Icons.campaign_outlined;
        case 'recognition':
          return Icons.emoji_events_outlined;
        default:
          return Icons.chat_bubble_outline;
      }
    }

    return _AccentCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: postType == 'holiday'
                    ? 'Post a holiday / celebration notice…'
                    : postType == 'announcement'
                        ? 'Post an announcement…'
                        : postType == 'recognition'
                            ? 'Recognize a teammate…'
                            : 'Post Status Updates',
                hintStyle: TextStyle(color: HrUi.muted(context), fontSize: 14),
                filled: true,
                fillColor: HrUi.card(context),
                contentPadding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _attachIcon(context, Icons.photo_camera_outlined, 'Photo'),
                      _attachIcon(context, Icons.videocam_outlined, 'Video'),
                      _attachIcon(context, Icons.link, 'Link'),
                      _attachIcon(context, Icons.attach_file, 'Attachment'),
                      _typeChip(context, 'status', Icons.chat_bubble_outline, 'Status'),
                      if (canBroadcast) ...[
                        _typeChip(context, 'holiday', Icons.celebration_outlined, 'Holiday'),
                        _typeChip(context, 'announcement', Icons.campaign_outlined, 'Announce'),
                        _typeChip(context, 'recognition', Icons.emoji_events_outlined, 'Recognition'),
                      ],
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD6C7A8),
                    foregroundColor: const Color(0xFF3F3A32),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    final text = controller.text;
                    await app.postStatus(
                      author: author,
                      text: text,
                      type: canBroadcast ? postType : 'status',
                      authorTitle: authorTitle,
                    );
                    controller.clear();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          postType == 'holiday'
                              ? 'Holiday notification posted'
                              : postType == 'announcement'
                                  ? 'Announcement posted'
                                  : postType == 'recognition'
                                      ? 'Recognition posted'
                                      : 'Status posted',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
            const Divider(height: 24),
            if (posts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No status updates yet. Share an update, holiday, or recognition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: HrUi.muted(context), fontSize: 13),
                ),
              )
            else
              for (final p in posts.take(12))
                _FeedPostTile(
                  post: p,
                  brand: brand,
                  author: author,
                  typeIcon: typeIcon((p['type'] ?? 'status').toString()),
                  relative: relative,
                  onLike: onLike,
                  onComment: onComment,
                ),
          ],
        ),
      ),
    );
  }

  Widget _attachIcon(BuildContext context, IconData icon, String tip) {
    return IconButton(
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tip attachment — add details in your post text'),
            backgroundColor: brand,
          ),
        );
      },
      icon: Icon(icon, size: 20, color: HrUi.muted(context)),
    );
  }

  Widget _typeChip(BuildContext context, String id, IconData icon, String tip) {
    final on = postType == id;
    return IconButton(
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: () => onType(id),
      icon: Icon(icon, size: 20, color: on ? brand : HrUi.muted(context)),
    );
  }
}

class _FeedPostTile extends StatelessWidget {
  const _FeedPostTile({
    required this.post,
    required this.brand,
    required this.author,
    required this.typeIcon,
    required this.relative,
    required this.onLike,
    required this.onComment,
  });

  final Map<String, dynamic> post;
  final Color brand;
  final String author;
  final IconData typeIcon;
  final String Function(String?) relative;
  final ValueChanged<String> onLike;
  final void Function(String postId, String text) onComment;

  String get _who => (post['author'] ?? 'User').toString();
  String get _type => (post['type'] ?? 'status').toString();
  String get _text => (post['text'] ?? '').toString();

  String get _subtitle {
    final title = (post['author_title'] ?? '').toString().trim();
    final dept = (post['author_department'] ?? '').toString().trim();
    if (title.isNotEmpty && dept.isNotEmpty) return '$title, $dept';
    if (title.isNotEmpty) return title;
    if (dept.isNotEmpty) return dept;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_type == 'recognition') {
      return _RecognitionBlock(
        post: post,
        brand: brand,
        author: author,
        relative: relative,
        onLike: onLike,
        onComment: onComment,
      );
    }

    final id = '${post['id']}';
    final likes = List<String>.from((post['likes'] as List?) ?? []);
    final comments = List<Map<String, dynamic>>.from(
      ((post['comments'] as List?) ?? []).whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ),
    );
    final liked = likes.contains(author);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: brand.withValues(alpha: 0.16),
                child: Text(
                  _who.isNotEmpty ? _who[0].toUpperCase() : 'U',
                  style: TextStyle(color: brand, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _who,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      ),
                    ),
                    if (_subtitle.isNotEmpty)
                      Text(
                        _subtitle,
                        style: TextStyle(color: HrUi.muted(context), fontSize: 12),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      _text,
                      style: TextStyle(color: HrUi.label(context), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin_outlined, size: 15, color: HrUi.muted(context)),
                      const SizedBox(width: 8),
                      Icon(Icons.close, size: 15, color: HrUi.muted(context)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    relative(post['created_at']?.toString()),
                    style: TextStyle(color: HrUi.muted(context), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => onLike(id),
                style: TextButton.styleFrom(
                  foregroundColor: liked ? brand : HrUi.muted(context),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                ),
                label: Text(likes.isEmpty ? 'Like' : 'Like (${likes.length})'),
              ),
              TextButton.icon(
                onPressed: () => _openFeedCommentSheet(
                  context,
                  postId: id,
                  comments: comments,
                  onComment: onComment,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: HrUi.muted(context),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(
                  comments.isEmpty
                      ? 'Comments'
                      : 'Comments (${comments.length})',
                ),
              ),
            ],
          ),
          if (comments.isNotEmpty) ...[
            for (final c in comments.take(3))
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 4),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${c['author'] ?? 'User'}: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: HrUi.label(context),
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: '${c['text'] ?? ''}',
                        style: TextStyle(
                          color: HrUi.muted(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

}

Future<void> _openFeedCommentSheet(
  BuildContext context, {
  required String postId,
  required List<Map<String, dynamic>> comments,
  required void Function(String postId, String text) onComment,
}) async {
  final ctrl = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: HrUi.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Comments',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: HrUi.label(ctx),
              ),
            ),
            const SizedBox(height: 12),
            if (comments.isEmpty)
              Text('No comments yet — be the first.',
                  style: TextStyle(color: HrUi.muted(ctx)))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in comments)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${c['author'] ?? 'User'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${c['text'] ?? ''}'),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      filled: true,
                      fillColor: HrUi.fieldBg(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: HrTheme.filledButton(ctx),
                  onPressed: () {
                    onComment(postId, ctrl.text);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  ctrl.dispose();
}

class _RecognitionBlock extends StatelessWidget {
  const _RecognitionBlock({
    required this.post,
    required this.brand,
    required this.author,
    required this.relative,
    required this.onLike,
    required this.onComment,
  });

  final Map<String, dynamic> post;
  final Color brand;
  final String author;
  final String Function(String?) relative;
  final ValueChanged<String> onLike;
  final void Function(String postId, String text) onComment;

  @override
  Widget build(BuildContext context) {
    final who = (post['author'] ?? 'Team member').toString();
    final raw = (post['text'] ?? '').toString().trim();
    final headline = raw.toLowerCase().contains('recognized')
        ? raw
        : '$who is Recognized';
    final id = '${post['id']}';
    final likes = List<String>.from((post['likes'] as List?) ?? []);
    final comments = List<Map<String, dynamic>>.from(
      ((post['comments'] as List?) ?? []).whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 36,
            backgroundColor: brand.withValues(alpha: 0.16),
            child: Text(
              who.isNotEmpty ? who[0].toUpperCase() : 'U',
              style: TextStyle(
                color: brand,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: HrUi.label(context),
            ),
          ),
          const SizedBox(height: 8),
          Icon(Icons.workspace_premium, size: 36, color: const Color(0xFFC9A227).withValues(alpha: 0.9)),
          const SizedBox(height: 4),
          Text(
            relative(post['created_at']?.toString()),
            style: TextStyle(color: HrUi.muted(context), fontSize: 11),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => onLike(id),
                style: TextButton.styleFrom(
                  foregroundColor: likes.contains(author) ? brand : HrUi.muted(context),
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  likes.contains(author) ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                ),
                label: Text(likes.isEmpty ? 'Like' : 'Like (${likes.length})'),
              ),
              TextButton.icon(
                onPressed: () => _openFeedCommentSheet(
                  context,
                  postId: id,
                  comments: comments,
                  onComment: onComment,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: HrUi.muted(context),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(
                  comments.isEmpty ? 'Comments' : 'Comments (${comments.length})',
                ),
              ),
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
    required this.actionCount,
    required this.approvalCount,
    required this.notifications,
    required this.approvals,
    required this.relative,
    required this.onAllApprovals,
  });

  final Color brand;
  final String tab;
  final ValueChanged<String> onTab;
  final int actionCount;
  final int approvalCount;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> approvals;
  final String Function(String?) relative;
  final VoidCallback onAllApprovals;

  static const _badge = Color(0xFF8B6B4A);

  @override
  Widget build(BuildContext context) {
    return _AccentCard(
      accent: const Color(0xFFC45C4A),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),
            Row(
              children: [
                _seg(context, 'Actions', actionCount, tab == 'actions', () => onTab('actions')),
                const SizedBox(width: 8),
                _seg(context, 'Approvals', approvalCount, tab == 'approvals', () => onTab('approvals')),
              ],
            ),
            const SizedBox(height: 14),
            if (tab == 'actions') ...[
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No alerts right now.',
                      style: TextStyle(color: HrUi.muted(context))),
                )
              else
                for (final n in notifications.take(8))
                  _alertRow(
                    context,
                    title: _alertTitle(n),
                    time: relative((n['created_at'] ?? '').toString()),
                    unread: n['is_read'] != true,
                  ),
            ] else ...[
              if (approvals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('No pending approvals.',
                      style: TextStyle(color: HrUi.muted(context))),
                )
              else
                for (final a in approvals.take(8))
                  _alertRow(
                    context,
                    title: _approvalTitle(a),
                    time: relative((a['created_at'] ?? a['submitted_at'] ?? '').toString()),
                    unread: true,
                  ),
            ],
          ],
        ),
      ),
    );
  }

  String _alertTitle(Map<String, dynamic> n) {
    final title = (n['title'] ?? '').toString().trim();
    final body = (n['body'] ?? '').toString().trim();
    if (title.toLowerCase().contains('acknowledgement') ||
        body.toLowerCase().contains('acknowledgement')) {
      return title.isNotEmpty ? title : body;
    }
    if (title.isNotEmpty && body.isNotEmpty) return '$title — $body';
    return title.isNotEmpty ? title : (body.isNotEmpty ? body : 'Alert');
  }

  String _approvalTitle(Map<String, dynamic> a) {
    final raw = (a['module'] ?? a['kind'] ?? a['type'] ?? 'Request').toString();
    final module = switch (raw.toLowerCase()) {
      'leave' || 'leaves' => 'Leaves',
      'travel' => 'Travel',
      'timesheet' => 'Timesheet',
      'resignation' || 'resignations' => 'Resignations',
      'loan' || 'loan_application' => 'Loan Applications',
      _ => raw.isEmpty ? 'Request' : raw[0].toUpperCase() + raw.substring(1),
    };
    final who = (a['employee_name'] ?? a['requester'] ?? '').toString();
    if (who.isNotEmpty) {
      return 'Your acknowledgement is required for: ($module) — $who';
    }
    return 'Your acknowledgement is required for: ($module)';
  }

  Widget _alertRow(
    BuildContext context, {
    required String title,
    required String time,
    required bool unread,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_tree_outlined, color: _badge, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: HrUi.label(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        time,
                        style: TextStyle(color: HrUi.muted(context), fontSize: 11),
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
    );
  }

  Widget _seg(BuildContext context, String label, int count, bool on, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE8E4DE) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? const Color(0xFFD4CFC6) : HrUi.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: HrUi.label(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _badge,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationsCard extends StatelessWidget {
  const _CelebrationsCard({
    required this.brand,
    required this.scope,
    required this.tab,
    required this.onScope,
    required this.onTab,
    required this.birthdays,
    required this.anniversaries,
  });

  final Color brand;
  final String scope;
  final String tab;
  final ValueChanged<String> onScope;
  final ValueChanged<String> onTab;
  final List<Map<String, dynamic>> birthdays;
  final List<Map<String, dynamic>> anniversaries;

  static const _badge = Color(0xFF8B6B4A);

  @override
  Widget build(BuildContext context) {
    final rows = tab == 'birthdays' ? birthdays : anniversaries;
    return _AccentCard(
      accent: const Color(0xFFC45C4A),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _scopeLink(context, 'Today\'s Celebrations', 'today'),
                const Spacer(),
                _scopeLink(context, 'Future Events', 'future'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _seg(context, 'Birthdays', birthdays.length, tab == 'birthdays',
                    () => onTab('birthdays')),
                const SizedBox(width: 8),
                _seg(context, 'Anniversaries', anniversaries.length,
                    tab == 'anniversaries', () => onTab('anniversaries')),
              ],
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              SizedBox(
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 28,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5C518),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 36,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sentiment_satisfied_alt,
                            color: Colors.white, size: 40),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final r in rows.take(8))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: brand.withValues(alpha: 0.16),
                        child: Text(
                          ((r['name'] ?? '?').toString().isNotEmpty
                                  ? r['name'].toString()[0]
                                  : '?')
                              .toUpperCase(),
                          style: TextStyle(
                            color: brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (r['name'] ?? '').toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: HrUi.label(context),
                                fontSize: 13,
                              ),
                            ),
                            if ((r['title'] ?? '').toString().isNotEmpty)
                              Text(
                                (r['title'] ?? '').toString(),
                                style: TextStyle(
                                  color: HrUi.muted(context),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if ((r['days_until'] as num?) != null &&
                          (r['days_until'] as num) > 0)
                        Text(
                          'in ${r['days_until']}d',
                          style: TextStyle(color: HrUi.muted(context), fontSize: 11),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _scopeLink(BuildContext context, String label, String id) {
    final on = scope == id;
    return InkWell(
      onTap: () => onScope(id),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: on ? HrUi.label(context) : HrUi.muted(context),
        ),
      ),
    );
  }

  Widget _seg(BuildContext context, String label, int count, bool on, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFE8E4DE) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: on ? const Color(0xFFD4CFC6) : HrUi.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: HrUi.label(context),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _badge,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
