import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Fallback brand (Bright Navy Blue) — live brand comes from MaterialApp seed
  static const Color primary = Color(0xFF1E4B8C);
  static const Color primaryLight = Color(0xFF3B6FB0);
  static const Color primaryDark = Color(0xFF163A6E);
  static const Color accent = Color(0xFF7C3AED);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardHover = Color(0xFF26334D);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  static LinearGradient brandGradient(Color brand) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brand,
          Color.lerp(brand, Colors.black, 0.18)!,
        ],
      );

  static LinearGradient get primaryGradient => brandGradient(primary);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static Color _onBrand(Color brand) {
    return brand.computeLuminance() > 0.55 ? const Color(0xFF1F2937) : Colors.white;
  }

  static ThemeData lightThemeFor(Color brand) {
    final onBrand = _onBrand(brand);
    final scheme = ColorScheme.light(
      primary: brand,
      secondary: Color.lerp(brand, const Color(0xFF7C3AED), 0.35)!,
      surface: lightSurface,
      error: danger,
      onPrimary: onBrand,
      onSurface: lightTextPrimary,
    );
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: brand,
      cardColor: lightCard,
      dividerColor: lightBorder,
      colorScheme: scheme,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
        ),
      ),
    );
  }

  static ThemeData darkThemeFor(Color brand) {
    final onBrand = _onBrand(brand);
    final scheme = ColorScheme.dark(
      primary: brand,
      secondary: Color.lerp(brand, const Color(0xFF7C3AED), 0.25)!,
      surface: darkSurface,
      error: danger,
      onPrimary: onBrand,
      onSurface: darkTextPrimary,
    );
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: brand,
      cardColor: darkCard,
      dividerColor: darkBorder,
      colorScheme: scheme,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
        ),
      ),
    );
  }

  /// Legacy getters — prefer lightThemeFor / darkThemeFor with live brand.
  static ThemeData get lightTheme => lightThemeFor(primary);
  static ThemeData get darkTheme => darkThemeFor(primary);
}
