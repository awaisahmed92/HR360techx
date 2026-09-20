import 'dart:math';

import 'package:flutter/material.dart';

/// Local login wallpapers from `web/login-background-images/`.
class LoginBackgrounds {
  LoginBackgrounds._();

  static const files = <String>[
    'images1.jpeg',
    'LoginBG13.jpg',
    'LoginBG28.jpg',
    'LoginBG29.jpg',
    'LoginBG38.jpg',
    'LoginBG103.jpg',
    'LoginBG143.jpg',
    'LoginBG148.jpg',
    'LoginBG161.jpg',
    'LoginBG188.jpg',
    'LoginBG215.jpg',
    'LoginBG244.jpg',
    'LoginBG257.jpg',
  ];

  static final _rng = Random();

  static String assetPath(String fileName) =>
      'web/login-background-images/$fileName';

  static String randomAssetPath() =>
      assetPath(files[_rng.nextInt(files.length)]);

  static ImageProvider randomImage() => AssetImage(randomAssetPath());
}
