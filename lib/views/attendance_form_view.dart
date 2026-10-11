import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/network/api_client.dart';
import '../core/util/json_maps.dart';
import '../theme/hr_theme.dart';

/// Add New Attendance — user, date, sign in/out, lunch, and extra break.
class AttendanceFormView extends StatefulWidget {
  const AttendanceFormView({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AttendanceFormView> createState() => _AttendanceFormViewState();
}

class _AttendanceFormViewState extends State<AttendanceFormView> {
  final _date = TextEditingController();
  final _in = TextEditingController();
  final _out = TextEditingController();
  final _lunchOut = TextEditingController();
  final _lunchIn = TextEditingController();
  final _extraOut = TextEditingController();
  final _extraIn = TextEditingController();
  List<Map<String, dynamic>> _people = [];
  int? _employeeId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date.text = '${now.month.toString().padLeft(2, '0')} / ${now.day.toString().padLeft(2, '0')} / ${now.year}';
    _loadPeople();
  }

  @override
  void dispose() {
    for (final c in [_date, _in, _out, _lunchOut, _lunchIn, _extraOut, _extraIn]) {
      c.dispose();
    }
    super.dispose();
  }

  ApiClient get _api => ApiClient(tokenProvider: () async => context.read<AuthState>().session?.token);

  Future<void> _loadPeople() async {
    try {
      final res = await _api.dio.get('/employees');
      final data = res.data;
      if (data is Map && data['success'] == true) {
        final rows = ((data['rows'] as List?) ?? []).map(asStringKeyedMap).toList();
        setState(() {
          _people = rows;
          if (rows.isNotEmpty) {
            _employeeId = int.tryParse('${rows.first['employee_id']}');
          }
        });
      }
    } catch (_) {}
  }

  String? _isoDate() {
    final parts = _date.text.split('/').map((p) => p.trim()).toList();
    if (parts.length != 3) return null;
    final m = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (m == null || d == null || y == null) return null;
    return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_isoDate() ?? '') ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date.text =
          '${picked.month.toString().padLeft(2, '0')} / ${picked.day.toString().padLeft(2, '0')} / ${picked.year}';
    });
  }

  Future<void> _pickTime(TextEditingController target) async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    setState(() {
      target.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    final date = _isoDate();
    if (_employeeId == null || date == null || _in.text.trim().isEmpty) {
      setState(() => _error = 'User, date, and sign in time are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await _api.dio.post('/attendance/admin/save', data: {
        'employee_id': _employeeId,
        'date': date,
        'punch_in': _in.text.trim(),
        'punch_out': _out.text.trim().isEmpty ? null : _out.text.trim(),
        'lunch_out': _lunchOut.text.trim().isEmpty ? null : _lunchOut.text.trim(),
        'lunch_in': _lunchIn.text.trim().isEmpty ? null : _lunchIn.text.trim(),
        'extra_out': _extraOut.text.trim().isEmpty ? null : _extraOut.text.trim(),
        'extra_in': _extraIn.text.trim().isEmpty ? null : _extraIn.text.trim(),
        'status': 1,
      });
      final data = res.data;
      if (data is Map && data['success'] == true) {
        if (mounted) widget.onBack?.call();
        return;
      }
      setState(() => _error = (data is Map ? data['message'] : null)?.toString() ?? 'Save failed');
    } on DioException catch (e) {
      final body = e.response?.data;
      setState(() => _error = body is Map ? '${body['message']}' : 'Save failed');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 40),
        children: [
          Row(
            children: [
              const Spacer(),
              Text('Add New Attendance',
                  style: TextStyle(fontSize: 22, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _section('User Attendance Information'),
          _row(
            'User Name:',
            required: true,
            child: DropdownButtonFormField<int>(
              value: _employeeId,
              decoration: _deco(),
              items: [
                for (final p in _people)
                  DropdownMenuItem(
                    value: int.tryParse('${p['employee_id']}'),
                    child: Text('${p['name'] ?? p['user_name'] ?? 'Employee'}'),
                  ),
              ],
              onChanged: (v) => setState(() => _employeeId = v),
            ),
          ),
          _row(
            'Attendance Date:',
            required: true,
            child: TextField(
              controller: _date,
              readOnly: true,
              decoration: _deco(icon: Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 18),
          _section('Regular Work Hours'),
          _row(
            'Sign In Time:',
            required: true,
            child: TextField(
              controller: _in,
              readOnly: true,
              decoration: _deco(icon: Icons.access_time, hint: '-- : --'),
              onTap: () => _pickTime(_in),
            ),
          ),
          _row(
            'Sign Out Time:',
            child: TextField(
              controller: _out,
              readOnly: true,
              decoration: _deco(icon: Icons.access_time, hint: '-- : --'),
              onTap: () => _pickTime(_out),
            ),
          ),
          const SizedBox(height: 18),
          _section('Lunch Break Hours'),
          _row(
            'Lunch Break Out Time:',
            child: TextField(
              controller: _lunchOut,
              readOnly: true,
              decoration: _deco(icon: Icons.access_time, hint: '-- : --'),
              onTap: () => _pickTime(_lunchOut),
            ),
          ),
          _row(
            'Lunch Break In Time:',
            child: TextField(
              controller: _lunchIn,
              readOnly: true,
              decoration: _deco(icon: Icons.access_time, hint: '-- : --'),
              onTap: () => _pickTime(_lunchIn),
            ),
          ),
          const SizedBox(height: 18),
          _section('Additional Break Hours'),
          _row(
            'Additional Break Out Time:',
            child: TextField(
              controller: _extraOut,
              readOnly: true,
              decoration: _deco(icon: Icons.access_time, hint: '-- : --'),
              onTap: () => _pickTime(_extraOut),
            ),
          ),
          _row(
            'Additional Break In Time:',
            child: TextField(
              controller: _extraIn,
              readOnly: true,
              decoration: _deco(icon: Icons.access_time, hint: '-- : --'),
              onTap: () => _pickTime(_extraIn),
            ),
          ),
          const SizedBox(height: 22),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: HrUi.brand),
              child: Text(_busy ? 'Saving…' : 'Save Attendance'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey.shade900)),
      );

  Widget _row(String label, {required Widget child, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(label, style: TextStyle(color: Colors.grey.shade800)),
          ),
          SizedBox(width: 280, child: child),
          const SizedBox(width: 8),
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
          if (required) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  InputDecoration _deco({IconData? icon, String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        suffixIcon: icon == null ? null : Icon(icon, size: 18, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      );
}
