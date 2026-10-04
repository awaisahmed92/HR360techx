import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The 360tech mark from the company portfolio.
class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo-mark.svg',
      width: size,
      height: size,
      semanticsLabel: '360tech',
    );
  }
}
