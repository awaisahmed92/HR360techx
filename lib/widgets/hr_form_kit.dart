import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/hr_theme.dart';
import 'hr_grid_query.dart';

/// ERP form + grid tokens — all accents come from [HrTheme] (app-wide).
class HrUi {
  static const Color statusPending = Color(0xFFE8A838);
  static const double formMaxWidth = 920;
  static const double labelWidth = 200;

  static bool isDark(BuildContext context) => HrTheme.isDark(context);

  static Color brand(BuildContext c) => HrTheme.brand(c);

  static Color pageBg(BuildContext c) =>
      isDark(c) ? AppTheme.darkBg : AppTheme.lightBg;

  static Color card(BuildContext c) => HrTheme.card(c);

  static Color fieldBg(BuildContext c) =>
      isDark(c) ? AppTheme.darkSurface : Colors.white;

  static Color border(BuildContext c) =>
      isDark(c) ? AppTheme.darkBorder : AppTheme.lightBorder;

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
                style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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

TextStyle hrFieldTextStyle(BuildContext context) => GoogleFonts.plusJakartaSans(
      color: HrUi.label(context),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

class HrLookupOption<T> {
  const HrLookupOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.person = false,
  });

  final T? value;
  final String label;
  final String? subtitle;
  final bool person;
}

/// Searchable select that opens under the field. One row is highlighted.
/// Multi-select toggles rows. There is no checkbox dialog.
class HrLookupSelect<T> extends StatefulWidget {
  const HrLookupSelect({
    super.key,
    required this.options,
    this.value,
    this.values = const [],
    this.onChanged,
    this.onMultiChanged,
    this.multiple = false,
    this.hint = 'Select',
    this.allLabel,
    this.errorText,
  });

  final List<HrLookupOption<T>> options;
  final T? value;
  final List<T> values;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<T>>? onMultiChanged;
  final bool multiple;
  final String hint;
  final String? allLabel;
  final String? errorText;

  @override
  State<HrLookupSelect<T>> createState() => _HrLookupSelectState<T>();
}

class _HrLookupSelectState<T> extends State<HrLookupSelect<T>> {
  static const _highlight = Color(0xFFC6A98A);

  final _link = LayerLink();
  final _portal = OverlayPortalController();
  final _fieldKey = GlobalKey();
  final _text = TextEditingController();
  final _focus = FocusNode();
  double _width = 280;

  @override
  void initState() {
    super.initState();
    _text.text = _display;
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant HrLookupSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && _text.text != _display) {
      _text.text = _display;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  String _labelOf(T? value) {
    for (final option in widget.options) {
      if (option.value == value) return option.label;
    }
    return '';
  }

  String get _display {
    if (widget.multiple) {
      final names = [
        for (final value in widget.values)
          if (_labelOf(value).isNotEmpty) _labelOf(value),
      ];
      return names.join(', ');
    }
    return _labelOf(widget.value);
  }

  bool get _hasValue => widget.multiple ? widget.values.isNotEmpty : widget.value != null && _display.isNotEmpty;

  void _onFocus() {
    if (_focus.hasFocus) {
      _text.clear();
      _open();
    } else {
      _text.text = _display;
      if (_portal.isShowing) _portal.hide();
    }
    if (mounted) setState(() {});
  }

  void _open() {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) _width = box.size.width;
    if (!_portal.isShowing) _portal.show();
  }

  void _choose(HrLookupOption<T>? option) {
    if (widget.multiple) {
      if (option == null || option.value == null) {
        widget.onMultiChanged?.call([]);
      } else {
        final next = List<T>.from(widget.values);
        final value = option.value as T;
        if (next.contains(value)) {
          next.remove(value);
        } else {
          next.add(value);
        }
        widget.onMultiChanged?.call(next);
      }
      _focus.requestFocus();
      return;
    }
    widget.onChanged?.call(option?.value);
    _focus.unfocus();
  }

  void _clear() {
    if (widget.multiple) {
      widget.onMultiChanged?.call([]);
    } else {
      widget.onChanged?.call(null);
    }
    _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = _focus.hasFocus ? _text.text.trim().toLowerCase() : '';
    final rows = [
      if (widget.allLabel != null && (query.isEmpty || widget.allLabel!.toLowerCase().contains(query)))
        HrLookupOption<T>(value: null, label: widget.allLabel!),
      for (final option in widget.options)
        if (query.isEmpty ||
            option.label.toLowerCase().contains(query) ||
            (option.subtitle ?? '').toLowerCase().contains(query))
          option,
    ];

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _focus.unfocus(),
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 4),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 10,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: _width,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 280),
                        child: rows.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text('No matches', style: TextStyle(color: Color(0xFF6B7280))),
                              )
                            : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final option = rows[index];
                            final selected = widget.multiple
                                ? (option.value == null
                                    ? widget.values.isEmpty
                                    : widget.values.contains(option.value))
                                : option.value == widget.value;
                            return Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (_) => _choose(option.value == null && widget.allLabel == option.label ? null : option),
                              child: Container(
                                color: selected ? _highlight : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: option.person
                                    ? Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Color(0xFFE7E5E4),
                                            child: Icon(Icons.person, size: 18, color: Color(0xFF78716C)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(option.label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                                                if ((option.subtitle ?? '').isNotEmpty)
                                                  Text(option.subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(option.label, style: const TextStyle(color: Color(0xFF111827))),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _link,
        child: TextField(
          key: _fieldKey,
          controller: _text,
          focusNode: _focus,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            errorText: widget.errorText,
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: _hasValue
                ? IconButton(
                    tooltip: 'Clear',
                    onPressed: _clear,
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                  )
                : const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _highlight, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

String hrMenuLabel(Widget? child) {
  switch (child) {
    case null:
      return '';
    case Text text:
      return text.data ?? text.textSpan?.toPlainText() ?? '';
    case RichText text:
      return text.text.toPlainText();
    case Row row:
      return row.children.map(hrMenuLabel).where((part) => part.isNotEmpty).join(' ');
    case Column column:
      return column.children.map(hrMenuLabel).where((part) => part.isNotEmpty).join(' ');
    case Flex flex:
      return flex.children.map(hrMenuLabel).where((part) => part.isNotEmpty).join(' ');
    case Expanded expanded:
      return hrMenuLabel(expanded.child);
    case Flexible flexible:
      return hrMenuLabel(flexible.child);
    case Padding padding:
      return hrMenuLabel(padding.child);
    case Align align:
      return hrMenuLabel(align.child);
    case DefaultTextStyle style:
      return hrMenuLabel(style.child);
    default:
      return '';
  }
}

/// Searchable select used by every form dropdown.
class HrDropdown<T> extends StatelessWidget {
  const HrDropdown({
    super.key,
    this.value,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.hint,
    this.decoration,
    this.validator,
    this.isExpanded,
    this.dropdownColor,
    this.style,
    this.iconEnabledColor,
    this.selectedItemBuilder,
    this.icon,
    this.focusNode,
    this.autovalidateMode,
  });

  final T? value;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final InputDecoration? decoration;
  final FormFieldValidator<T>? validator;
  final bool? isExpanded;
  final Color? dropdownColor;
  final TextStyle? style;
  final Color? iconEnabledColor;
  final DropdownButtonBuilder? selectedItemBuilder;
  final Widget? icon;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final current = value ?? initialValue;
    final prompt = hint ?? decoration?.labelText ?? decoration?.hintText ?? 'Select';
    final options = [
      for (final item in items)
        if (item.enabled)
          HrLookupOption<T>(
            value: item.value,
            label: hrMenuLabel(item.child).isEmpty ? '${item.value ?? ''}' : hrMenuLabel(item.child),
          ),
    ];
    return FormField<T>(
      initialValue: current,
      validator: validator,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
      builder: (state) {
        return HrLookupSelect<T>(
          hint: prompt,
          value: current,
          options: options.where((o) => o.label != '—' && o.label != '-').toList(),
          errorText: state.errorText,
          onChanged: (next) {
            state.didChange(next);
            onChanged(next);
          },
        );
      },
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
    return HrGridQuery(
      rows: rows,
      onSearch: onSearch,
      builder: (context, shown, query, setLocal) {
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
                style: GoogleFonts.plusJakartaSans(
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
                onPressed: () {
                  setLocal('');
                  clearGridSearch(context);
                  onRefresh?.call();
                },
                icon: Icon(Icons.refresh, color: HrUi.muted(context)),
              ),
              const SizedBox(width: 8),
              HrSearchField(
                hint: searchHint,
                value: query,
                onChanged: setLocal,
              ),
            ],
          ),
          const SizedBox(height: 14),
          hrQueryBanner(context, query, shown.length, onClear: () => setLocal('')),
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
                    dataTextStyle: GoogleFonts.plusJakartaSans(
                      fontSize: columns.length > 6 ? 12 : 13,
                      color: textPrimary,
                    ),
                  ),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(header),
                  headingTextStyle: GoogleFonts.plusJakartaSans(
                    color: HrUi.onHeader(context),
                    fontWeight: FontWeight.w700,
                    fontSize: columns.length > 6 ? 11 : 12,
                  ),
                  dataTextStyle: GoogleFonts.plusJakartaSans(
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
                  rows: shown.isEmpty
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
                          for (final r in shown)
                            DataRow(
                              color: query.trim().isEmpty
                                  ? null
                                  : const WidgetStatePropertyAll(hrMatchRowColor),
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
      },
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
            style: GoogleFonts.plusJakartaSans(
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
