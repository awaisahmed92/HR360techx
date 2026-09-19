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
  ];

  static BrandThemeOption byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}
