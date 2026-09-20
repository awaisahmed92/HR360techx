import 'package:flutter/material.dart';

class ClockFaceOption {
  const ClockFaceOption({
    required this.id,
    required this.name,
    required this.colors,
    this.icon = Icons.schedule,
  });

  final String id;
  final String name;
  final List<Color> colors;
  final IconData icon;
}

/// Visual clock themes (WebHR-style circular faces).
class ClockFaces {
  ClockFaces._();

  static const defaultId = 'digital_vortex';

  static const all = <ClockFaceOption>[
    ClockFaceOption(id: 'nightfall_serenity', name: 'Nightfall Serenity', colors: [Color(0xFF1A1A2E), Color(0xFFE94560)], icon: Icons.local_fire_department),
    ClockFaceOption(id: 'cosmo_rings', name: 'Cosmo Rings', colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFFE63946)], icon: Icons.blur_circular),
    ClockFaceOption(id: 'quantum_noir', name: 'Quantum Noir', colors: [Color(0xFF000000), Color(0xFF434343)], icon: Icons.nights_stay),
    ClockFaceOption(id: 'codewave_time', name: 'CodeWave Time', colors: [Color(0xFF0D1B0D), Color(0xFF39FF14)], icon: Icons.code),
    ClockFaceOption(id: 'blackcore_clock', name: 'BlackCore Clock', colors: [Color(0xFF111111), Color(0xFF444444)], icon: Icons.radio_button_checked),
    ClockFaceOption(id: 'darkstream_clock', name: 'Darkstream Clock', colors: [Color(0xFF141E30), Color(0xFF243B55)], icon: Icons.close),
    ClockFaceOption(id: 'opal_ticks', name: 'Opal Ticks', colors: [Color(0xFFFF6B35), Color(0xFFF7C59F)], icon: Icons.bubble_chart),
    ClockFaceOption(id: 'greenwave', name: 'GreenWave', colors: [Color(0xFF0B3D0B), Color(0xFF7CFC00)], icon: Icons.waves),
    ClockFaceOption(id: 'ecochrono', name: 'EcoChrono', colors: [Color(0xFF1B5E20), Color(0xFFCDDC39)], icon: Icons.eco),
    ClockFaceOption(id: 'moonlit_retreat', name: 'Moonlit Retreat', colors: [Color(0xFF0D1B2A), Color(0xFF778DA9)], icon: Icons.nightlight_round),
    ClockFaceOption(id: 'ethereal_ticks', name: 'Ethereal Ticks', colors: [Color(0xFFFFF176), Color(0xFFFF8A65)], icon: Icons.sentiment_satisfied_alt),
    ClockFaceOption(id: 'digital_vortex', name: 'Digital Vortex', colors: [Color(0xFF0A1628), Color(0xFF00D4FF)], icon: Icons.blur_on),
    ClockFaceOption(id: 'regaltime', name: 'RegalTime', colors: [Color(0xFF2D1B4E), Color(0xFF9B59B6)], icon: Icons.workspace_premium),
    ClockFaceOption(id: 'turbine_horizon', name: 'Turbine Horizon', colors: [Color(0xFF3E2723), Color(0xFF8D6E63)], icon: Icons.account_balance),
    ClockFaceOption(id: 'coastal_clock_tower', name: 'Coastal Clock Tower', colors: [Color(0xFF1565C0), Color(0xFF90CAF9)], icon: Icons.location_city),
    ClockFaceOption(id: 'azure_tower', name: 'The Azure Tower', colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)], icon: Icons.apartment),
    ClockFaceOption(id: 'tower_of_dawn', name: 'Tower of Dawn', colors: [Color(0xFF4A148C), Color(0xFFE040FB)], icon: Icons.castle),
    ClockFaceOption(id: 'oasis_clock', name: 'Oasis Clock', colors: [Color(0xFF263238), Color(0xFF90A4AE)], icon: Icons.park),
    ClockFaceOption(id: 'time_of_stone', name: 'Time of Stone', colors: [Color(0xFF37474F), Color(0xFF78909C)], icon: Icons.landscape),
    ClockFaceOption(id: 'sunset_spire', name: 'Sunset Spire Time', colors: [Color(0xFFBF360C), Color(0xFFFFAB40)], icon: Icons.wb_twilight),
    ClockFaceOption(id: 'mirage_time', name: 'Mirage Time', colors: [Color(0xFF4E342E), Color(0xFFFF7043)], icon: Icons.temple_buddhist),
    ClockFaceOption(id: 'blue_winds', name: 'Blue Winds of Time', colors: [Color(0xFF01579B), Color(0xFF4FC3F7)], icon: Icons.air),
    ClockFaceOption(id: 'emerald_monument', name: 'Emerald Monument', colors: [Color(0xFF1B5E20), Color(0xFF69F0AE)], icon: Icons.forest),
    ClockFaceOption(id: 'wave_watcher', name: 'Wave Watcher', colors: [Color(0xFF006064), Color(0xFF18FFFF)], icon: Icons.tsunami),
    ClockFaceOption(id: 'atlantis_time', name: 'Time of Atlantis', colors: [Color(0xFF004D40), Color(0xFF1DE9B6)], icon: Icons.water),
    ClockFaceOption(id: 'winter_antlers', name: 'Winter Antlers', colors: [Color(0xFF263238), Color(0xFFB0BEC5)], icon: Icons.ac_unit),
    ClockFaceOption(id: 'statue_hour', name: 'Statue of the Hour', colors: [Color(0xFF1A237E), Color(0xFF7986CB)], icon: Icons.account_balance),
    ClockFaceOption(id: 'inkflare_time', name: 'Inkflare Time', colors: [Color(0xFF880E4F), Color(0xFFFF4081)], icon: Icons.brush),
    ClockFaceOption(id: 'starline_sync', name: 'Starline Sync', colors: [Color(0xFFB71C1C), Color(0xFFFF5252)], icon: Icons.star),
    ClockFaceOption(id: 'zentick', name: 'ZenTick', colors: [Color(0xFF1B5E20), Color(0xFFA5D6A7)], icon: Icons.spa),
  ];

  static ClockFaceOption byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return all.firstWhere((f) => f.id == defaultId, orElse: () => all.first);
  }
}
