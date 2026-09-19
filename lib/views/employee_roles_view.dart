import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../widgets/hr_form_kit.dart';

/// Employee Roles — module View / Add / Edit / Delete (no Copy / Templates).
class EmployeeRolesView extends StatefulWidget {
  const EmployeeRolesView({super.key});

  @override
  State<EmployeeRolesView> createState() => _EmployeeRolesViewState();
}

class _EmployeeRolesViewState extends State<EmployeeRolesView> {
  late final EmployeeState _state;
  int? _selectedId;
  Map<String, dynamic> _permissions = {};
  List<Map<String, dynamic>> _catalog = [];
  bool _loadingRoles = false;
  bool _saving = false;

  static const _accent = Color(0xFFA67C5D);

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _state.load();
      if (!mounted) return;
      setState(() => _catalog = List.from(_state.roleCatalog));
      if (_state.rows.isNotEmpty) {
        await _selectEmployee((_state.rows.first['employee_id'] as num).toInt());
      }
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _selectEmployee(int id) async {
    setState(() {
      _selectedId = id;
      _loadingRoles = true;
    });
    final data = await _state.loadRoles(id);
    if (!mounted) return;
    if (data != null) {
      final perms = data['permissions'];
      _permissions = perms is Map
          ? Map<String, dynamic>.from(perms.map((k, v) => MapEntry(k.toString(), v)))
          : {};
      final cat = data['role_catalog'];
      if (cat is List && cat.isNotEmpty) {
        _catalog = cat.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    setState(() => _loadingRoles = false);
  }

  Map<String, dynamic> _module(String key) {
    final raw = _permissions[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'enabled': false, 'screens': <String, dynamic>{}};
  }

  Map<String, dynamic> _screen(String module, String screen) {
    final screens = _module(module)['screens'];
    if (screens is Map && screens[screen] is Map) {
      return Map<String, dynamic>.from(screens[screen] as Map);
    }
    return {'view': false, 'add': false, 'edit': false, 'delete': false};
  }

  void _setModuleEnabled(String module, bool enabled) {
    final mod = _module(module);
    mod['enabled'] = enabled;
    _permissions[module] = mod;
    setState(() {});
  }

  void _setFlag(String module, String screen, String flag, bool value) {
    final mod = _module(module);
    final screens = Map<String, dynamic>.from(
      (mod['screens'] is Map) ? mod['screens'] as Map : {},
    );
    final flags = _screen(module, screen);
    flags[flag] = value;
    if (value && flag != 'view') flags['view'] = true;
    screens[screen] = flags;
    mod['screens'] = screens;
    mod['enabled'] = true;
    _permissions[module] = mod;
    setState(() {});
  }

  Future<void> _save() async {
    if (_selectedId == null) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{};
    _permissions.forEach((mod, raw) {
      if (raw is! Map) return;
      final screensOut = <String, dynamic>{};
      final screens = raw['screens'];
      if (screens is Map) {
        screens.forEach((sk, sv) {
          if (sv is Map) {
            screensOut[sk.toString()] = {
              'view': sv['view'] == true,
              'add': sv['add'] == true,
              'edit': sv['edit'] == true,
              'delete': sv['delete'] == true,
            };
          }
        });
      }
      payload[mod] = {'enabled': raw['enabled'] == true, 'screens': screensOut};
    });
    final err = await _state.saveRoles(_selectedId!, payload);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Roles saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: HrUi.pageBg(context),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Icon(Icons.security_outlined, size: 18, color: HrUi.label(context)),
                  const SizedBox(width: 8),
                  Text(
                    'Employee Roles',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: HrUi.label(context),
                    ),
                  ),
                  const Spacer(),
                  const Text('Employee:', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<int>(
                      value: _selectedId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _state.rows.map((e) {
                        final id = (e['employee_id'] as num).toInt();
                        return DropdownMenuItem(
                          value: id,
                          child: Text('${e['name']} (${e['user_name']})'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) _selectEmployee(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _accent),
                    onPressed: _saving || _selectedId == null ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save Roles'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loadingRoles)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_catalog.isEmpty)
                const Text('No role catalog loaded.')
              else
                ..._catalog.map(_moduleTile),
            ],
          ),
        );
      },
    );
  }

  Widget _moduleTile(Map<String, dynamic> mod) {
    final key = '${mod['key']}';
    final label = '${mod['label']}';
    final enabled = _module(key)['enabled'] == true;
    final screens = ((mod['screens'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.add_circle_outline, color: Colors.grey.shade700, size: 22),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A3F35)),
              ),
            ),
            Switch(
              value: enabled,
              activeColor: _accent,
              onChanged: (v) => _setModuleEnabled(key, v),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(children: [_th('Screen'), _th('View'), _th('Add'), _th('Edit'), _th('Delete')]),
              for (final s in screens)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('${s['label']}', style: const TextStyle(fontSize: 13)),
                    ),
                    _cb(key, '${s['key']}', 'view'),
                    _cb(key, '${s['key']}', 'add'),
                    _cb(key, '${s['key']}', 'edit'),
                    _cb(key, '${s['key']}', 'delete'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _th(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
      );

  Widget _cb(String module, String screen, String flag) {
    return Center(
      child: Checkbox(
        value: _screen(module, screen)[flag] == true,
        activeColor: _accent,
        onChanged: (v) => _setFlag(module, screen, flag, v ?? false),
      ),
    );
  }
}
