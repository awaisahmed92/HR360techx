import 'dart:math';

import 'package:flutter/material.dart';

/// HR photos from `web/profile-backgroud/` (Flutter assets + web static files).
class ProfileBackgrounds {
  ProfileBackgrounds._();

  static const files = <String>[
    'Profile1004.webp',
    'Profile1046.png',
    'Profile1096.png',
    'Profile110.webp',
    'Profile1256.png',
    'Profile241.webp',
    'Profile303.png',
    'Profile347.png',
    'Profile922.png',
    'Profile970.png',
  ];

  static final _rng = Random();

  /// Asset key used by [Image.asset] / [AssetImage].
  static String assetPath(String fileName) => 'web/profile-backgroud/$fileName';

  static String randomAssetPath() => assetPath(files[_rng.nextInt(files.length)]);

  static ImageProvider randomImage() => AssetImage(randomAssetPath());
}
