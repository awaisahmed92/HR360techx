import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth/auth_state.dart';
import '../core/calendar/calendar_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart'; // HrUi

class CalendarView extends StatefulWidget {
  const CalendarView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late final CalendarState _state;
  CalendarFormat _format = CalendarFormat.month;

  static const _tabs = ['Calendar', 'Events', 'Meetings', 'Settings', 'Reports'];

  @override
  void initState() {
    super.initState();
    _state = CalendarState(context.read<AuthState>())
      ..tab = widget.initialTab.clamp(0, _tabs.length - 1);
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Company Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HrUi.label(context),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _state.load(),
                      icon: const Icon(Icons.refresh),
                    ),
                    if (_state.tab == 1)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                        onPressed: () => _editEvent(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Event'),
                      ),
                    if (_state.tab == 2)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                        onPressed: () => _editMeeting(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Meeting'),
                      ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_tabs[i]),
                          selected: _state.tab == i,
                          selectedColor: HrTheme.brand(context),
                          labelStyle: TextStyle(
                            color: _state.tab == i ? HrTheme.onBrand(context) : HrUi.label(context),
                            fontWeight: FontWeight.w600,
                          ),
                          checkmarkColor: HrTheme.onBrand(context),
                          onSelected: (_) => _state.setTab(i),
                        ),
                      ),
                  ],
                ),
              ),
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Expanded(
                child: _state.busy && _state.events.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : switch (_state.tab) {
                        0 => _calendarTab(),
                        1 => _eventsTab(),
                        2 => _meetingsTab(),
                        3 => _settingsTab(),
                        _ => _reportsTab(),
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _calendarTab() {
    final selected = _state.selectedDay ?? _state.focusedDay;
    final dayItems = _state.itemsForDay(selected);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final k in ['leave', 'holiday', 'birthday', 'anniversary', 'training', 'interview'])
              FilterChip(
                label: Text(k),
                selected: _state.overlayToggles.contains(k),
                selectedColor: HrTheme.brand(context),
                checkmarkColor: HrTheme.onBrand(context),
                labelStyle: TextStyle(
                  color: _state.overlayToggles.contains(k) ? HrTheme.onBrand(context) : HrUi.label(context),
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => _state.toggleOverlay(k),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _state.focusedDay,
          calendarFormat: _format,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (d) => isSameDay(d, _state.selectedDay),
          eventLoader: (d) => _state.itemsForDay(d),
          onFormatChanged: (f) => setState(() => _format = f),
          onDaySelected: (selectedDay, focusedDay) {
            _state.selectDay(selectedDay, focusedDay);
          },
          onPageChanged: (focused) {
            _state.focusedDay = focused;
            _state.load();
          },
        ),
        const SizedBox(height: 12),
        Text('Day detail', style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
        const SizedBox(height: 8),
        if (dayItems.isEmpty)
          Text('No items', style: TextStyle(color: HrUi.muted(context)))
        else
          ...dayItems.map(
            (e) => ListTile(
              dense: true,
              leading: Icon(
                e['kind'] == 'meeting' ? Icons.groups_outlined : Icons.event_outlined,
                color: HrTheme.brand(context),
              ),
              title: Text('${e['title'] ?? ''}'),
              subtitle: Text('${e['kind']} · ${e['start_at'] ?? e['meeting_date'] ?? e['date'] ?? ''}'),
            ),
          ),
      ],
    );
  }

  Widget _eventsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _state.events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = _state.events[i];
        return ListTile(
          title: Text('${e['title']}'),
          subtitle: Text('${e['start_at']} · ${e['type_title'] ?? ''} · ${e['status']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editEvent(e)),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await _state.deleteEvent((e['id'] as num).toInt());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _meetingsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _state.meetings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final m = _state.meetings[i];
        return ListTile(
          title: Text('${m['title']}'),
          subtitle: Text('${m['meeting_date']} ${m['meeting_time'] ?? ''}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ('${m['teams_join_url']}'.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.videocam_outlined),
                  onPressed: () => launchUrl(Uri.parse('${m['teams_join_url']}')),
                ),
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editMeeting(m)),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _state.deleteMeeting((m['id'] as num).toInt()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _settingsTab() {
    final startCtrl = TextEditingController(text: '${_state.settings['start_of_week'] ?? 1}');
    final gClient = TextEditingController(text: '${_state.settings['google_client_id'] ?? ''}');
    final teamsTenant = TextEditingController(text: '${_state.settings['teams_tenant_id'] ?? ''}');
    final teamsClient = TextEditingController(text: '${_state.settings['teams_client_id'] ?? ''}');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Defaults', style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
        const SizedBox(height: 8),
        TextField(
          controller: startCtrl,
          decoration: const InputDecoration(labelText: 'Start of week (0=Sun … 6=Sat)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        Text('Integrations', style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
        const SizedBox(height: 8),
        TextField(controller: gClient, decoration: const InputDecoration(labelText: 'Google Client ID', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: teamsTenant, decoration: const InputDecoration(labelText: 'Teams Tenant ID', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: teamsClient, decoration: const InputDecoration(labelText: 'Teams Client ID', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () async {
                final err = await _state.saveSettings({
                  'start_of_week': int.tryParse(startCtrl.text) ?? 1,
                  'google_client_id': gClient.text.trim().isEmpty ? null : gClient.text.trim(),
                  'teams_tenant_id': teamsTenant.text.trim().isEmpty ? null : teamsTenant.text.trim(),
                  'teams_client_id': teamsClient.text.trim().isEmpty ? null : teamsClient.text.trim(),
                  'default_overlays': _state.overlayToggles.toList(),
                  'show_everyone': true,
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
              },
              child: const Text('Save settings'),
            ),
            OutlinedButton(
              onPressed: () async {
                await _state.loadIcsToken(regenerate: true);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_state.icsToken == null ? 'ICS failed' : 'ICS token: ${_state.icsToken}')),
                );
              },
              child: const Text('Regenerate ICS token'),
            ),
            OutlinedButton(
              onPressed: () async {
                await _state.loadGoogleConnect();
                final url = _state.googleConnectUrl;
                if (url != null) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_state.error ?? 'Google setup needed')),
                  );
                }
              },
              child: const Text('Connect Google'),
            ),
            OutlinedButton(
              onPressed: () async {
                final msg = await _state.googleSync();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Done')));
              },
              child: const Text('Sync Google'),
            ),
          ],
        ),
        if (_state.icsToken != null) ...[
          const SizedBox(height: 12),
          SelectableText('ICS path: /api/calendar/ics/${_state.icsToken}.ics?org=demo'),
        ],
        const SizedBox(height: 8),
        Text(
          'Google configured: ${_state.settings['google_configured'] == true} · Teams: ${_state.settings['teams_configured'] == true}',
          style: TextStyle(color: HrUi.muted(context)),
        ),
      ],
    );
  }

  Widget _reportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _statCard('Month', '${_state.reports['month'] ?? ''}'),
          _statCard('Events', '${_state.reports['events'] ?? 0}'),
          _statCard('Meetings', '${_state.reports['meetings'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: HrUi.muted(context))),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: HrUi.label(context))),
        ],
      ),
    );
  }

  Future<void> _editEvent([Map<String, dynamic>? row]) async {
    final title = TextEditingController(text: '${row?['title'] ?? ''}');
    final start = TextEditingController(text: '${row?['start_at'] ?? DateTime.now().toIso8601String().substring(0, 16).replaceFirst('T', ' ')}');
    final loc = TextEditingController(text: '${row?['location'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(row == null ? 'New event' : 'Edit event'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: start, decoration: const InputDecoration(labelText: 'Start (YYYY-MM-DD HH:MM)')),
              TextField(controller: loc, decoration: const InputDecoration(labelText: 'Location')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final err = await _state.saveEvent({
      'title': title.text.trim(),
      'start_at': start.text.trim(),
      'location': loc.text.trim(),
      'all_day': false,
    }, id: row == null ? null : (row['id'] as num?)?.toInt());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
  }

  Future<void> _editMeeting([Map<String, dynamic>? row]) async {
    final title = TextEditingController(text: '${row?['title'] ?? ''}');
    final date = TextEditingController(text: '${row?['meeting_date'] ?? DateTime.now().toIso8601String().substring(0, 10)}');
    final time = TextEditingController(text: '${row?['meeting_time'] ?? '10:00:00'}');
    var teams = row?['teams_enabled'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(row == null ? 'New meeting' : 'Edit meeting'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: date, decoration: const InputDecoration(labelText: 'Date')),
                TextField(controller: time, decoration: const InputDecoration(labelText: 'Time')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Create Teams meeting'),
                  value: teams,
                  onChanged: (v) => setLocal(() => teams = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final msg = await _state.saveMeeting({
      'title': title.text.trim(),
      'meeting_date': date.text.trim(),
      'meeting_time': time.text.trim(),
      'teams_enabled': teams,
      'duration_min': 60,
    }, id: row == null ? null : (row['id'] as num?)?.toInt());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Saved')));
  }
}
