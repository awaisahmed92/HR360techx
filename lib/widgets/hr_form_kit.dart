import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';

/// ERP form + grid tokens — all accents come from [HrTheme] (app-wide).
class HrUi {
  static const Color statusPending = Color(0xFFE8A838);
  static const double formMaxWidth = 920;
  static const double labelWidth = 200;

  static bool isDark(BuildContext context) => HrTheme.isDark(context);

  static Color brand(BuildContext c) => HrTheme.brand(c);

  static Color pageBg(BuildContext c) =>
      isDark(c) ? AppTheme.darkBg : const Color(0xFFF3F1EE);

  static Color card(BuildContext c) => HrTheme.card(c);

  static Color fieldBg(BuildContext c) =>
      isDark(c) ? AppTheme.darkSurface : const Color(0xFFF5F5F5);

  static Color border(BuildContext c) =>
      isDark(c) ? AppTheme.darkBorder : const Color(0xFFE5E0D8);

  static Color label(BuildContext c) => HrTheme.text(c);

  static Color muted(BuildContext c) => HrTheme.textSecondary(c);

  static Color sectionTitle(BuildContext c) => HrTheme.heading(c);

  static Color header(BuildContext c) => HrTheme.header(c);

  static Color onHeader(BuildContext c) => HrTheme.onHeader(c);
}

class HrFormShell extends StatelessWidget {
  const HrFormShell({
    super.key,
    required this.moduleTitle,
    required this.moduleIcon,
    required this.formTitle,
    required this.onBack,
    required this.child,
    this.footer,
  });

  final String moduleTitle;
  final IconData moduleIcon;
  final String formTitle;
  final VoidCallback onBack;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Row(
            children: [
              Icon(moduleIcon, size: 18, color: HrUi.sectionTitle(context)),
              const SizedBox(width: 8),
              Text(
                moduleTitle,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: HrUi.sectionTitle(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: HrUi.formMaxWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: HrUi.card(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HrUi.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: HrUi.label(context),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        formTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.libreBaskerville(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: HrUi.sectionTitle(context),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: HrUi.border(context)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
                      child: child,
                    ),
                    if (footer != null) ...[
                      Divider(height: 1, color: HrUi.border(context)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
                        child: footer!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HrFormSection extends StatelessWidget {
  const HrFormSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.libreBaskerville(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: HrUi.sectionTitle(context),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class HrFormRow extends StatelessWidget {
  const HrFormRow({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.showInfo = true,
  });

  final String label;
  final Widget child;
  final bool required;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = !c.maxWidth.isFinite || c.maxWidth < 340;
          final labelWidget = SizedBox(
            width: narrow ? null : HrUi.labelWidth,
            child: Row(
              mainAxisAlignment: narrow ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: HrUi.label(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (required)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    textAlign: narrow ? TextAlign.left : TextAlign.right,
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.info_outline, size: 14, color: HrUi.muted(context)),
                ],
              ],
            ),
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                labelWidget,
                const SizedBox(height: 6),
                child,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              labelWidget,
              const SizedBox(width: 16),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

InputDecoration hrFieldDecoration(
  BuildContext context, {
  String? hint,
  Widget? suffix,
}) {
  final muted = HrUi.muted(context);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: muted, fontSize: 13),
    filled: true,
    fillColor: HrUi.fieldBg(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: HrUi.header(context), width: 1.2),
    ),
    suffixIcon: suffix,
    suffixIconColor: muted,
  );
}

TextStyle hrFieldTextStyle(BuildContext context) => GoogleFonts.inter(
      color: HrUi.label(context),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

/// Dropdown that keeps selected text visible in light + dark themes.
class HrDropdown<T> extends StatelessWidget {
  const HrDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final textColor = HrUi.label(context);
    // Only use value if it exists in items — avoids blank selection.
    final safeValue = items.any((i) => i.value == value) ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue,
      isExpanded: true,
      dropdownColor: HrUi.card(context),
      iconEnabledColor: HrUi.muted(context),
      style: GoogleFonts.inter(color: textColor, fontSize: 14),
      decoration: hrFieldDecoration(context, hint: hint),
      hint: hint == null
          ? null
          : Text(hint!, style: TextStyle(color: HrUi.muted(context), fontSize: 13)),
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle(
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              child: item.child,
            ),
          );
        }).toList();
      },
      items: items,
      onChanged: onChanged,
    );
  }
}

class HrDataGridPage extends StatelessWidget {
  const HrDataGridPage({
    super.key,
    required this.title,
    required this.icon,
    required this.columns,
    required this.rows,
    required this.onAdd,
    this.onRefresh,
    this.searchHint = 'Search',
    this.onSearch,
    this.emptyMessage = 'No records found.',
    this.page,
    this.totalPages,
    this.total,
    this.onPage,
  });

  final String title;
  final IconData icon;
  final List<String> columns;
  final List<List<Widget>> rows;
  final VoidCallback onAdd;
  final VoidCallback? onRefresh;
  final String searchHint;
  final ValueChanged<String>? onSearch;
  final String emptyMessage;
  final int? page;
  final int? totalPages;
  final int? total;
  final ValueChanged<int>? onPage;

  @override
  Widget build(BuildContext context) {
    final header = HrUi.header(context);
    final textPrimary = HrUi.label(context);

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: textPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: header,
                  foregroundColor: HrUi.onHeader(context),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('+ Add Record'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: Icon(Icons.refresh, color: HrUi.muted(context)),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 220,
                height: 38,
                child: TextField(
                  onChanged: onSearch,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: TextStyle(color: HrUi.muted(context)),
                    filled: true,
                    fillColor: HrUi.card(context),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    suffixIcon: Icon(Icons.search, size: 18, color: HrUi.muted(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: HrUi.border(context)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: HrUi.border(context)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: HrUi.card(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HrUi.border(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: HrFitDataTableHost(
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    dataTextStyle: GoogleFonts.inter(
                      fontSize: columns.length > 6 ? 12 : 13,
                      color: textPrimary,
                    ),
                  ),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(header),
                  headingTextStyle: GoogleFonts.inter(
                    color: HrUi.onHeader(context),
                    fontWeight: FontWeight.w700,
                    fontSize: columns.length > 6 ? 11 : 12,
                  ),
                  dataTextStyle: GoogleFonts.inter(
                    fontSize: columns.length > 6 ? 12 : 13,
                    color: textPrimary,
                  ),
                  columnSpacing: columns.length > 6 ? 14 : 22,
                  horizontalMargin: columns.length > 6 ? 10 : 14,
                  columns: columns
                      .map((c) => DataColumn(
                            label: Text(c, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  rows: rows.isEmpty
                      ? [
                          DataRow(
                            cells: List.generate(
                              columns.length,
                              (i) => DataCell(
                                i == 0
                                    ? Text(
                                        emptyMessage,
                                        style: TextStyle(color: HrUi.muted(context)),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ]
                      : [
                          for (final r in rows)
                            DataRow(
                              cells: r.map((w) => DataCell(w)).toList(),
                            ),
                        ],
                ),
              ),
            ),
          ),
          if (page != null &&
              totalPages != null &&
              total != null &&
              onPage != null &&
              totalPages! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Text(
                    'Page $page of $totalPages · $total records',
                    style: TextStyle(color: HrUi.muted(context), fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: page! > 1 ? () => onPage!(page! - 1) : null,
                    icon: Icon(Icons.chevron_left, color: header),
                  ),
                  IconButton(
                    onPressed:
                        page! < totalPages! ? () => onPage!(page! + 1) : null,
                    icon: Icon(Icons.chevron_right, color: header),
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
  const HrStatusPill({super.key, required this.label, this.pending = true});

  final String label;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final bg = pending ? HrUi.statusPending : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pending ? Icons.schedule : Icons.check_circle_outline,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fits [child] (usually a [DataTable]) to the content pane width.
/// Uses a visible scrollbar when columns still overflow.
class HrFitDataTableHost extends StatefulWidget {
  const HrFitDataTableHost({super.key, required this.child});

  final Widget child;

  @override
  State<HrFitDataTableHost> createState() => _HrFitDataTableHostState();
}

class _HrFitDataTableHostState extends State<HrFitDataTableHost> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        return Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          trackVisibility: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: w),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
