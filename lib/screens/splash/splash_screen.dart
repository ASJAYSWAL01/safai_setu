import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';

/// App splash screen — white gradient background, shimmering "सफाई सेतु" /
/// "Safai Setu" titles, the Hindi tagline, three feature icon cards and the
/// "Powered by Diplomax" footer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              _ShimmerText(
                'सफाई सेतु',
                fontSize: 40,
                letterSpacing: 4,
                secondWordLetterSpacing: 1.0,
                controller: _shimmer,
              ),
              const Spacer(flex: 4),
              _ShimmerText(
                'Safai Setu',
                fontSize: 46,
                letterSpacing: 2.5,
                controller: _shimmer,
              ),
              const SizedBox(height: 12),
              Text(
                'एक कदम स्वच्छता की ओर',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: const Color(0xFF555555),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 3),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconCard(
                    color: Color(0xFF4CAF50),
                    icon: Icons.cleaning_services,
                  ),
                  SizedBox(width: 28),
                  _IconCard(
                    color: Color(0xFFFF9800),
                    icon: Icons.description_outlined,
                  ),
                  SizedBox(width: 28),
                  _IconCard(
                    color: Color(0xFF009688),
                    icon: Icons.local_shipping,
                  ),
                ],
              ),
              const Spacer(flex: 4),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF999999),
                    letterSpacing: 1.2,
                  ),
                  children: [
                    TextSpan(text: AppStrings.of(context).poweredBy),
                    const TextSpan(
                      text: 'Diplomax',
                      style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title text with a moving blue shimmer gradient.
class _ShimmerText extends StatelessWidget {
  const _ShimmerText(
    this.text, {
    required this.controller,
    required this.fontSize,
    this.letterSpacing = 0,
    this.secondWordLetterSpacing,
  });

  final String text;
  final Animation<double> controller;
  final double fontSize;
  final double letterSpacing;

  /// If set, the text is split on the first space and this value is applied
  /// as the letterSpacing for the second word only (e.g. to visually balance
  /// Devanagari words that differ in optical density).
  final double? secondWordLetterSpacing;

  @override
  Widget build(BuildContext context) {
    // Split into two words when per-word spacing is needed.
    final parts = secondWordLetterSpacing != null ? text.split(' ') : null;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: const [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
              Color(0xFF1565C0),
            ],
            stops: const [0.3, 0.5, 0.7],
            transform: _SlidingGradientTransform(controller.value),
          ).createShader(bounds),
          child: parts != null
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${parts.first} ',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: letterSpacing,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: parts.skip(1).join(' '),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: secondWordLetterSpacing,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                )
              : Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: letterSpacing,
                    color: Colors.white,
                  ),
                ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Slide the highlight band across the text.
    final shift = (slidePercent * 2 - 1) * bounds.width * 0.35;
    return Matrix4.translationValues(shift, 0, 0);
  }
}

/// White rounded card with a colored border and icon (like the HTML design).
class _IconCard extends StatelessWidget {
  const _IconCard({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 42),
    );
  }
}
