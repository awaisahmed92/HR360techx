import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_state.dart';
import '../core/recruitment/recruitment_state.dart';
import '../theme/hr_theme.dart';
import '../widgets/hr_record_kit.dart';
import 'recruitment_forms.dart';
import 'recruitment_view.dart';

/// Recruitment module laid out like the WebHR recruitment screens:
/// left menu, dashboard metric cards, and candidate search cards.
class RecruitmentModuleView extends StatefulWidget {
  const RecruitmentModuleView({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<RecruitmentModuleView> createState() => _RecruitmentModuleViewState();
}

class _NavItem {
  const _NavItem(this.tab, this.label, this.icon, {this.internalPosts = false});
  final int tab;
  final String label;
  final IconData icon;
  final bool internalPosts;
}

class _RecruitmentModuleViewState extends State<RecruitmentModuleView> {
  late final RecruitmentState _state;
  final _searchCtrl = TextEditingController();

  late int _navIndex;
  int _dashPane = 0;
  bool _internalOnly = false;
  int? _draftPost;
  int? _draftStage;
  bool _draftFav = false;
  bool _draftRej = false;
  String _appliedQ = '';
  int? _appliedPost;
  int? _appliedStage;
  bool _appliedFav = false;
  bool _appliedRej = false;
  String? _editor;
  Map<String, dynamic>? _editRow;

  static const _sideBg = Color(0xFFF4F5F8);
  static const _pageBg = Color(0xFFF7F8FB);

  Color get _accent => HrTheme.brand(context);
  static const _ink = Color(0xFF2A2E3A);
  static const _muted = Color(0xFF8B909E);

  static const _nav = [
    _NavItem(0, 'Dashboard', Icons.donut_small_outlined),
    _NavItem(4, 'Search Candidates', Icons.search),
    _NavItem(1, 'Job Requests', Icons.mail_outline),
    _NavItem(2, 'Job Posts', Icons.work_outline),
    _NavItem(2, 'Internal Job Posts', Icons.assignment_ind_outlined, internalPosts: true),
    _NavItem(4, 'Job Candidates', Icons.person_outline),
    _NavItem(6, 'Job Tests', Icons.fact_check_outlined),
    _NavItem(7, 'Job Evaluation', Icons.bar_chart_outlined),
    _NavItem(11, 'Jobs Portal', Icons.language_outlined),
    _NavItem(3, 'Screening', Icons.view_kanban_outlined),
    _NavItem(5, 'Interviews', Icons.event_available_outlined),
    _NavItem(8, 'Referrals', Icons.share_outlined),
    _NavItem(9, 'Tasks', Icons.task_alt_outlined),
    _NavItem(10, 'Reports', Icons.assessment_outlined),
    _NavItem(12, 'ATS', Icons.hub_outlined),
  ];

  static const _titles = {
    0: 'Recruitment Dashboard',
    1: 'Job Requests',
    2: 'Job Posts',
    3: 'Screening',
    4: 'Search Candidates',
    5: 'Interviews',
    6: 'Job Tests',
    7: 'Job Evaluation',
    8: 'Referrals',
    9: 'Tasks',
    10: 'Reports',
    11: 'Jobs Portal',
    12: 'ATS Integrations',
  };

  @override
  void initState() {
    super.initState();
    final start = widget.initialTab.clamp(0, 12);
    _state = RecruitmentState(context.read<AuthState>())..tab = start;
    final found = _nav.indexWhere((n) => n.tab == start && !n.internalPosts);
    _navIndex = found < 0 ? 0 : found;
    _internalOnly = _nav[_navIndex].internalPosts;
    WidgetsBinding.instance.addPostFrameCallback((_) => _state.load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _state.dispose();
    super.dispose();
  }

  void _openNav(int index) {
    final item = _nav[index];
    setState(() {
      _navIndex = index;
      _internalOnly = item.internalPosts;
      _editor = null;
      _editRow = null;
    });
    _state.setTab(item.tab);
  }

  void _openEditor(String kind, [Map<String, dynamic>? row]) {
    setState(() {
      _editor = kind;
      _editRow = row;
    });
  }

  Future<void> _saveRecord(String path, Map<String, dynamic> body) async {
    final messenger = ScaffoldMessenger.of(context);
    final err = await _state.postJson(path, body);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
    if (err == null) {
      setState(() {
        _editor = null;
        _editRow = null;
      });
    }
  }

  bool _navSelected(int index) => _navIndex == index;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return ColoredBox(
          color: _pageBg,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sidebar(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(),
                    if (_state.error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Text(_state.error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebar() {
    return Container(
      width: 228,
      color: _sideBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
            child: Text(
              'Recruitment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _accent),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                for (var i = 0; i < _nav.length; i++) _sideTile(i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideTile(int index) {
    final item = _nav[index];
    final on = _navSelected(index);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: on ? _accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _openNav(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: on ? Colors.white : const Color(0xFF6B7280)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                      color: on ? Colors.white : const Color(0xFF4B5160),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final title = _state.tab == 2 && _internalOnly
        ? 'Internal Job Posts'
        : (_titles[_state.tab] ?? 'Recruitment');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 14, 16, 14),
      child: Row(
        children: [
          Icon(_nav[_navIndex].icon, color: _accent, size: 22),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _ink)),
          const Spacer(),
          // Grids already have their own Add Record. Keep this only for list tabs.
          if (_editor == null && (_state.tab == 5 || _state.tab == 9))
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _accent, shape: const StadiumBorder()),
                onPressed: () {
                  if (_state.tab == 5) _editInterview();
                  else if (_state.tab == 9) _editTask();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Record'),
              ),
            ),
          IconButton(onPressed: () => _state.load(), icon: const Icon(Icons.refresh, color: _muted)),
        ],
      ),
    );
  }

  Widget _body() {
    if (_state.tab == 3) return const RecruitmentView(embedded: true);
    if (_state.busy && _state.posts.isEmpty && _state.dashboard.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_editor == 'request') {
      return JobRequestForm(
        row: _editRow,
        onSave: (body) => _saveRecord(
          _editRow == null ? '/recruitment/requisitions' : '/recruitment/requisitions/${_editRow!['id']}',
          body,
        ),
      );
    }
    if (_editor == 'post') {
      return JobPostForm(
        row: _editRow,
        internal: _internalOnly,
        onSave: (body) => _saveRecord(
          _editRow == null ? '/recruitment/posts' : '/recruitment/posts/${_editRow!['id']}',
          body,
        ),
      );
    }
    if (_editor == 'candidate') {
      return JobCandidateForm(
        posts: _state.posts,
        onSave: (body) => _saveRecord('/recruitment/candidates', body),
      );
    }
    if (_editor == 'test') {
      return JobTestForm(onSave: (body) => _saveRecord('/recruitment/tests', body));
    }
    return switch (_state.tab) {
      0 => _dashboard(),
      1 => _requestGrid(),
      2 => _postGrid(),
      4 => _nav[_navIndex].label == 'Job Candidates' ? _candidateGrid() : _searchCandidates(),
      5 => _recordList(_state.interviews, (r) => '${r['title']} — ${r['candidate_name']}', (r) => '${r['scheduled_at']} · ${r['mode']}', onEdit: _editInterview),
      6 => _testGrid(),
      7 => _evaluation(),
      8 => _recordList(_state.referrals, (r) => '${r['candidate_name']}', (r) => 'Referred by ${r['employee_name']} · ${r['post_title']}'),
      9 => _tasks(),
      10 => _reports(),
      11 => _portal(),
      12 => _ats(),
      _ => const SizedBox.shrink(),
    };
  }

  List<Map<String, dynamic>> get _visiblePosts {
    if (!_internalOnly) return _state.posts;
    return _state.posts.where((p) => (p['job_for'] as num?)?.toInt() == 1).toList();
  }

  Widget _requestGrid() {
    return HrRecordGrid(
      rows: _state.requisitions,
      onAdd: () => _openEditor('request'),
      onOpen: (row) => _openEditor('request', row),
      columns: [
        HrGridColumn('Job Title', (r) => '${r['job_title']}', flex: 3),
        HrGridColumn('Job Type', (r) => '${r['job_type']}'),
        HrGridColumn('No. of Positions', (r) => '${r['vacancies']}', flex: 1),
        HrGridColumn('Reference Number', (r) => '${r['reference_number'] ?? ''}'),
        HrGridColumn(
          'Approval Status',
          (r) => '${r['status_label']}',
          cell: (r) => HrStatusPill(
            '${r['status_label']}',
            color: '${r['status_label']}' == 'Approved' ? const Color(0xFF16A34A) : _accent,
          ),
        ),
        HrGridColumn('Status', (r) => '${r['status_label']}'.toLowerCase() == 'approved' ? 'approve' : '${r['status_label']}'),
      ],
    );
  }

  Widget _postGrid() {
    String detail(Map<String, dynamic> r, String key) {
      final d = r['details'];
      if (d is Map && d[key] != null) return '${d[key]}';
      return '';
    }

    return HrRecordGrid(
      rows: _visiblePosts,
      onAdd: () => _openEditor('post'),
      onOpen: (row) => _openEditor('post', row),
      columns: [
        HrGridColumn('Job Title', (r) => '${r['title']}', flex: 3),
        HrGridColumn('Job Field', (r) => detail(r, 'job_field')),
        HrGridColumn('Job Type', (r) => '${r['job_type']}'),
        HrGridColumn('No. of Positions', (r) => '${r['vacancies']}', flex: 1),
        HrGridColumn('Reference Number', (r) => '${r['reference_number'] ?? ''}'),
        HrGridColumn('City', (r) => detail(r, 'city')),
        HrGridColumn('Country', (r) => detail(r, 'country')),
        HrGridColumn('Closing Date', (r) => '${r['closing_date'] ?? '-'}'),
        HrGridColumn(
          'Status',
          (r) => '${r['status_label']}',
          cell: (r) => HrStatusPill('${r['status_label']}', color: _accent),
        ),
      ],
    );
  }

  Widget _candidateGrid() {
    final rows = _state.applications.isNotEmpty
        ? _state.applications
        : _state.candidates
            .map((c) => {
                  'candidate_name': c['name'],
                  'candidate_email': c['email'],
                  'candidate_phone': c['phone'],
                  'created_at': '',
                  'post_title': c['job_title'],
                })
            .toList();
    return HrRecordGrid(
      rows: rows,
      onAdd: () => _openEditor('candidate'),
      columns: [
        HrGridColumn('Candidate Name', (r) => '${r['candidate_name'] ?? r['name']}', flex: 3),
        HrGridColumn('Job Field', (r) => '${r['post_title'] ?? ''}'),
        HrGridColumn('Email Address', (r) => '${r['candidate_email'] ?? r['email'] ?? ''}', flex: 3),
        HrGridColumn('Mobile Number', (r) => '${r['candidate_phone'] ?? r['phone'] ?? ''}'),
        HrGridColumn('Applied On', (r) => '${r['created_at'] ?? ''}'.split(' ').first),
      ],
    );
  }

  Widget _testGrid() {
    return HrRecordGrid(
      rows: _state.tests,
      onAdd: () => _openEditor('test'),
      columns: [
        HrGridColumn('Test Title', (r) => '${r['title']}', flex: 3),
        HrGridColumn('Pass Score', (r) => '${r['pass_score']}'),
        HrGridColumn('Questions', (r) => '${(r['questions'] as List?)?.length ?? 0}'),
        HrGridColumn('Status', (r) => (r['status'] as num?)?.toInt() == 1 ? 'Active' : 'Inactive', cell: (r) => const HrStatusPill('Active')),
      ],
    );
  }

  Widget _dashboard() {
    final candidates = _state.candidates.length;
    final jobs = _state.posts.length;
    final open = _state.posts.where((p) => (p['status'] as num?)?.toInt() == 1).length;
    final closed = _state.posts.where((p) => (p['status'] as num?)?.toInt() == 2).length;
    final funnel = (_state.dashboard['funnel'] as List?) ?? [];
    final interviews = (_state.dashboard['interviews_week'] as List?) ?? [];
    final aging = (_state.dashboard['aging'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _dashTab('Dashboard', 0),
                  _dashTab('Recruitment Globe', 1),
                  _dashTab('Applicants Synopsis', 2),
                ],
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(18),
                child: switch (_dashPane) {
                  1 => _globePane(),
                  2 => _synopsis(funnel),
                  _ => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _stat('Candidate', '$candidates', Icons.groups_outlined, const Color(0xFF7C6BF2)),
                            _stat('Total Jobs', '$jobs', Icons.work_outline, const Color(0xFF2BB673)),
                            _stat('Open Job post', '$open', Icons.search, const Color(0xFFE0A100)),
                            _stat('Closed Job Post', '$closed', Icons.lock_outline, const Color(0xFF8B5CF6)),
                            _stat('Job Test', '${_state.tests.length}', Icons.task_alt_outlined, const Color(0xFF22A06B)),
                            _stat('Job Evaluation', '${_state.evaluations.length}', Icons.assignment_outlined, const Color(0xFFE11D48)),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _panel('What\'s New Around?', _state.posts.take(4).map((p) => '${p['title']}').toList())),
                            const SizedBox(width: 12),
                            Expanded(child: _panel('Activity Feed', aging.take(4).map((a) => a is Map ? '${a['candidate_name']} · ${a['post_title']}' : '').where((s) => s.isNotEmpty).toList())),
                            const SizedBox(width: 12),
                            Expanded(child: _panel('Hiring Calendar', interviews.take(4).map((a) => a is Map ? '${a['title']} · ${a['scheduled_at']}' : '').where((s) => s.isNotEmpty).toList())),
                          ],
                        ),
                      ],
                    ),
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dashTab(String label, int index) {
    final on = _dashPane == index;
    return InkWell(
      onTap: () => setState(() => _dashPane = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: on ? _accent : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
            color: on ? _accent : _muted,
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color tint) {
    return Container(
      width: 190,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF0F4)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: tint, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, List<String> lines) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 10),
          if (lines.isEmpty)
            const Text('Nothing new yet.', style: TextStyle(color: _muted))
          else
            ...lines.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(l, style: const TextStyle(color: Color(0xFF4B5160), fontSize: 13)),
                )),
        ],
      ),
    );
  }

  Widget _globePane() {
    final places = _state.posts.map((p) => '${p['locations'] ?? ''}'.trim()).where((s) => s.isNotEmpty).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Open roles by location', style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        const SizedBox(height: 12),
        if (places.isEmpty)
          const Text('No locations on job posts yet.', style: TextStyle(color: _muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: places.map((p) => Chip(label: Text(p))).toList(),
          ),
      ],
    );
  }

  Widget _synopsis(List funnel) {
    return Column(
      children: [
        for (final f in funnel.whereType<Map>())
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 110, child: Text('${f['label']}', style: const TextStyle(color: _ink))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: _bar(f['count']),
                      backgroundColor: const Color(0xFFEEF0F4),
                      color: _accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${f['count']}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }

  double _bar(dynamic count) {
    final n = (count as num?)?.toDouble() ?? 0;
    final maxN = _state.candidates.isEmpty ? 1.0 : _state.candidates.length.toDouble();
    return (n / maxN).clamp(0, 1);
  }

  Widget _searchCandidates() {
    final rows = _filteredApplicants();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: 420,
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _applySearchFilters(),
              decoration: InputDecoration(
                hintText: 'Search Candidates',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: _muted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE6E8EE))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Color(0xFFE6E8EE))),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 250, child: _filterColumn()),
                const SizedBox(width: 14),
                Expanded(child: _resultGrid(rows)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterColumn() {
    final stages = const ['Applied', 'Screening', 'Interview', 'Offer', 'Hired'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView(
        children: [
          const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6B46C1))),
          const SizedBox(height: 8),
          _filterMenu(
            'All Job Posts',
            _state.posts.map((p) => DropdownMenuItem<int?>(value: (p['id'] as num).toInt(), child: Text('${p['title']}'))).toList(),
            _draftPost,
            (v) => setState(() => _draftPost = v),
          ),
          _filterMenu(
            'All Application Stages',
            [
              for (var i = 0; i < stages.length; i++) DropdownMenuItem<int?>(value: i, child: Text(stages[i])),
            ],
            _draftStage,
            (v) => setState(() => _draftStage = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorite', style: TextStyle(fontSize: 13)),
            value: _draftFav,
            onChanged: (v) => setState(() => _draftFav = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rejected', style: TextStyle(fontSize: 13)),
            value: _draftRej,
            onChanged: (v) => setState(() => _draftRej = v),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _accent, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _applySearchFilters,
            icon: const Icon(Icons.filter_alt_outlined, size: 18),
            label: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _filterMenu(String hint, List<DropdownMenuItem<int?>> items, int? value, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<int?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF7F8FB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        hint: Text(hint, style: const TextStyle(fontSize: 13)),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(hint)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  void _applySearchFilters() {
    setState(() {
      _appliedQ = _searchCtrl.text.trim();
      _appliedPost = _draftPost;
      _appliedStage = _draftStage;
      _appliedFav = _draftFav;
      _appliedRej = _draftRej;
    });
  }

  List<Map<String, dynamic>> _filteredApplicants() {
    final source = _state.applications.isNotEmpty
        ? _state.applications
        : _state.candidates.map((c) => {
              'candidate_name': c['name'],
              'candidate_email': c['email'],
              'candidate_phone': c['phone'],
              'post_title': c['job_title'],
              'stage': c['status'],
              'status': c['status'],
              'is_favorite': false,
            }).toList();
    final q = _appliedQ.toLowerCase();
    return source.where((a) {
      if (_appliedPost != null && (a['post_id'] as num?)?.toInt() != _appliedPost) return false;
      if (_appliedStage != null && (a['stage'] as num?)?.toInt() != _appliedStage) return false;
      if (_appliedFav && a['is_favorite'] != true) return false;
      if (_appliedRej && (a['status'] as num?)?.toInt() != -1) return false;
      if (q.isEmpty) return true;
      final blob = '${a['candidate_name']} ${a['candidate_email']} ${a['candidate_phone']} ${a['post_title']}'.toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  Widget _resultGrid(List<Map<String, dynamic>> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Search Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6B46C1))),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('No candidates match these filters.', style: TextStyle(color: _muted)))
              : LayoutBuilder(
                  builder: (context, box) {
                    final two = box.maxWidth > 720;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: two ? 2 : 1,
                        mainAxisExtent: 118,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: rows.length,
                      itemBuilder: (context, i) => _candidateCard(rows[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _candidateCard(Map<String, dynamic> row) {
    final name = '${row['candidate_name'] ?? row['name'] ?? 'Candidate'}';
    final email = '${row['candidate_email'] ?? row['email'] ?? ''}';
    final phone = '${row['candidate_phone'] ?? row['phone'] ?? ''}';
    final stage = (row['stage'] as num?)?.toInt() ?? 0;
    final stageLabel = const ['Applied', 'Screening', 'Interview', 'Offer', 'Hired'][stage.clamp(0, 4)];
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0]).join().toUpperCase();
    final tint = _avatarColors[name.hashCode.abs() % _avatarColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: tint,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: _ink))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF2F80ED), borderRadius: BorderRadius.circular(10)),
                      child: Text(stageLabel, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
                if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12, color: _muted)),
                if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 12, color: _muted)),
                Text('${row['post_title'] ?? ''}', style: const TextStyle(fontSize: 12, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _avatarColors = [
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF14B8A6),
    Color(0xFF22C55E),
    Color(0xFFEAB308),
    Color(0xFF8B5CF6),
  ];

  Widget _recordList(
    List<Map<String, dynamic>> rows,
    String Function(Map<String, dynamic>) title,
    String Function(Map<String, dynamic>) subtitle, {
    void Function(Map<String, dynamic> row)? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: rows.isEmpty
          ? const Center(child: Text('No records yet.', style: TextStyle(color: _muted)))
          : ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final row = rows[i];
                return ListTile(
                  title: Text(title(row), style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
                  subtitle: Text(subtitle(row)),
                  trailing: onEdit == null
                      ? null
                      : IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => onEdit(row)),
                );
              },
            ),
    );
  }

  Widget _tasks() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView(
        children: [
          for (final t in _state.tasks)
            ListTile(
              title: Text('${t['title']}'),
              subtitle: Text('Due ${t['due_date']}'),
              trailing: (t['status'] as num?)?.toInt() == 0
                  ? TextButton(
                      onPressed: () => _state.postJson('/recruitment/tasks/${t['id']}/complete', {}),
                      child: const Text('Complete'),
                    )
                  : const Text('Done'),
            ),
        ],
      ),
    );
  }

  Widget _evaluation() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _panel('Scorecards', _state.evaluations.map((e) => '${e['title']}').toList()),
        const SizedBox(height: 12),
        _panel('Results', _state.evaluationResults.map((e) => '${e['candidate_name']} · ${e['total_score'] ?? '-'}').toList()),
      ],
    );
  }

  Widget _reports() {
    final pipeline = (_state.reports['pipeline'] as List?) ?? [];
    final source = (_state.reports['source'] as List?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _panel('Time to hire', ['${_state.reports['time_to_hire_days'] ?? 0} days average']),
        const SizedBox(height: 12),
        _panel('Pipeline', pipeline.whereType<Map>().map((p) => 'Stage ${p['stage']}: ${p['count']}').toList()),
        const SizedBox(height: 12),
        _panel('Source', source.whereType<Map>().map((p) => '${p['source']}: ${p['count']}').toList()),
      ],
    );
  }

  Widget _portal() {
    final brand = TextEditingController(text: '${_state.portalSettings['brand_name'] ?? ''}');
    final welcome = TextEditingController(text: '${_state.portalSettings['welcome_text'] ?? ''}');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand name')),
              TextField(controller: welcome, maxLines: 3, decoration: const InputDecoration(labelText: 'Welcome text')),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _accent),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final err = await _state.postJson('/recruitment/portal-settings', {
                      'enabled': true,
                      'brand_name': brand.text.trim(),
                      'welcome_text': welcome.text.trim(),
                    });
                    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
                  },
                  child: const Text('Save portal'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ats() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final p in ['workable', 'greenhouse', 'jazzhr'])
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _accent),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final err = await _state.postJson('/recruitment/ats/sync/$p', {});
                  messenger.showSnackBar(SnackBar(content: Text(err ?? 'Sync $p')));
                },
                child: Text('Sync $p'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _panel('Sync log', _state.atsLog.take(12).map((l) => '${l['provider']} · ${l['status']} · ${l['message']}').toList()),
      ],
    );
  }

  Future<void> _editInterview([Map<String, dynamic>? row]) async {
    final messenger = ScaffoldMessenger.of(context);
    final title = TextEditingController(text: '${row?['title'] ?? 'Interview'}');
    final appId = TextEditingController(text: '${row?['application_id'] ?? (_state.applications.isNotEmpty ? _state.applications.first['id'] : '')}');
    final when = TextEditingController(text: '${row?['scheduled_at'] ?? DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 16).replaceFirst('T', ' ')}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Interview'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: appId, decoration: const InputDecoration(labelText: 'Application ID')),
          TextField(controller: when, decoration: const InputDecoration(labelText: 'Scheduled at')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final path = row == null ? '/recruitment/interviews' : '/recruitment/interviews/${row['id']}';
    final err = await _state.postJson(path, {
      'title': title.text.trim(),
      'application_id': int.tryParse(appId.text) ?? 0,
      'scheduled_at': when.text.trim(),
      'mode': 'online',
    });
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
  }

  Future<void> _editTask() async {
    final messenger = ScaffoldMessenger.of(context);
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recruit task'),
        content: TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final err = await _state.postJson('/recruitment/tasks', {'title': title.text.trim()});
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
  }
}
