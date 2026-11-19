import 'package:flutter/material.dart';

/// Purple data grid and left-label forms used by Recruitment (WebHR layout).
const kRecPurple = Color(0xFF6D4AFF);
const kRecInk = Color(0xFF2C3140);
const kRecMuted = Color(0xFF8B919E);
const kRecField = Color(0xFFF2F3F7);

class HrGridColumn {
  const HrGridColumn(this.label, this.value, {this.flex = 2, this.cell});
  final String label;
  final String Function(Map<String, dynamic> row) value;
  final int flex;
  final Widget Function(Map<String, dynamic> row)? cell;
}

class HrRecordGrid extends StatefulWidget {
  const HrRecordGrid({
    super.key,
    required this.rows,
    required this.columns,
    required this.onAdd,
    this.onOpen,
    this.addLabel = 'Add Record',
    this.pageSize = 15,
    this.extraActions = const [],
  });

  final List<Map<String, dynamic>> rows;
  final List<HrGridColumn> columns;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic> row)? onOpen;
  final String addLabel;
  final int pageSize;
  final List<Widget> extraActions;

  @override
  State<HrRecordGrid> createState() => _HrRecordGridState();
}

class _HrRecordGridState extends State<HrRecordGrid> {
  final _search = TextEditingController();
  int _page = 0;
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_q.isEmpty) return widget.rows;
    final q = _q.toLowerCase();
    return widget.rows.where((row) {
      final blob = widget.columns.map((c) => c.value(row)).join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = _filtered;
    final pages = (all.length / widget.pageSize).ceil().clamp(1, 9999);
    if (_page >= pages) _page = pages - 1;
    final start = _page * widget.pageSize;
    final slice = all.skip(start).take(widget.pageSize).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEFF3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Spacer(),
                ...widget.extraActions,
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kRecPurple,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(widget.addLabel),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.filter_alt_outlined, color: kRecMuted)),
                IconButton(onPressed: () => setState(() { _q = ''; _search.clear(); _page = 0; }), icon: const Icon(Icons.refresh, color: kRecMuted)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 180,
                  height: 36,
                  child: TextField(
                    controller: _search,
                    onSubmitted: (v) => setState(() { _q = v.trim(); _page = 0; }),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF7F8FB),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: kRecPurple,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 46, child: Text('Number', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                for (final col in widget.columns)
                  Expanded(flex: col.flex, child: Text(col.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          Expanded(
            child: slice.isEmpty
                ? const Center(child: Text('No records', style: TextStyle(color: kRecMuted)))
                : ListView.separated(
                    itemCount: slice.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F1F5)),
                    itemBuilder: (context, i) {
                      final row = slice[i];
                      final n = start + i + 1;
                      return InkWell(
                        onTap: widget.onOpen == null ? null : () => widget.onOpen!(row),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 46, child: Text('$n', style: const TextStyle(color: kRecInk, fontSize: 13))),
                              for (final col in widget.columns)
                                Expanded(
                                  flex: col.flex,
                                  child: col.cell != null
                                      ? col.cell!(row)
                                      : Text(col.value(row), overflow: TextOverflow.ellipsis, style: const TextStyle(color: kRecInk, fontSize: 13)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Text('${all.length} Records', style: const TextStyle(color: kRecMuted, fontSize: 12)),
                const Spacer(),
                IconButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${_page + 1} of $pages', style: const TextStyle(fontSize: 12, color: kRecMuted)),
                IconButton(
                  onPressed: _page + 1 < pages ? () => setState(() => _page++) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HrStatusPill extends StatelessWidget {
  const HrStatusPill(this.label, {super.key, this.color = const Color(0xFF16A34A)});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class HrRecordForm extends StatelessWidget {
  const HrRecordForm({super.key, required this.title, required this.children, required this.onSave});
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
        children: [
          Center(child: Text(title, style: const TextStyle(fontSize: 22, color: Color(0xFFB0B6C2), fontWeight: FontWeight.w500))),
          const SizedBox(height: 18),
          ...children,
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kRecPurple, padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
              onPressed: onSave,
              child: const Text('Save Record'),
            ),
          ),
        ],
      ),
    );
  }
}

class HrFormSection extends StatelessWidget {
  const HrFormSection(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kRecInk)),
    );
  }
}

class HrField extends StatelessWidget {
  const HrField({super.key, required this.label, required this.child, this.required = false});
  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 210, child: Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13.5))),
          SizedBox(width: 360, child: child),
          if (required) const Padding(padding: EdgeInsets.only(left: 6), child: Text('*', style: TextStyle(color: Colors.red, fontSize: 16))),
          const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.info_outline, size: 16, color: Color(0xFFC4C8D2))),
        ],
      ),
    );
  }
}

InputDecoration hrWaDecoration({String? hint}) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: kRecField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );

class HrWaInput extends StatelessWidget {
  const HrWaInput({super.key, required this.controller, this.hint, this.maxLines = 1});
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller, maxLines: maxLines, decoration: hrWaDecoration(hint: hint));
  }
}

class HrWaSelect extends StatelessWidget {
  const HrWaSelect({super.key, required this.value, required this.items, required this.onChanged, this.hint});
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value != null && items.contains(value) ? value : null,
      isExpanded: true,
      decoration: hrWaDecoration(hint: hint),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}

class HrWaDate extends StatelessWidget {
  const HrWaDate({super.key, required this.controller});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: hrWaDecoration(hint: 'mm / dd / yyyy').copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16)),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: now);
        if (picked != null) {
          controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}

class HrWaSwitch extends StatelessWidget {
  const HrWaSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Switch(value: value, activeThumbColor: kRecPurple, onChanged: onChanged),
    );
  }
}

class HrRichNote extends StatelessWidget {
  const HrRichNote({super.key, required this.controller, this.hint});
  final TextEditingController controller;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 360,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFBFC),
            border: Border(top: BorderSide(color: Color(0xFFE6E8EE)), left: BorderSide(color: Color(0xFFE6E8EE)), right: BorderSide(color: Color(0xFFE6E8EE))),
          ),
          child: const Text('B  I  U   •   list', style: TextStyle(color: kRecMuted, fontSize: 12)),
        ),
        SizedBox(width: 360, child: TextField(controller: controller, minLines: 4, maxLines: 8, decoration: hrWaDecoration(hint: hint))),
      ],
    );
  }
}
