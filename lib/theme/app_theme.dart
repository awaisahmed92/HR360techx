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

  static const Color ink = Color(0xFF14181F);
  static const Color sidebarDark = Color(0xFF161B22);

  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardHover = Color(0xFF26334D);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  static const Color lightBg = Color(0xFFF3F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE6E8EE);
  static const Color lightTextPrimary = Color(0xFF1A1D26);
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
      useMaterial3: true,
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
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: lightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: brand, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      useMaterial3: true,
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
        backgroundColor: ink,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: brand, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  /// Legacy getters — prefer lightThemeFor / darkThemeFor with live brand.
  static ThemeData get lightTheme => lightThemeFor(primary);
  static ThemeData get darkTheme => darkThemeFor(primary);
}
