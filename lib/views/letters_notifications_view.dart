import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/letters/letter_state.dart';
import '../core/self_service/self_service_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// HR letter templates + employee preview.
class LettersView extends StatefulWidget {
  const LettersView({super.key});

  @override
  State<LettersView> createState() => _LettersViewState();
}

class _LettersViewState extends State<LettersView> {
  late final LetterState _state;

  @override
  void initState() {
    super.initState();
    _state = LetterState(context.read<AuthState>());
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
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text('HR Letters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    FilledButton.icon(
                      style: HrTheme.filledButton(context),
                      onPressed: () => _editLetter(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Template'),
                    ),
                    IconButton(onPressed: () => _state.load(), icon: const Icon(Icons.refresh)),
                  ],
                ),
              ),
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Expanded(
                child: _state.busy && _state.letters.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _state.letters.isEmpty
                        ? Center(child: Text('No letter templates.', style: TextStyle(color: HrUi.muted(context))))
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _state.letters.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final l = _state.letters[i];
                              return Card(
                                child: ListTile(
                                  title: Text('${l['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                    '${l['page_size']} · margins T${l['margin_top']} R${l['margin_right']} B${l['margin_bottom']} L${l['margin_left']}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Preview',
                                        icon: const Icon(Icons.visibility_outlined),
                                        onPressed: () => _preview(l),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _editLetter(existing: l),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final err = await _state.delete((l['id'] as num).toInt());
                                          if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () => _editLetter(existing: l),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editLetter({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final content = TextEditingController(text: '${existing?['content'] ?? ''}');
    String pageSize = '${existing?['page_size'] ?? 'A4'}';
    final mt = TextEditingController(text: '${existing?['margin_top'] ?? 20}');
    final mr = TextEditingController(text: '${existing?['margin_right'] ?? 20}');
    final mb = TextEditingController(text: '${existing?['margin_bottom'] ?? 20}');
    final ml = TextEditingController(text: '${existing?['margin_left'] ?? 20}');
    final placeholders = (_state.options['placeholders'] as List?) ?? [];
    final sizes = (_state.options['page_sizes'] as List?) ?? ['A4', 'LETTER', 'LEGAL'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add Letter' : 'Edit Letter'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
                  DropdownButtonFormField<String>(
                    value: pageSize,
                    decoration: const InputDecoration(labelText: 'Page size'),
                    items: sizes
                        .map((s) => DropdownMenuItem(value: '$s', child: Text('$s')))
                        .toList(),
                    onChanged: (v) => setLocal(() => pageSize = v ?? 'A4'),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: placeholders
                        .map((p) => ActionChip(
                              label: Text('$p', style: const TextStyle(fontSize: 11)),
                              onPressed: () {
                                content.text = '${content.text}$p';
                                content.selection = TextSelection.collapsed(offset: content.text.length);
                                setLocal(() {});
                              },
                            ))
                        .toList(),
                  ),
                  TextField(
                    controller: content,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 8,
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: mt, decoration: const InputDecoration(labelText: 'Margin top'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: mr, decoration: const InputDecoration(labelText: 'Right'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: mb, decoration: const InputDecoration(labelText: 'Bottom'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: ml, decoration: const InputDecoration(labelText: 'Left'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final err = await _state.save({
      'name': name.text.trim(),
      'content': content.text,
      'page_size': pageSize,
      'margin_top': double.tryParse(mt.text) ?? 20,
      'margin_right': double.tryParse(mr.text) ?? 20,
      'margin_bottom': double.tryParse(mb.text) ?? 20,
      'margin_left': double.tryParse(ml.text) ?? 20,
    }, id: (existing?['id'] as num?)?.toInt());
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _preview(Map<String, dynamic> letter) async {
    final employees = (_state.options['employees'] as List?) ?? [];
    int? empId;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text('Preview · ${letter['name']}'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    value: empId,
                    decoration: const InputDecoration(labelText: 'Employee'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— placeholders only —')),
                      ...employees.whereType<Map>().map((e) {
                        final id = (e['id'] as num?)?.toInt();
                        return DropdownMenuItem(value: id, child: Text('${e['name']}'));
                      }),
                    ],
                    onChanged: (v) async {
                      setLocal(() => empId = v);
                      await _state.loadPreview((letter['id'] as num).toInt(), v);
                      setLocal(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _state.preview?['content']?.toString() ??
                          letter['content']?.toString() ??
                          '',
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              FilledButton(
                onPressed: () async {
                  await _state.loadPreview((letter['id'] as num).toInt(), empId);
                  setLocal(() {});
                },
                child: const Text('Render'),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
