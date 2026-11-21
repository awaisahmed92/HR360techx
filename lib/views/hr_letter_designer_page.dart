import 'package:flutter/material.dart';

import '../core/letters/letter_state.dart';
import '../widgets/hr_record_kit.dart';

/// HR Letters Designer: brand-colored grid plus the tabbed letter editor.
class LetterDesignerScreen extends StatefulWidget {
  const LetterDesignerScreen({super.key, required this.state});

  final LetterState state;

  @override
  State<LetterDesignerScreen> createState() => _LetterDesignerScreenState();
}

class _LetterDesignerScreenState extends State<LetterDesignerScreen> {
  Map<String, dynamic>? _editing;
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    if (_editing != null || _creating) {
      return _LetterEditor(
        state: widget.state,
        existing: _editing,
        onClose: () => setState(() {
          _editing = null;
          _creating = false;
        }),
      );
    }
    return HrRecordGrid(
      rows: widget.state.types,
      addLabel: 'Add Record',
      onAdd: _addDialog,
      onOpen: (row) => setState(() => _editing = row),
      extraActions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: hrAccent(context), shape: const StadiumBorder()),
            onPressed: _sampleDialog,
            child: const Text('Sample HR Letters'),
          ),
        ),
      ],
      columns: [
        HrGridColumn('HR Letter Type', (r) => (r['letter_kind'] as num?)?.toInt() == 1 ? 'Job Candidate Letters' : 'Employee Letters', flex: 2),
        HrGridColumn('HR Letter Name', (r) => '${r['name']}', flex: 3),
        HrGridColumn('Category Name', (r) => '${r['category_name']}'.isEmpty ? '-' : '${r['category_name']}'),
        HrGridColumn(
          'Status',
          (r) => (r['status'] as num?)?.toInt() == 1 ? 'Active' : 'Inactive',
          cell: (r) => HrStatusPill((r['status'] as num?)?.toInt() == 1 ? 'Active' : 'Inactive'),
        ),
        HrGridColumn('', (_) => '', flex: 1, cell: (r) => _rowMenu(r)),
      ],
    );
  }

  Widget _rowMenu(Map<String, dynamic> row) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (action) => _act(action, row),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'view', child: Text('View HR Letter')),
          PopupMenuItem(value: 'edit', child: Text('Edit HR Letter')),
          PopupMenuItem(value: 'history', child: Text('Change History')),
          PopupMenuItem(value: 'status', child: Text('HR Letter Designer Status')),
          PopupMenuItem(value: 'copy', child: Text('Copy HR Letter')),
          PopupMenuItem(value: 'access', child: Text('HR Letter Type Access')),
          PopupMenuItem(value: 'print', child: Text('Print HR Letter')),
          PopupMenuItem(value: 'talk', child: Text('Discussions')),
          PopupMenuItem(value: 'delete', child: Text('Delete HR Letter')),
        ],
      ),
    );
  }

  Future<void> _act(String action, Map<String, dynamic> row) async {
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case 'edit':
        setState(() => _editing = row);
        return;
      case 'view':
      case 'print':
        await showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            insetPadding: const EdgeInsets.all(28),
            child: SizedBox(
              width: 820,
              height: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: const Color(0xFF111111),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Text('HR Letter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        _previewBtn(Icons.print_outlined, 'Print Report', const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _previewBtn(Icons.email_outlined, 'Email Report', const Color(0xFFE11D48)),
                        const SizedBox(width: 8),
                        _previewBtn(Icons.file_download_outlined, 'Export Report', const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _previewBtn(Icons.save_outlined, 'Save In My Reports', const Color(0xFF16A34A)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Text('${row['contents']}'.isEmpty ? 'This letter has no contents yet.' : '${row['contents']}', style: const TextStyle(height: 1.5, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      case 'status':
        final active = (row['status'] as num?)?.toInt() == 1;
        final err = await widget.state.saveType({..._bodyFrom(row), 'status': active ? 0 : 1}, id: (row['id'] as num).toInt());
        messenger.showSnackBar(SnackBar(content: Text(err ?? (active ? 'Marked inactive' : 'Marked active'))));
        return;
      case 'copy':
        final err = await widget.state.saveType({..._bodyFrom(row), 'name': '${row['name']} Copy'});
        messenger.showSnackBar(SnackBar(content: Text(err ?? 'Copied')));
        return;
      case 'delete':
        final err = await widget.state.deleteType((row['id'] as num).toInt());
        messenger.showSnackBar(SnackBar(content: Text(err ?? 'Deleted')));
        return;
      default:
        messenger.showSnackBar(SnackBar(content: Text('$action is stored with the letter. Open Edit to change it.')));
    }
  }

  Widget _previewBtn(IconData icon, String label, Color color) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: color, visualDensity: VisualDensity.compact),
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Map<String, dynamic> _bodyFrom(Map<String, dynamic> row) => {
        'name': row['name'],
        'category_id': row['category_id'],
        'letter_kind': row['letter_kind'],
        'contents': row['contents'],
        'header_html': row['header_html'],
        'footer_html': row['footer_html'],
        'custom_variables': row['custom_variables'] ?? [],
        'options': row['options'] ?? {},
        'logo_path': row['logo_path'],
        'footer_image_path': row['footer_image_path'],
        'reference_pattern': row['reference_pattern'],
        'status': row['status'],
      };

  Future<void> _sampleDialog() async {
    const samples = {
      'Job Confirmation Letter':
          'Dated: {{Current Date}}\n\nSubject: Employee Job Confirmation Letter\n\nDear {{Employee Full Name}},\n\nI am pleased to offer you the position of {{Job Title}}, beginning on {{Start Date}}; your starting salary will be {{Salary}}.\n\nSincerely,\nHR Manager',
      'Salary Certificate':
          'This is to certify that {{Employee Full Name}} is employed with {{Organization Name}} as of {{Current Date}}.\n\nHR Manager',
      'Salary Increment Notification':
          'Dear {{Employee Full Name}},\n\nYour salary has been revised effective {{Current Date}}.\n\nHR Manager',
    };
    var selected = samples.keys.first;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Sample HR Letters'),
          content: SizedBox(
            width: 420,
            child: DropdownButtonFormField<String>(
              value: selected,
              decoration: hrWaDecoration(),
              items: [for (final name in samples.keys) DropdownMenuItem(value: name, child: Text(name))],
              onChanged: (v) => setLocal(() => selected = v ?? selected),
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE85D4C)),
              onPressed: () {
                Navigator.pop(ctx);
                showDialog<void>(
                  context: context,
                  builder: (p) => AlertDialog(
                    title: Text(selected),
                    content: SizedBox(width: 520, child: SingleChildScrollView(child: Text(samples[selected]!))),
                    actions: [TextButton(onPressed: () => Navigator.pop(p), child: const Text('Close'))],
                  ),
                );
              },
              child: const Text('Preview'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: hrAccent(context)),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final err = await widget.state.saveType({
                  'name': selected,
                  'letter_kind': 0,
                  'contents': samples[selected],
                  'status': 1,
                  'custom_variables': const [],
                  'options': const {'page_size': 'A4'},
                });
                messenger.showSnackBar(SnackBar(content: Text(err ?? 'Sample added')));
              },
              child: const Text('Add Sample'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }

  Future<void> _addDialog() async {
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Center(child: Text('Add New HR Letter', style: TextStyle(fontWeight: FontWeight.w500))),
        content: SizedBox(
          width: 460,
          child: HrField(label: 'HR Letter Title:', required: true, child: HrWaInput(controller: title, hint: 'HR Letter Title')),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: hrAccent(context)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add HR Letter'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() {
        _creating = true;
        _editing = {'name': title.text.trim()};
      });
    }
  }
}

class _LetterEditor extends StatefulWidget {
  const _LetterEditor({required this.state, required this.onClose, this.existing});
  final LetterState state;
  final Map<String, dynamic>? existing;
  final VoidCallback onClose;

  @override
  State<_LetterEditor> createState() => _LetterEditorState();
}

class _LetterEditorState extends State<_LetterEditor> {
  int _tab = 0;
  late final TextEditingController _name;
  late final TextEditingController _contents;
  late final TextEditingController _header;
  late final TextEditingController _footer;
  late final TextEditingController _ref;
  late final TextEditingController _top;
  late final TextEditingController _bottom;
  late final TextEditingController _left;
  late final TextEditingController _right;
  late final TextEditingController _logo;
  late final TextEditingController _footerImage;
  int _kind = 0;
  int? _categoryId;
  String _orientation = 'Right to Left';
  String _status = 'Active';
  String _approval = 'Multi Level Approval';
  String _levels = 'Auto Approved';
  String _logoAlign = '-';
  String _footerAlign = '-';
  late final List<Map<String, String>> _vars;

  static const _tabs = ['HR Letter Info', 'Contents', 'Header & Footer', 'Custom Variables', 'Images'];
  static const _varTypes = ['Text Box', 'List Box', 'Checkbox', 'Date', 'Number'];
  static const _tokens = [
    'Organization Name',
    'Current Date',
    'Employee Preferred Name',
    'Employee Last Name',
    'Employee Full Name',
    'Employee Preferred Name Initial',
  ];
  static const _tables = [
    'Employee Qualifications',
    'Employee Work Experience',
    'Employee Memberships',
    'Employee Trainings',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? {};
    final opts = e['options'] is Map ? Map<String, dynamic>.from(e['options'] as Map) : <String, dynamic>{};
    _name = TextEditingController(text: '${e['name'] ?? ''}');
    _contents = TextEditingController(text: '${e['contents'] ?? ''}');
    _header = TextEditingController(text: '${e['header_html'] ?? ''}');
    _footer = TextEditingController(text: '${e['footer_html'] ?? ''}');
    _ref = TextEditingController(text: '${e['reference_pattern'] ?? '-'}');
    _top = TextEditingController(text: '${opts['margin_top'] ?? 0}');
    _bottom = TextEditingController(text: '${opts['margin_bottom'] ?? 0}');
    _left = TextEditingController(text: '${opts['margin_left'] ?? 0}');
    _right = TextEditingController(text: '${opts['margin_right'] ?? 0}');
    _logo = TextEditingController(text: '${e['logo_path'] ?? ''}');
    _footerImage = TextEditingController(text: '${e['footer_image_path'] ?? ''}');
    _kind = (e['letter_kind'] as num?)?.toInt() ?? 0;
    _categoryId = (e['category_id'] as num?)?.toInt();
    _orientation = '${opts['orientation'] ?? 'Right to Left'}';
    _status = (e['status'] as num?)?.toInt() == 0 ? 'Inactive' : 'Active';
    _approval = '${opts['approval_method'] ?? 'Multi Level Approval'}';
    _levels = opts['skip_approval'] == true ? 'Auto Approved' : '${opts['approval_levels'] ?? 'Auto Approved'}';
    _logoAlign = '${opts['logo_align'] ?? '-'}';
    _footerAlign = '${opts['footer_align'] ?? '-'}';
    final raw = (e['custom_variables'] as List?) ?? [];
    _vars = [
      for (final v in raw)
        if (v is Map)
          {
            'type': _varTypes.contains('${v['type']}') ? '${v['type']}' : 'Text Box',
            'title': '${v['label'] ?? v['title'] ?? ''}',
            'options': '${v['options'] ?? ''}',
            'color': '${v['color'] ?? ''}',
            'key': '${v['key'] ?? ''}',
          },
    ];
    while (_vars.length < 10) {
      final n = _vars.length + 1;
      _vars.add({'type': 'Text Box', 'title': 'Custom Variable #$n', 'options': '', 'color': '', 'key': 'CustomVariable$n'});
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _contents, _header, _footer, _ref, _top, _bottom, _left, _right, _logo, _footerImage]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('HR Letter Title is required')));
      return;
    }
    final id = widget.existing?['id'];
    final err = await widget.state.saveType({
      'name': _name.text.trim(),
      'category_id': _categoryId,
      'letter_kind': _kind,
      'contents': _contents.text,
      'header_html': _header.text,
      'footer_html': _footer.text,
      'reference_pattern': _ref.text.trim(),
      'logo_path': _logo.text.trim().isEmpty ? null : _logo.text.trim(),
      'footer_image_path': _footerImage.text.trim().isEmpty ? null : _footerImage.text.trim(),
      'status': _status == 'Active' ? 1 : 0,
      'custom_variables': [
        for (final v in _vars)
          {'key': v['key'], 'label': v['title'], 'type': v['type'], 'options': v['options'], 'color': v['color']},
      ],
      'options': {
        'margin_top': num.tryParse(_top.text) ?? 0,
        'margin_bottom': num.tryParse(_bottom.text) ?? 0,
        'margin_left': num.tryParse(_left.text) ?? 0,
        'margin_right': num.tryParse(_right.text) ?? 0,
        'orientation': _orientation,
        'approval_method': _approval,
        'approval_levels': _levels,
        'skip_approval': _levels == 'Auto Approved',
        'logo_align': _logoAlign,
        'footer_align': _footerAlign,
        'page_size': 'A4',
      },
    }, id: id is num ? id.toInt() : null);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Saved')));
    if (err == null) widget.onClose();
  }

  void _insert(String token) {
    _contents.text = '${_contents.text}{{$token}}';
    setState(() {});
  }

  void _wrap(String open, String close) {
    final text = _contents.text;
    final sel = _contents.selection;
    if (!sel.isValid || sel.start < 0) {
      _contents.text = '$text$open$close';
      return;
    }
    final selected = text.substring(sel.start, sel.end);
    _contents.text = text.replaceRange(sel.start, sel.end, '$open$selected$close');
    _contents.selection = TextSelection.collapsed(offset: sel.start + open.length + selected.length + close.length);
  }

  @override
  Widget build(BuildContext context) {
    final cats = ((widget.state.options['categories'] as List?) ?? []).whereType<Map>().toList();
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                Text(_name.text.isEmpty ? 'HR Letter' : _name.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kRecInk)),
                const Spacer(),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                InkWell(
                  onTap: () => setState(() => _tab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: _tab == i ? hrAccent(context) : Colors.transparent, width: 2)),
                    ),
                    child: Text(_tabs[i], style: TextStyle(color: _tab == i ? hrAccent(context) : kRecMuted, fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500)),
                  ),
                ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: switch (_tab) {
              0 => _info(cats),
              1 => _contentsTab(),
              2 => _headerFooter(),
              3 => _variables(),
              _ => _images(),
            },
          ),
        ],
      ),
    );
  }

  Widget _info(List<Map> cats) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const HrFormSection('HR Letter Info'),
        HrField(
          label: 'HR Letter Type',
          child: HrWaSelect(
            value: _kind == 1 ? 'Job Candidate Letters' : 'Employee Letters',
            items: const ['Employee Letters', 'Job Candidate Letters'],
            onChanged: (v) => setState(() => _kind = v == 'Job Candidate Letters' ? 1 : 0),
          ),
        ),
        HrField(label: 'HR Letter Title:', required: true, child: HrWaInput(controller: _name)),
        HrField(
          label: 'HR Letter Category',
          child: DropdownButtonFormField<int?>(
            value: _categoryId,
            decoration: hrWaDecoration(),
            items: [
              const DropdownMenuItem(value: null, child: Text('-')),
              for (final c in cats) DropdownMenuItem(value: (c['id'] as num).toInt(), child: Text('${c['name']}')),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ),
        HrField(label: 'Reference Number', child: HrWaInput(controller: _ref)),
        HrField(
          label: 'Orientation',
          child: HrWaSelect(value: _orientation, items: const ['Left to Right', 'Right to Left'], onChanged: (v) => setState(() => _orientation = v ?? _orientation)),
        ),
        HrField(
          label: 'Status',
          child: HrWaSelect(value: _status, items: const ['Active', 'Inactive'], onChanged: (v) => setState(() => _status = v ?? 'Active')),
        ),
        const HrFormSection('Margins'),
        HrField(label: 'Top', child: HrWaInput(controller: _top)),
        HrField(label: 'Bottom', child: HrWaInput(controller: _bottom)),
        HrField(label: 'Left', child: HrWaInput(controller: _left)),
        HrField(label: 'Right', child: HrWaInput(controller: _right)),
        const HrFormSection('Notifications'),
        const HrField(label: 'Notify Upon Submission', child: _FakeSelect('Select Employees')),
        const HrField(label: 'Notify Upon Approval', child: _FakeSelect('Select Employees')),
        const HrFormSection('HR Letter Approval'),
        HrField(
          label: 'Approval Method',
          child: HrWaSelect(value: _approval, items: const ['Multi Level Approval', 'Auto Approved', 'No Approval'], onChanged: (v) => setState(() => _approval = v ?? _approval)),
        ),
        HrField(
          label: 'Approval Levels',
          child: HrWaSelect(value: _levels, items: const ['Auto Approved', '1 Level', '2 Levels', '3 Levels'], onChanged: (v) => setState(() => _levels = v ?? _levels)),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: _save, child: const Text('Save')),
        ),
      ],
    );
  }

  Widget _contentsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Text('HR Letter Contents', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            _menu('Insert eSignature', const ['Sign here'], (v) => _insert('eSignature:$v')),
            const SizedBox(width: 8),
            _menu('Insert Data Table', _tables, _insert),
            const SizedBox(width: 8),
            _menu('Insert Variable', _tokens, _insert),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE6E8EE)), borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
          child: Row(
            children: [
              IconButton(tooltip: 'Bold', onPressed: () => _wrap('<b>', '</b>'), icon: const Icon(Icons.format_bold, size: 18)),
              IconButton(tooltip: 'Italic', onPressed: () => _wrap('<i>', '</i>'), icon: const Icon(Icons.format_italic, size: 18)),
              IconButton(tooltip: 'Underline', onPressed: () => _wrap('<u>', '</u>'), icon: const Icon(Icons.format_underlined, size: 18)),
              IconButton(tooltip: 'Bullet', onPressed: () => _wrap('\n• ', ''), icon: const Icon(Icons.format_list_bulleted, size: 18)),
              const Spacer(),
              const Text('HTML', style: TextStyle(color: kRecMuted, fontSize: 12)),
              const SizedBox(width: 8),
            ],
          ),
        ),
        TextField(
          controller: _contents,
          minLines: 16,
          maxLines: 24,
          decoration: const InputDecoration(border: OutlineInputBorder(), alignLabelWithHint: true),
        ),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: _save, child: const Text('Save'))),
      ],
    );
  }

  Widget _menu(String label, List<String> items, void Function(String) onPick) {
    return PopupMenuButton<String>(
      onSelected: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF4F5F8), borderRadius: BorderRadius.circular(6)),
        child: Text(label),
      ),
      itemBuilder: (context) => [for (final item in items) PopupMenuItem(value: item, child: Text(item))],
    );
  }

  Widget _headerFooter() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('HR Letter Header', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(controller: _header, minLines: 5, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder())),
        const SizedBox(height: 16),
        const Text('HR Letter Footer', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextField(controller: _footer, minLines: 5, maxLines: 8, decoration: const InputDecoration(border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Center(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: _save, child: const Text('Save'))),
      ],
    );
  }

  Widget _variables() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Custom Variables', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(hrAccent(context)),
            headingTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Variable Type')),
              DataColumn(label: Text('Variable Title')),
              DataColumn(label: Text('Options (Listbox / Checkbox)')),
              DataColumn(label: Text('Font Color')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (var i = 0; i < _vars.length; i++)
                DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(SizedBox(
                    width: 140,
                    child: HrWaSelect(value: _vars[i]['type'], items: _varTypes, onChanged: (v) => setState(() => _vars[i]['type'] = v ?? 'Text Box')),
                  )),
                  DataCell(SizedBox(width: 180, child: TextFormField(initialValue: _vars[i]['title'], decoration: hrWaDecoration(), onChanged: (v) => _vars[i]['title'] = v))),
                  DataCell(SizedBox(width: 160, child: TextFormField(initialValue: _vars[i]['options'], decoration: hrWaDecoration(hint: 'Options'), onChanged: (v) => _vars[i]['options'] = v))),
                  DataCell(SizedBox(width: 100, child: TextFormField(initialValue: _vars[i]['color'], decoration: hrWaDecoration(), onChanged: (v) => _vars[i]['color'] = v))),
                  DataCell(IconButton(onPressed: () => setState(() => _vars.removeAt(i)), icon: const Icon(Icons.close, size: 16))),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: _save, child: const Text('Save'))),
      ],
    );
  }

  Widget _images() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('HR Letter Logo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: () {}, child: const Text('Upload Logo')),
        ),
        HrField(
          label: 'Header Logo Alignment',
          child: HrWaSelect(value: _logoAlign, items: const ['-', 'Left', 'Center', 'Right'], onChanged: (v) => setState(() => _logoAlign = v ?? '-')),
        ),
        HrField(label: 'Logo path', child: HrWaInput(controller: _logo, hint: 'Stored path')),
        const SizedBox(height: 12),
        const Text('HR Letter Footer Image', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: () {}, child: const Text('Upload Footer Image')),
        ),
        HrField(
          label: 'Footer Image Alignment',
          child: HrWaSelect(value: _footerAlign, items: const ['-', 'Left', 'Center', 'Right'], onChanged: (v) => setState(() => _footerAlign = v ?? '-')),
        ),
        HrField(label: 'Footer image path', child: HrWaInput(controller: _footerImage)),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerRight, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: hrAccent(context)), onPressed: _save, child: const Text('Save'))),
      ],
    );
  }
}

class _FakeSelect extends StatelessWidget {
  const _FakeSelect(this.hint);
  final String hint;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: kRecField, borderRadius: BorderRadius.circular(10)),
      child: Text(hint, style: const TextStyle(color: kRecMuted)),
    );
  }
}
