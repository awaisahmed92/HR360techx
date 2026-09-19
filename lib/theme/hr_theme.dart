import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_state.dart';
import 'app_theme.dart';

/// **Single app-wide theme API** — use this everywhere (modules, forms, grids).
///
/// Choosing a color on the Themes page updates [AppState.brandColor], which
/// rebuilds [MaterialApp] and every call to [HrTheme.brand] / [HrTheme.header].
///
/// ```dart
/// color: HrTheme.brand(context)
/// backgroundColor: HrTheme.header(context)
/// gradient: HrTheme.gradient(context)
/// ```
class HrTheme {
  HrTheme._();

  // ── Brand accent (selected theme color) ──────────────────────────

  /// Selected theme color (menu, buttons, grid headers, form accents).
  static Color brand(BuildContext context) {
    // Prefer live AppState so widgets rebuild immediately on theme pick.
    try {
      return context.watch<AppState>().brandColor;
    } catch (_) {
      return Theme.of(context).colorScheme.primary;
    }
  }

  /// Contrast text/icons on [brand] / [header] backgrounds.
  static Color onBrand(BuildContext context) {
    final b = brand(context);
    return b.computeLuminance() > 0.55 ? const Color(0xFF1F2937) : Colors.white;
  }

  /// Lighter tint of brand (chips, icons, soft highlights).
  static Color brandLight(BuildContext context) =>
      Color.lerp(brand(context), Colors.white, 0.28)!;

  /// Brand with opacity (selected rows, soft fills).
  static Color brandSoft(BuildContext context, [double opacity = 0.12]) =>
      brand(context).withOpacity(opacity);

  /// Primary gradient for CTAs / hero chips.
  static LinearGradient gradient(BuildContext context) =>
      AppTheme.brandGradient(brand(context));

  // ── Forms / grids aliases (same brand) ───────────────────────────

  /// Grid header bars + primary Save buttons.
  static Color header(BuildContext context) => brand(context);

  static Color onHeader(BuildContext context) => onBrand(context);

  /// Section / form headings.
  static Color heading(BuildContext context) {
    final b = brand(context);
    return isDark(context)
        ? Color.lerp(b, Colors.white, 0.35)!
        : Color.lerp(b, Colors.black, 0.22)!;
  }

  // ── Surfaces (light / dark shell) ────────────────────────────────

  static bool isDark(BuildContext context) {
    try {
      return context.watch<AppState>().isDarkMode;
    } catch (_) {
      return Theme.of(context).brightness == Brightness.dark;
    }
  }

  static Color pageBg(BuildContext c) =>
      isDark(c) ? AppTheme.darkBg : AppTheme.lightBg;

  static Color card(BuildContext c) =>
      isDark(c) ? AppTheme.darkCard : AppTheme.lightCard;

  static Color surface(BuildContext c) =>
      isDark(c) ? AppTheme.darkSurface : AppTheme.lightSurface;

  static Color border(BuildContext c) =>
      isDark(c) ? AppTheme.darkBorder : AppTheme.lightBorder;

  static Color text(BuildContext c) =>
      isDark(c) ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

  static Color textSecondary(BuildContext c) =>
      isDark(c) ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

  static Color textMuted(BuildContext c) =>
      isDark(c) ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;

  // ── Ready-made button styles ─────────────────────────────────────

  static ButtonStyle filledButton(BuildContext context) =>
      FilledButton.styleFrom(
        backgroundColor: header(context),
        foregroundColor: onHeader(context),
      );

  static ButtonStyle elevatedButton(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: brand(context),
        foregroundColor: onBrand(context),
      );
}
