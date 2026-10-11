import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';

const hrMatchRowColor = Color(0xFFFFF3C4);

/// Top-bar search plus the grid's own box. Every word must appear in the row.
String hrSearchQuery(BuildContext context, [String local = '']) {
  final page = context.watch<AppState>().pageQuery.trim();
  final own = local.trim();
  if (own.isEmpty) return page;
  if (page.isEmpty) return own;
  return '$own $page';
}

bool hrMatchesQuery(String haystack, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final hay = haystack.toLowerCase();
  if (hay.contains(q)) return true;
  final parts = q.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  return parts.every(hay.contains);
}

String hrPlainText(Widget? widget) {
  switch (widget) {
    case null:
      return '';
    case Text text:
      return text.data ?? text.textSpan?.toPlainText() ?? '';
    case RichText text:
      return text.text.toPlainText();
    case Row row:
      return row.children.map(hrPlainText).join(' ');
    case Column column:
      return column.children.map(hrPlainText).join(' ');
    case Flex flex:
      return flex.children.map(hrPlainText).join(' ');
    case Wrap wrap:
      return wrap.children.map(hrPlainText).join(' ');
    case Padding padding:
      return hrPlainText(padding.child);
    case Align align:
      return hrPlainText(align.child);
    case SizedBox box:
      return hrPlainText(box.child);
    case Expanded expanded:
      return hrPlainText(expanded.child);
    case Flexible flexible:
      return hrPlainText(flexible.child);
    case InkWell well:
      return hrPlainText(well.child);
    case GestureDetector detector:
      return hrPlainText(detector.child);
    case Container container:
      return hrPlainText(container.child);
    case DefaultTextStyle style:
      return hrPlainText(style.child);
    case Tooltip tip:
      return '${tip.message ?? ''} ${hrPlainText(tip.child)}';
    case Icon _:
      return '';
    default:
      return '';
  }
}

List<DataRow> hrQueryRows(List<DataRow> rows, String query) {
  final q = query.trim();
  if (q.isEmpty) return rows;
  final matched = <DataRow>[];
  for (final row in rows) {
    final text = row.cells.map((cell) => hrPlainText(cell.child)).join(' ');
    if (!hrMatchesQuery(text, q)) continue;
    matched.add(DataRow(
      key: row.key,
      color: const WidgetStatePropertyAll(hrMatchRowColor),
      onSelectChanged: row.onSelectChanged,
      cells: row.cells,
    ));
  }
  return matched;
}

List<List<Widget>> hrFilterWidgetRows(List<List<Widget>> rows, String query) {
  final q = query.trim();
  if (q.isEmpty) return rows;
  return [
    for (final cells in rows)
      if (hrMatchesQuery(cells.map(hrPlainText).join(' '), q)) cells,
  ];
}

/// Keeps the grid search box and applies it together with the top-bar search.
class HrGridQuery extends StatefulWidget {
  const HrGridQuery({
    super.key,
    required this.rows,
    required this.builder,
    this.onSearch,
  });

  final List<List<Widget>> rows;
  final ValueChanged<String>? onSearch;
  final Widget Function(
    BuildContext context,
    List<List<Widget>> shown,
    String query,
    ValueChanged<String> setLocal,
  ) builder;

  @override
  State<HrGridQuery> createState() => _HrGridQueryState();
}

class _HrGridQueryState extends State<HrGridQuery> {
  String _local = '';

  @override
  Widget build(BuildContext context) {
    final query = hrSearchQuery(context, _local);
    final shown = hrFilterWidgetRows(widget.rows, query);
    return widget.builder(context, shown, query, (value) {
      setState(() => _local = value);
      widget.onSearch?.call(value);
    });
  }
}

Widget hrQueryBanner(String query, int count) {
  final q = query.trim();
  if (q.isEmpty) return const SizedBox.shrink();
  final label = count == 0
      ? 'No rows match "$q".'
      : '$count highlighted ${count == 1 ? 'row' : 'rows'} for "$q".';
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hrMatchRowColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5D36A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 16, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E), fontSize: 12.5),
            ),
          ),
        ],
      ),
    ),
  );
}
