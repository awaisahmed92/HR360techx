import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/hr_theme.dart';
import 'hr_form_kit.dart';

/// Shared text field — width/colors come from [HrUi] / [HrTheme] globally.
class HrTextField extends StatelessWidget {
  const HrTextField({
    super.key,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      style: hrFieldTextStyle(context),
      decoration: hrFieldDecoration(context, hint: hint),
    );
  }
}

/// Alias of [HrDropdown] for SelectBox naming consistency.
typedef HrSelectBox<T> = HrDropdown<T>;

/// Multi-select employee / option picker (chip style).
class HrMultiSelect<T> extends StatelessWidget {
  const HrMultiSelect({
    super.key,
    required this.items,
    required this.values,
    required this.onChanged,
    required this.labelOf,
    this.hint = 'Select…',
  });

  final List<T> items;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final String Function(T) labelOf;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final next = await showDialog<List<T>>(
          context: context,
          builder: (ctx) => _MultiSelectDialog<T>(
            items: items,
            initial: List<T>.from(values),
            labelOf: labelOf,
          ),
        );
        if (next != null) onChanged(next);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: hrFieldDecoration(context, hint: hint),
        child: values.isEmpty
            ? Text(hint, style: TextStyle(color: HrUi.muted(context), fontSize: 13))
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final v in values)
                    Chip(
                      label: Text(labelOf(v), style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: HrTheme.brandSoft(context),
                      side: BorderSide.none,
                      deleteIconColor: HrTheme.brand(context),
                      onDeleted: () {
                        final copy = List<T>.from(values)..remove(v);
                        onChanged(copy);
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class _MultiSelectDialog<T> extends StatefulWidget {
  const _MultiSelectDialog({
    required this.items,
    required this.initial,
    required this.labelOf,
  });

  final List<T> items;
  final List<T> initial;
  final String Function(T) labelOf;

  @override
  State<_MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<_MultiSelectDialog<T>> {
  late List<T> _selected;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      if (_q.trim().isEmpty) return true;
      return widget.labelOf(i).toLowerCase().contains(_q.toLowerCase());
    }).toList();

    return AlertDialog(
      backgroundColor: HrUi.card(context),
      title: Text('Select', style: TextStyle(color: HrUi.label(context))),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _q = v),
              style: hrFieldTextStyle(context),
              decoration: hrFieldDecoration(context, hint: 'Search'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final checked = _selected.contains(item);
                  return CheckboxListTile(
                    value: checked,
                    activeColor: HrTheme.brand(context),
                    title: Text(widget.labelOf(item),
                        style: TextStyle(color: HrUi.label(context), fontSize: 13)),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(item);
                        } else {
                          _selected.remove(item);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: HrTheme.filledButton(context),
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Search filter bar used above grids.
class HrSearchFilter extends StatelessWidget {
  const HrSearchFilter({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.width = 240,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 38,
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: HrUi.label(context), fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: HrTheme.brand(context), width: 1.2),
          ),
        ),
      ),
    );
  }
}

/// Theme-aware pagination strip.
class HrPagination extends StatelessWidget {
  const HrPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
    this.perPage = 20,
  });

  final int page;
  final int totalPages;
  final int total;
  final int perPage;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '$total record${total == 1 ? '' : 's'}',
          style: TextStyle(color: HrUi.muted(context), fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            'Page $page of $totalPages · $total records',
            style: TextStyle(color: HrUi.muted(context), fontSize: 12),
          ),
          const Spacer(),
          IconButton(
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: HrTheme.brand(context),
          ),
          IconButton(
            onPressed: page < totalPages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: HrTheme.brand(context),
          ),
        ],
      ),
    );
  }
}

class HrToggleRow extends StatelessWidget {
  const HrToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showInfo = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    return HrFormRow(
      label: label,
      showInfo: showInfo,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Switch.adaptive(
          value: value,
          activeColor: HrTheme.brand(context),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Settings shell matching WebHR Approvals / Notifications layout.
class HrSettingsShell extends StatelessWidget {
  const HrSettingsShell({
    super.key,
    required this.title,
    required this.navItems,
    required this.selectedNav,
    required this.onNav,
    required this.child,
    this.onSave,
    this.saveLabel = 'Save Settings',
  });

  final String title;
  final List<String> navItems;
  final String selectedNav;
  final ValueChanged<String> onNav;
  final Widget child;
  final VoidCallback? onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    final brand = HrTheme.brand(context);
    final onBrand = HrTheme.onBrand(context);

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        children: [
          Text(
            title,
            style: GoogleFonts.libreBaskerville(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: HrTheme.heading(context),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: HrUi.card(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: HrUi.border(context)),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 720;
                final menu = Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in navItems)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Material(
                            color: item == selectedNav ? brand : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              onTap: () => onNav(item),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                child: Text(
                                  item,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: item == selectedNav
                                        ? onBrand
                                        : HrUi.label(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
                final body = Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedNav,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: HrUi.label(context),
                        ),
                      ),
                      const SizedBox(height: 22),
                      child,
                      if (onSave != null) ...[
                        const SizedBox(height: 24),
                        FilledButton(
                          style: HrTheme.filledButton(context),
                          onPressed: onSave,
                          child: Text(saveLabel),
                        ),
                      ],
                    ],
                  ),
                );
                if (wide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 220, child: menu),
                        VerticalDivider(width: 1, color: HrUi.border(context)),
                        Expanded(child: body),
                      ],
                    ),
                  );
                }
                return Column(children: [menu, Divider(height: 1, color: HrUi.border(context)), body]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
