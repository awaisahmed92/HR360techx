import 'package:flutter/material.dart';

/// WebHR-style accent presets — drives menu, headings, and form accents.
class BrandThemeOption {
  const BrandThemeOption({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
}

class BrandThemes {
  BrandThemes._();

  static const defaultId = 'bright_navy_blue';

  static const List<BrandThemeOption> all = [
    BrandThemeOption(id: 'bright_navy_blue', name: 'Bright Navy Blue', color: Color(0xFF1E4B8C)),
    BrandThemeOption(id: 'spring_blink', name: 'Spring Blink', color: Color(0xFFB4D12A)),
    BrandThemeOption(id: 'flame_orange', name: 'Flame Orange', color: Color(0xFFFF5C00)),
    BrandThemeOption(id: 'dark_gray', name: 'Dark Gray', color: Color(0xFF4B5563)),
    BrandThemeOption(id: 'light_gray', name: 'Light Gray', color: Color(0xFF9CA3AF)),
    BrandThemeOption(id: 'deep_maroon', name: 'Deep Maroon', color: Color(0xFF7A1F2B)),
    BrandThemeOption(id: 'vivid_orchid', name: 'Vivid Orchid', color: Color(0xFFC026D3)),
    BrandThemeOption(id: 'forest_green', name: 'Forest Green', color: Color(0xFF1B5E3B)),
    BrandThemeOption(id: 'charcoal_gray', name: 'Charcoal Gray', color: Color(0xFF374151)),
    BrandThemeOption(id: 'raspberry_pink', name: 'Raspberry Pink', color: Color(0xFFE11D8F)),
    BrandThemeOption(id: 'azure_blue', name: 'Azure Blue', color: Color(0xFF22B8CF)),
    BrandThemeOption(id: 'mustard_yellow', name: 'Mustard Yellow', color: Color(0xFFCA8A04)),
    BrandThemeOption(id: 'prussian_blue', name: 'Prussian Blue', color: Color(0xFF0C2340)),
    BrandThemeOption(id: 'grass_green', name: 'Grass Green', color: Color(0xFF22C55E)),
    BrandThemeOption(id: 'bubblegum_pink', name: 'Bubblegum Pink', color: Color(0xFFF9A8D4)),
    BrandThemeOption(id: 'roast_brown', name: 'Roast Brown', color: Color(0xFF8B5A2B)),
    BrandThemeOption(id: 'brick_red', name: 'Brick Red', color: Color(0xFFB42318)),
    BrandThemeOption(id: 'slate_green', name: 'Slate Green', color: Color(0xFF3F4F46)),
    BrandThemeOption(id: 'tan_brown', name: 'Tan Brown', color: Color(0xFFC4A484)),
    BrandThemeOption(id: 'modern_blue', name: 'Modern Blue', color: Color(0xFF3B82F6)),
    BrandThemeOption(id: 'royal_purple', name: 'Royal Purple', color: Color(0xFF6D28D9)),
    BrandThemeOption(id: 'autumn_maple', name: 'Autumn Maple', color: Color(0xFFE67A1A)),
    BrandThemeOption(id: 'olive_green', name: 'Olive Green', color: Color(0xFF808000)),
    BrandThemeOption(id: 'mahogany_red', name: 'Mahogany Red', color: Color(0xFF4A0E0E)),
    BrandThemeOption(id: 'turquoise_whisper', name: 'Turquoise Whisper', color: Color(0xFF0E7490)),
    BrandThemeOption(id: 'dusty_rose', name: 'Dusty Rose', color: Color(0xFFC4A4A4)),
    BrandThemeOption(id: 'tranquil_sky', name: 'Tranquil Sky', color: Color(0xFF60A5FA)),
    BrandThemeOption(id: 'kale_green', name: 'Kale Green', color: Color(0xFF4B5320)),
    BrandThemeOption(id: 'hawthorn_rose', name: 'Hawthorn Rose', color: Color(0xFF9F1239)),
    BrandThemeOption(id: 'saffron_sunset', name: 'Saffron Sunset', color: Color(0xFFE2B007)),
    BrandThemeOption(id: 'deep_teal_blue', name: 'Deep Teal Blue', color: Color(0xFF0F3D4C)),
    BrandThemeOption(id: 'moonlit_lavender', name: 'Moonlit Lavender', color: Color(0xFFC4B5FD)),
    BrandThemeOption(id: 'aqua_horizon', name: 'Aqua Horizon', color: Color(0xFF22D3EE)),
    BrandThemeOption(id: 'sunlit_amber', name: 'Sunlit Amber', color: Color(0xFFF59E0B)),
  ];

  static BrandThemeOption byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}
