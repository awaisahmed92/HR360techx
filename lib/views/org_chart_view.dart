import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../widgets/hr_form_kit.dart';

/// Full-width org chart. Cards scroll sideways; filters narrow the tree.
class OrgChartView extends StatefulWidget {
  const OrgChartView({super.key});

  @override
  State<OrgChartView> createState() => _OrgChartViewState();
}

class _Person {
  _Person(this.raw);
  final Map<String, dynamic> raw;
  int get id => int.tryParse('${raw['employee_id']}') ?? 0;
  int get managerId => int.tryParse('${raw['line_manager']}') ?? 0;
  int get departmentId => int.tryParse('${raw['department_id']}') ?? 0;
  int get stationId => int.tryParse('${raw['station_id']}') ?? 0;
  String get name => '${raw['name'] ?? ''}';
  String get title => '${raw['designation_name'] ?? ''}';
  String get office => '${raw['station_name'] ?? ''}';
  String get department => '${raw['department_name'] ?? ''}';
}

class _OrgChartViewState extends State<OrgChartView> {
  List<_Person> _people = [];
  bool _busy = true;
  String? _error;
  int? _station;
  int? _department;
  int? _user;
  bool _applied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);
      final res = await api.dio.get('/insights/people');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        setState(() {
          _people = ((data['rows'] as List?) ?? []).map((e) => _Person(asStringKeyedMap(e))).toList();
          _busy = false;
        });
        return;
      }
      setState(() {
        _error = 'Could not load the org chart.';
        _busy = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'Could not load the org chart.';
        _busy = false;
      });
    }
  }

  List<_Person> get _visible {
    if (!_applied) return _people;
    return _people.where((p) {
      if (_station != null && p.stationId != _station) return false;
      if (_department != null && p.departmentId != _department) return false;
      return true;
    }).toList();
  }

  List<_Person> _roots(List<_Person> people) {
    if (_user != null && _applied) {
      return people.where((p) => p.id == _user).toList();
    }
    final ids = people.map((p) => p.id).toSet();
    final roots = people.where((p) => p.managerId <= 0 || !ids.contains(p.managerId)).toList();
    return roots.isEmpty ? people : roots;
  }

  List<_Person> _childrenOf(int id, List<_Person> people) =>
      people.where((p) => p.managerId == id && p.id != id).toList();

  String _place(String name) {
    final n = name.trim().toLowerCase();
    if (n == 'head office' || n == 'headoffice' || n == 'headquarters' || n == 'hq') {
      return 'HQ';
    }
    return name;
  }

  String _managerName(int id) {
    for (final person in _people) {
      if (person.id == id) return person.name;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final stations = {
      for (final p in _people)
        if (p.stationId > 0) p.stationId: _place(p.office),
    };
    final departments = {
      for (final p in _people)
        if (p.departmentId > 0) p.departmentId: p.department,
    };
    final visible = _visible;
    final roots = _roots(visible);

    return ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _filter('Office', _station, stations, (v) => setState(() => _station = v)),
                _filter('Department', _department, departments, (v) => setState(() => _department = v)),
                SizedBox(
                  width: 220,
                  child: HrDropdown<int>(
                    value: _user,
                    isExpanded: true,
                    decoration: _box('User'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All users')),
                      for (final p in _people)
                        DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => _user = v),
                  ),
                ),
                FilledButton(
                  onPressed: () => setState(() => _applied = true),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8D6E63)),
                  child: const Text('Apply Filters'),
                ),
                OutlinedButton(
                  onPressed: () => _report(visible),
                  child: const Text('Open Report'),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: box.maxWidth, minHeight: box.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final root in roots) _node(root, visible, 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filter(String label, int? value, Map<int, String> options, ValueChanged<int?> onChanged) {
    return SizedBox(
      width: 200,
      child: HrDropdown<int>(
        value: value,
        isExpanded: true,
        decoration: _box(label),
        items: [
          DropdownMenuItem(value: null, child: Text('All $label')),
          for (final e in options.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  InputDecoration _box(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );

  Widget _node(_Person person, List<_Person> people, int depth) {
    if (depth > 8) return const SizedBox.shrink();
    final kids = _childrenOf(person.id, people);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _card(person, kids.length),
        if (kids.isNotEmpty) ...[
          Container(width: 2, height: 16, color: const Color(0xFF93C5FD)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < kids.length; i++)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bar(i, kids.length),
                    _node(kids[i], people, depth + 1),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _bar(int index, int count) {
    const line = Color(0xFF93C5FD);
    return SizedBox(
      width: 168,
      height: 16,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: index == 0 ? Colors.transparent : line)),
              ),
            ),
          ),
          Container(width: 2, height: 16, color: line),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: index == count - 1 ? Colors.transparent : line)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(_Person person, int reports) {
    final photo = AppConfig.resolveMediaUrl(person.raw['profile_picture']?.toString());
    return Container(
      width: 156,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFDBEAFE),
            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
            child: photo.isEmpty ? const Icon(Icons.person, color: Color(0xFF2563EB)) : null,
          ),
          const SizedBox(height: 8),
          Text(person.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8), fontSize: 13)),
          if (person.title.isNotEmpty)
            Text(person.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          if (person.office.isNotEmpty)
            Text(_place(person.office), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$reports', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  void _report(List<_Person> people) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Org Chart Report'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Job Title')),
                DataColumn(label: Text('Department')),
                DataColumn(label: Text('Office')),
                DataColumn(label: Text('Reports To')),
              ],
              rows: [
                for (final p in people)
                  DataRow(cells: [
                    DataCell(Text(p.name)),
                    DataCell(Text(p.title)),
                    DataCell(Text(p.department)),
                    DataCell(Text(_place(p.office))),
                    DataCell(Text(_managerName(p.managerId))),
                  ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
