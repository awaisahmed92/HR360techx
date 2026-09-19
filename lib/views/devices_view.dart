import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/devices/devices_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

class DevicesView extends StatefulWidget {
  const DevicesView({super.key});

  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  late final DevicesState _state;

  @override
  void initState() {
    super.initState();
    _state = DevicesState(context.read<AuthState>());
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
        final s = _state.stats;
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Text(
                    'Biometric Devices',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HrUi.label(context),
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Devices')),
                      ButtonSegment(value: 1, label: Text('Raw punches')),
                    ],
                    selected: {_state.tab},
                    onSelectionChanged: (v) => _state.setTab(v.first),
                  ),
                  const SizedBox(width: 12),
                  if (_state.tab == 0)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: _addDevice,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  IconButton(
                    onPressed: () => _state.load(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _statChip('Devices', '${s['devices'] ?? 0}'),
                  _statChip('Active', '${s['active_devices'] ?? 0}'),
                  _statChip('Punches today', '${s['punches_today'] ?? 0}'),
                  _statChip('Unprocessed', '${s['unprocessed'] ?? 0}'),
                  if (s['last_punch_at'] != null)
                    _statChip('Last punch', '${s['last_punch_at']}'),
                ],
              ),
              if (_state.tables['biometric_devices'] == false ||
                  _state.tables['device_attendance'] == false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Some device tables are missing on this tenant — status still works when present.',
                    style: TextStyle(color: HrUi.muted(context), fontSize: 13),
                  ),
                ),
              if (_state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              const SizedBox(height: 16),
              if (_state.busy && _state.devices.isEmpty && _state.punches.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_state.tab == 0)
                ..._devices()
              else
                ..._punches(),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HrUi.card(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HrUi.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: HrUi.muted(context))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: HrUi.label(context))),
        ],
      ),
    );
  }

  List<Widget> _devices() {
    if (_state.devices.isEmpty) {
      return [
        Text(
          'No biometric devices configured. Add a device record (ingest stays on the server).',
          style: TextStyle(color: HrUi.muted(context)),
        ),
      ];
    }
    return _state.devices.map((d) {
      final active = d['is_active'] == true;
      return ListTile(
        leading: Icon(
          Icons.fingerprint,
          color: active ? Colors.green : HrUi.muted(context),
        ),
        title: Text('${d['name']}'),
        subtitle: Text(
          '${d['status_label']} · ${d['serial_number']} · ${d['ip_address']}:${d['port']}'
          '${d['last_sync'] != null ? ' · sync ${d['last_sync']}' : ''}'
          '${(d['last_error'] as String?)?.isNotEmpty == true ? ' · err ${d['last_error']}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editDevice(d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final err = await _state.deleteDevice((d['id'] as num).toInt());
                if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
              },
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _punches() {
    return [
      Row(
        children: [
          Text('Filter', style: TextStyle(color: HrUi.muted(context))),
          const SizedBox(width: 12),
          DropdownButton<int?>(
            value: _state.punchFilter,
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 0, child: Text('Unprocessed')),
              DropdownMenuItem(value: 1, child: Text('Processed')),
            ],
            onChanged: (v) => _state.setPunchFilter(v),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_state.punches.isEmpty)
        Text('No raw device punches yet.', style: TextStyle(color: HrUi.muted(context)))
      else
        ..._state.punches.map((p) {
          final processed = p['processed'] == true;
          return ListTile(
            dense: true,
            leading: Icon(
              processed ? Icons.check_circle_outline : Icons.pending_outlined,
              color: processed ? Colors.green : Colors.orange,
              size: 20,
            ),
            title: Text(
              '${p['employee_name']?.toString().isNotEmpty == true ? p['employee_name'] : p['employee_code']} · ${p['punch_type']}',
            ),
            subtitle: Text(
              '${p['punch_time']} · ${p['device_name'] ?? p['device_id'] ?? 'device'}'
              '${(p['verify_mode'] as String?)?.isNotEmpty == true ? ' · ${p['verify_mode']}' : ''}',
            ),
          );
        }),
    ];
  }

  Future<void> _addDevice() => _editDevice(null);

  Future<void> _editDevice(Map<String, dynamic>? existing) async {
    final name = TextEditingController(text: '${existing?['name'] ?? ''}');
    final serial = TextEditingController(text: '${existing?['serial_number'] ?? ''}');
    final ip = TextEditingController(text: '${existing?['ip'] ?? existing?['ip_address'] ?? ''}');
    final port = TextEditingController(text: '${existing?['port'] ?? 80}');
    final type = TextEditingController(text: '${existing?['device_type'] ?? 'ZKTeco'}');
    String status = '${existing?['status'] ?? 'inactive'}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add Device' : 'Edit Device'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
                  TextField(controller: serial, decoration: const InputDecoration(labelText: 'Serial *')),
                  TextField(controller: ip, decoration: const InputDecoration(labelText: 'IP address *')),
                  TextField(controller: port, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
                  TextField(controller: type, decoration: const InputDecoration(labelText: 'Type')),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'testing', child: Text('Testing')),
                      DropdownMenuItem(value: 'error', child: Text('Error')),
                    ],
                    onChanged: (v) => setLocal(() => status = v ?? 'inactive'),
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
    if (ok != true || name.text.trim().isEmpty || serial.text.trim().isEmpty || ip.text.trim().isEmpty) {
      return;
    }
    final err = await _state.saveDevice(
      {
        'name': name.text.trim(),
        'serial_number': serial.text.trim(),
        'ip_address': ip.text.trim(),
        'port': int.tryParse(port.text) ?? 80,
        'device_type': type.text.trim(),
        'status': status,
        'is_active': status == 'active',
        'protocol': 'http',
      },
      id: existing == null ? null : (existing['id'] as num).toInt(),
    );
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}
