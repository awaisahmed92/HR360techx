import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/employees/employee_state.dart';
import '../widgets/hr_record_kit.dart';
import 'employee_form_view.dart';

/// Onboarding landing: add a new employee, continue an existing one, then tasks.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final EmployeeState _state;
  bool _showForm = false;
  int? _editId;
  int? _selectedId;
  final _done = <int, Set<String>>{};

  static const _employeeTasks = [
    'Complete personal profile',
    'Upload identity documents',
    'Acknowledge company policies',
    'Add bank and payroll details',
  ];
  static const _internalTasks = [
    'Create system access',
    'Assign reporting manager',
    'Issue appointment letter',
    'Schedule orientation',
  ];

  @override
  void initState() {
    super.initState();
    _state = EmployeeState(context.read<AuthState>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load());
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  void _openForm(int? id) {
    setState(() {
      _editId = id;
      _showForm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showForm) {
      return EmployeeFormView(
        state: _state,
        editId: _editId,
        onCancel: () => setState(() => _showForm = false),
        onDone: () {
          setState(() => _showForm = false);
          _state.load();
        },
      );
    }
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: const Color(0xFFF7F8FB),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right, size: 18, color: kRecMuted),
                  SizedBox(width: 8),
                  Text('Onboarding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kRecInk)),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final stacked = c.maxWidth < 860;
                  final cards = [_addCard(), _searchCard()];
                  if (stacked) {
                    return Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final stacked = c.maxWidth < 860;
                  final cards = [
                    _taskCard('Employee Tasks', _employeeTasks),
                    _taskCard('Internal Tasks', _internalTasks),
                  ];
                  if (stacked) {
                    return Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: 16),
                      Expanded(child: cards[1]),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addCard() {
    return _panel(
      child: Column(
        children: [
          const Text('Add a New Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kRecInk)),
          const SizedBox(height: 18),
          const _AddArt(),
          const SizedBox(height: 16),
          const Text(
            'This process will let you Add a New Employee and initiate the onboarding process.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kRecMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: kRecPurple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => _openForm(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Employee'),
          ),
        ],
      ),
    );
  }

  Widget _searchCard() {
    final names = <int, String>{
      for (final row in _state.rows)
        if ((row['employee_id'] as num?) != null) (row['employee_id'] as num).toInt(): '${row['name'] ?? 'Employee'}',
    };
    return _panel(
      child: Column(
        children: [
          const Text('Search for Existing Employees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kRecInk)),
          const SizedBox(height: 18),
          const _SearchArt(),
          const SizedBox(height: 16),
          const Text(
            'This process will let you initiate or continue the onboarding process for an existing employee.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kRecMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<int?>(
            value: names.containsKey(_selectedId) ? _selectedId : null,
            isExpanded: true,
            decoration: hrWaDecoration(hint: 'Select Employees'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Select Employees')),
              for (final entry in names.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (id) => setState(() => _selectedId = id),
          ),
          if (_selectedId != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _openForm(_selectedId),
              child: const Text('Continue onboarding'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _taskCard(String title, List<String> tasks) {
    final id = _selectedId;
    final done = id == null ? <String>{} : (_done[id] ?? const <String>{});
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kRecInk)),
          const SizedBox(height: 8),
          if (id == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('Select an employee to track these tasks.', style: TextStyle(color: kRecMuted)),
            )
          else
            for (final task in tasks)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: done.contains(task),
                activeColor: kRecPurple,
                title: Text(task, style: const TextStyle(fontSize: 13.5, color: kRecInk)),
                onChanged: (v) {
                  setState(() {
                    final set = _done.putIfAbsent(id, () => <String>{});
                    if (v == true) {
                      set.add(task);
                    } else {
                      set.remove(task);
                    }
                  });
                },
              ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF3)),
      ),
      child: child,
    );
  }
}

class _AddArt extends StatelessWidget {
  const _AddArt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle, size: 120, color: Color(0xFFEDE7FF)),
          Icon(Icons.assignment_ind_outlined, size: 64, color: Color(0xFF7C6CF0)),
          Positioned(right: 86, bottom: 28, child: Icon(Icons.work_outline, size: 28, color: Color(0xFF8B7CF6))),
        ],
      ),
    );
  }
}

class _SearchArt extends StatelessWidget {
  const _SearchArt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle, size: 120, color: Color(0xFFEDE7FF)),
          Icon(Icons.desktop_windows_outlined, size: 64, color: Color(0xFF7C6CF0)),
          Positioned(right: 90, bottom: 30, child: Icon(Icons.person_outline, size: 26, color: Color(0xFF8B7CF6))),
        ],
      ),
    );
  }
}
