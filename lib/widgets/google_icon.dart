import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official multi-color Google "G" logo, rendered from the bundled SVG asset.
/// The exact same logo Google uses in its own sign-in buttons.
class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/google_g.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
