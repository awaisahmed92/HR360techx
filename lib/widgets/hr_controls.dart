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

/// Searchable multi-select. Selected rows highlight. No checkbox dialog.
class HrMultiSelect<T> extends StatelessWidget {
  const HrMultiSelect({
    super.key,
    required this.items,
    required this.values,
    required this.onChanged,
    required this.labelOf,
    this.subtitleOf,
    this.person = false,
    this.hint = 'Select',
    this.allLabel,
  });

  final List<T> items;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final String Function(T) labelOf;
  final String Function(T)? subtitleOf;
  final bool person;
  final String hint;
  final String? allLabel;

  @override
  Widget build(BuildContext context) {
    return HrLookupSelect<T>(
      multiple: true,
      hint: hint,
      allLabel: allLabel,
      values: values,
      onMultiChanged: onChanged,
      options: [
        for (final item in items)
          HrLookupOption<T>(
            value: item,
            label: labelOf(item),
            subtitle: subtitleOf?.call(item),
            person: person,
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

/// Settings shell matching HR360tech Approvals / Notifications layout.
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
    final border = HrUi.border(context);

    final menu = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
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
                  splashColor: item == selectedNav
                      ? onBrand.withValues(alpha: 0.12)
                      : brand.withValues(alpha: 0.12),
                  highlightColor: item == selectedNav
                      ? onBrand.withValues(alpha: 0.08)
                      : brand.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Text(
                      item,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item == selectedNav ? onBrand : HrUi.label(context),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedNav,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: HrUi.label(context),
            ),
          ),
          const SizedBox(height: 22),
          child,
          if (onSave != null) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                style: HrTheme.filledButton(context),
                onPressed: onSave,
                child: Text(saveLabel),
              ),
            ),
          ],
        ],
      ),
    );

    return ColoredBox(
      color: HrUi.pageBg(context),
      child: LayoutBuilder(
        builder: (context, pageConstraints) {
          final wide = pageConstraints.maxWidth > 720;

          // Never use IntrinsicHeight + Expanded inside a scroll view — that
          // collapses the form to zero height on wide viewports (fields only
          // appear when DevTools shrinks width into the narrow Column layout).
          final cardChild = wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 220, child: menu),
                    Container(width: 1, color: border),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    menu,
                    Divider(height: 1, color: border),
                    body,
                  ],
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    border: Border.all(color: border),
                  ),
                  child: cardChild,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
