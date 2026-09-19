import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/recruitment/recruitment_state.dart';
import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_form_kit.dart';

/// API-backed talent pipeline (Kanban) + Jobs CRUD.
class RecruitmentView extends StatefulWidget {
  const RecruitmentView({super.key});

  @override
  State<RecruitmentView> createState() => _RecruitmentViewState();
}

class _RecruitmentViewState extends State<RecruitmentView> {
  late final RecruitmentState _state;

  static const _stages = [
    ('Applied', 0, AppTheme.info),
    ('Screening', 1, AppTheme.warning),
    ('Interview', 2, AppTheme.accent),
    ('Offer', 3, AppTheme.cyan),
    ('Hired', 4, AppTheme.success),
  ];

  @override
  void initState() {
    super.initState();
    _state = RecruitmentState(context.read<AuthState>());
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
                    Text('Talent Pipeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HrUi.label(context),
                        )),
                    const Spacer(),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Pipeline')),
                        ButtonSegment(value: 1, label: Text('Jobs')),
                        ButtonSegment(value: 2, label: Text('Long List')),
                        ButtonSegment(value: 3, label: Text('Short List')),
                      ],
                      selected: {_state.tab},
                      onSelectionChanged: (s) => _state.setTab(s.first),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: HrTheme.brand(context)),
                      onPressed: () {
                        if (_state.tab == 1) {
                          _addJob();
                        } else {
                          _addCandidate();
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(_state.tab == 1 ? 'Add Job' : 'Add Candidate'),
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
              if (_state.tab == 2 || _state.tab == 3) _filterBar(),
              Expanded(
                child: _state.busy && _state.candidates.isEmpty && _state.jobs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : switch (_state.tab) {
                        0 => _pipeline(),
                        1 => _jobsTab(),
                        2 => _listTab(_state.longList, short: false),
                        _ => _listTab(_state.shortList, short: true),
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterBar() {
    final jobs = (_state.options['jobs'] as List?) ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 36,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search name/email',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (v) => _state.setFilters(q: v),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<int?>(
              value: _state.filterJobId,
              decoration: const InputDecoration(
                labelText: 'Job',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All jobs')),
                ...jobs.whereType<Map>().map((j) {
                  final id = (j['id'] as num?)?.toInt();
                  return DropdownMenuItem(value: id, child: Text('${j['name']}'));
                }),
              ],
              onChanged: (v) {
                if (v == null) {
                  _state.setFilters(clearJob: true);
                } else {
                  _state.setFilters(jobId: v);
                }
              },
            ),
          ),
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<int?>(
              value: _state.filterGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 1, child: Text('Male')),
                DropdownMenuItem(value: 2, child: Text('Female')),
              ],
              onChanged: (v) {
                if (v == null) {
                  _state.setFilters(clearGender: true);
                } else {
                  _state.setFilters(gender: v);
                }
              },
            ),
          ),
          SizedBox(
            width: 110,
            height: 36,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Experience',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (v) => _state.setFilters(exp: v),
            ),
          ),
          SizedBox(
            width: 120,
            height: 36,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Qualification',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (v) => _state.setFilters(qualification: v),
            ),
          ),
          SizedBox(
            width: 110,
            height: 36,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'District',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (v) => _state.setFilters(district: v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTab(List<Map<String, dynamic>> rows, {required bool short}) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          short ? 'No shortlisted candidates yet (Interview+).' : 'No candidates.',
          style: TextStyle(color: HrUi.muted(context)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final c = rows[i];
        final status = (c['status'] as num?)?.toInt() ?? 0;
        return Card(
          child: ListTile(
            title: Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${c['job_title'] ?? '—'} · ${c['stage'] ?? ''} · ${c['email'] ?? ''}'
              '${'${c['remarks'] ?? ''}'.isNotEmpty ? '\n${c['remarks']}' : ''}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status >= 0 && status < 3)
                  TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final err = await _state.moveStatus((c['id'] as num).toInt(), status + 1);
                      if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                    },
                    child: const Text('Advance'),
                  ),
                if (status == 3)
                  TextButton(
                    onPressed: () => _hireCandidate(c),
                    child: const Text('Hire'),
                  ),
                if (status >= 0 && status < 4)
                  TextButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final err = await _state.moveStatus((c['id'] as num).toInt(), -1);
                      if (err != null) {
                        messenger.showSnackBar(SnackBar(content: Text(err)));
                      } else {
                        messenger.showSnackBar(const SnackBar(content: Text('Candidate rejected')));
                      }
                    },
                    child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
                  ),
                IconButton(
                  tooltip: 'Profile (edu/exp/refs)',
                  icon: const Icon(Icons.badge_outlined),
                  onPressed: () => _editCandidateProfile(c),
                ),
                IconButton(
                  tooltip: 'Reference check',
                  icon: const Icon(Icons.fact_check_outlined),
                  onPressed: () => _referenceNote(c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final err = await _state.deleteCandidate((c['id'] as num).toInt());
                    if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCandidateProfile(Map<String, dynamic> c) async {
    final id = (c['id'] as num).toInt();
    final profile = await _state.loadCandidateProfile(id);
    if (!mounted) return;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load profile')));
      return;
    }
    final degrees = (_state.options['degrees'] as List?) ?? [];
    final qual = TextEditingController(text: '${profile['candidate'] is Map ? (profile['candidate'] as Map)['qualification'] ?? '' : ''}');
    final district = TextEditingController(text: '${profile['candidate'] is Map ? (profile['candidate'] as Map)['district'] ?? '' : ''}');
    final edu = <_EduDraft>[
      for (final e in ((profile['education'] as List?) ?? []).whereType<Map>())
        _EduDraft(
          degreeId: (e['degree_id'] as num?)?.toInt(),
          institute: TextEditingController(text: '${e['institute'] ?? ''}'),
          field: TextEditingController(text: '${e['field'] ?? ''}'),
          grade: TextEditingController(text: '${e['grade'] ?? ''}'),
        ),
    ];
    if (edu.isEmpty) edu.add(_EduDraft());
    final exp = <_ExpDraft>[
      for (final e in ((profile['experience'] as List?) ?? []).whereType<Map>())
        _ExpDraft(
          company: TextEditingController(text: '${e['company'] ?? ''}'),
          position: TextEditingController(text: '${e['position'] ?? ''}'),
          dates: TextEditingController(text: '${e['from_date'] ?? ''} – ${e['to_date'] ?? ''}'),
        ),
    ];
    if (exp.isEmpty) exp.add(_ExpDraft());
    final refs = <_RefDraft>[
      for (final e in ((profile['references'] as List?) ?? []).whereType<Map>())
        _RefDraft(
          name: TextEditingController(text: '${e['name'] ?? ''}'),
          company: TextEditingController(text: '${e['company'] ?? ''}'),
          phone: TextEditingController(text: '${e['phone'] ?? ''}'),
          feedback: TextEditingController(text: '${e['feedback'] ?? ''}'),
        ),
    ];
    if (refs.isEmpty) refs.add(_RefDraft());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Profile · ${c['name']}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: qual, decoration: const InputDecoration(labelText: 'Qualification')),
                  TextField(controller: district, decoration: const InputDecoration(labelText: 'District')),
                  const SizedBox(height: 12),
                  const Text('Education', style: TextStyle(fontWeight: FontWeight.w700)),
                  for (var i = 0; i < edu.length; i++) ...[
                    DropdownButtonFormField<int>(
                      value: edu[i].degreeId,
                      decoration: const InputDecoration(labelText: 'Degree'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        ...degrees.whereType<Map>().map((d) {
                          final did = (d['id'] as num?)?.toInt();
                          return DropdownMenuItem(value: did, child: Text('${d['name']}'));
                        }),
                      ],
                      onChanged: (v) => setLocal(() => edu[i].degreeId = v),
                    ),
                    TextField(controller: edu[i].institute, decoration: const InputDecoration(labelText: 'Institute')),
                    TextField(controller: edu[i].field, decoration: const InputDecoration(labelText: 'Field')),
                    TextField(controller: edu[i].grade, decoration: const InputDecoration(labelText: 'Grade')),
                  ],
                  TextButton(onPressed: () => setLocal(() => edu.add(_EduDraft())), child: const Text('+ Education')),
                  const SizedBox(height: 8),
                  const Text('Experience', style: TextStyle(fontWeight: FontWeight.w700)),
                  for (final e in exp) ...[
                    TextField(controller: e.company, decoration: const InputDecoration(labelText: 'Company')),
                    TextField(controller: e.position, decoration: const InputDecoration(labelText: 'Position')),
                    TextField(controller: e.dates, decoration: const InputDecoration(labelText: 'From – To')),
                  ],
                  TextButton(onPressed: () => setLocal(() => exp.add(_ExpDraft())), child: const Text('+ Experience')),
                  const SizedBox(height: 8),
                  const Text('References', style: TextStyle(fontWeight: FontWeight.w700)),
                  for (final r in refs) ...[
                    TextField(controller: r.name, decoration: const InputDecoration(labelText: 'Name')),
                    TextField(controller: r.company, decoration: const InputDecoration(labelText: 'Company')),
                    TextField(controller: r.phone, decoration: const InputDecoration(labelText: 'Phone')),
                    TextField(controller: r.feedback, decoration: const InputDecoration(labelText: 'Feedback')),
                  ],
                  TextButton(onPressed: () => setLocal(() => refs.add(_RefDraft())), child: const Text('+ Reference')),
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
    if (ok != true) return;
    final err = await _state.saveCandidateProfile(id, {
      'qualification': qual.text.trim(),
      'district': district.text.trim(),
      'education': edu
          .map((e) => {
                'degree_id': e.degreeId,
                'institute': e.institute.text.trim(),
                'field': e.field.text.trim(),
                'grade': e.grade.text.trim(),
              })
          .toList(),
      'experience': exp.map((e) {
        final parts = e.dates.text.split('–');
        return {
          'company': e.company.text.trim(),
          'position': e.position.text.trim(),
          'from_date': parts.isNotEmpty ? parts.first.trim() : '',
          'to_date': parts.length > 1 ? parts.last.trim() : '',
        };
      }).toList(),
      'references': refs
          .where((r) => r.name.text.trim().isNotEmpty)
          .map((r) => {
                'name': r.name.text.trim(),
                'company': r.company.text.trim(),
                'phone': r.phone.text.trim(),
                'feedback': r.feedback.text.trim(),
              })
          .toList(),
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidate profile saved')));
    }
  }

  Future<void> _referenceNote(Map<String, dynamic> c) async {
    final remarks = TextEditingController(text: '${c['ref_remarks'] ?? c['remarks'] ?? ''}');
    var advance = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Reference check · ${c['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: remarks,
                decoration: const InputDecoration(labelText: 'Reference notes / outcome'),
                maxLines: 4,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pass & move to Offer'),
                value: advance,
                onChanged: (v) => setLocal(() => advance = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final status = advance ? 3 : (c['status'] as num?)?.toInt() ?? 2;
    final err = await _state.moveStatus(
      (c['id'] as num).toInt(),
      status,
      remarks: remarks.text.trim(),
      refRemarks: remarks.text.trim(),
    );
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _hireCandidate(Map<String, dynamic> c) async {
    final user = TextEditingController();
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hire · ${c['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Creates an employee record and marks the candidate Hired.'),
            const SizedBox(height: 12),
            TextField(controller: user, decoration: const InputDecoration(labelText: 'Login username (optional)')),
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Employee code (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hire')),
        ],
      ),
    );
    if (ok != true) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _state.hireCandidate(
      (c['id'] as num).toInt(),
      body: {
        if (user.text.trim().isNotEmpty) 'user_name': user.text.trim(),
        if (code.text.trim().isNotEmpty) 'employee_code': code.text.trim(),
      },
    );
    if (!mounted) return;
    if (result != null && result.startsWith('HIRED_OK|')) {
      final parts = result.split('|');
      messenger.showSnackBar(SnackBar(
        content: Text('Hired. Login: ${parts[1]}  Temp password: ${parts[2]}'),
        duration: const Duration(seconds: 8),
      ));
    } else if (result != null) {
      messenger.showSnackBar(SnackBar(content: Text(result)));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Candidate hired as employee')));
    }
  }

  Widget _pipeline() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in _stages)
            Container(
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
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
                      Icon(Icons.circle, size: 10, color: s.$3),
                      const SizedBox(width: 6),
                      Text(s.$1, style: TextStyle(fontWeight: FontWeight.w800, color: HrUi.label(context))),
                      const Spacer(),
                      Text('${_state.byStage(s.$1).length}',
                          style: TextStyle(color: HrUi.muted(context), fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._state.byStage(s.$1).map((c) => _candCard(c, s.$2)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _candCard(Map<String, dynamic> c, int currentStatus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${c['job_title'] ?? '—'}', style: TextStyle(fontSize: 11, color: HrUi.muted(context))),
            if ('${c['email']}'.isNotEmpty)
              Text('${c['email']}', style: TextStyle(fontSize: 11, color: HrUi.muted(context))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                if (currentStatus >= 0 && currentStatus < 3)
                  TextButton(
                    onPressed: () async {
                      final err = await _state.moveStatus((c['id'] as num).toInt(), currentStatus + 1);
                      if (mounted && err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                      }
                    },
                    child: const Text('Advance →'),
                  ),
                if (currentStatus == 3)
                  TextButton(
                    onPressed: () => _hireCandidate(c),
                    child: const Text('Hire'),
                  ),
                if (currentStatus >= 0 && currentStatus < 4)
                  TextButton(
                    onPressed: () async {
                      await _state.moveStatus((c['id'] as num).toInt(), -1);
                    },
                    child: Text('Reject', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_state.jobs.isEmpty)
          Text('No job openings yet.', style: TextStyle(color: HrUi.muted(context)))
        else
          ..._state.jobs.map((j) => ListTile(
                title: Text('${j['title']}'),
                subtitle: Text(
                    '${j['status_label']} · Vacancies: ${j['vacancies']} · ${j['experience'] ?? ''}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final err = await _state.deleteJob((j['id'] as num).toInt());
                    if (mounted && err != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              )),
      ],
    );
  }

  Future<void> _addCandidate() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final exp = TextEditingController();
    int? jobId;
    final jobs = (_state.options['jobs'] as List?) ?? [];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add Candidate'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: exp, decoration: const InputDecoration(labelText: 'Experience')),
                DropdownButtonFormField<int>(
                  value: jobId,
                  decoration: const InputDecoration(labelText: 'Job'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    ...jobs.whereType<Map>().map((j) {
                      final id = (j['id'] as num?)?.toInt();
                      return DropdownMenuItem(value: id, child: Text('${j['name']}'));
                    }),
                  ],
                  onChanged: (v) => setLocal(() => jobId = v),
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
    if (ok != true || name.text.trim().isEmpty) return;
    final err = await _state.saveCandidate({
      'name': name.text.trim(),
      'email': email.text.trim(),
      'phone': phone.text.trim(),
      'total_experience': exp.text.trim(),
      'job_id': jobId,
      'status': 0,
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _addJob() async {
    final title = TextEditingController();
    final vacancies = TextEditingController(text: '1');
    final exp = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Job'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title *')),
            TextField(
              controller: vacancies,
              decoration: const InputDecoration(labelText: 'Vacancies'),
              keyboardType: TextInputType.number,
            ),
            TextField(controller: exp, decoration: const InputDecoration(labelText: 'Experience')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    final err = await _state.saveJob({
      'title': title.text.trim(),
      'vacancies': int.tryParse(vacancies.text) ?? 1,
      'experience': exp.text.trim(),
      'status': 1,
    });
    if (mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _EduDraft {
  _EduDraft({this.degreeId, TextEditingController? institute, TextEditingController? field, TextEditingController? grade})
      : institute = institute ?? TextEditingController(),
        field = field ?? TextEditingController(),
        grade = grade ?? TextEditingController();
  int? degreeId;
  final TextEditingController institute;
  final TextEditingController field;
  final TextEditingController grade;
}

class _ExpDraft {
  _ExpDraft({TextEditingController? company, TextEditingController? position, TextEditingController? dates})
      : company = company ?? TextEditingController(),
        position = position ?? TextEditingController(),
        dates = dates ?? TextEditingController();
  final TextEditingController company;
  final TextEditingController position;
  final TextEditingController dates;
}

class _RefDraft {
  _RefDraft({
    TextEditingController? name,
    TextEditingController? company,
    TextEditingController? phone,
    TextEditingController? feedback,
  })  : name = name ?? TextEditingController(),
        company = company ?? TextEditingController(),
        phone = phone ?? TextEditingController(),
        feedback = feedback ?? TextEditingController();
  final TextEditingController name;
  final TextEditingController company;
  final TextEditingController phone;
  final TextEditingController feedback;
}
