import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Global keys attached to the tour targets (bottom navigation bar and the
/// dashboard stat cards) so the overlay can compute their EXACT screen
/// rectangles. Only one shell exists at a time, so sharing these is safe.
class TourKeys {
  TourKeys._();

  /// Attached to the shell's [NavigationBar].
  static final GlobalKey navBarKey = GlobalKey();

  /// Attached to the dashboard's 2x2 stat GridView (used only to detect that
  /// the grid is laid out; the exact tile rects come from [statTileKeys]).
  static final GlobalKey statGridKey = GlobalKey();

  /// Attached to each of the four stat cards, so the spotlight hole covers
  /// the exact card and nothing else.
  static final List<GlobalKey> statTileKeys =
      List<GlobalKey>.generate(4, (_) => GlobalKey());
}

/// One spotlight step of the tour.
class TourStep {
  const TourStep({
    required this.title,
    required this.description,
    this.icon,
    this.target,
    this.targetBuilder,
  });

  final String title;
  final String description;
  final IconData? icon;

  /// Screen rectangle to spotlight. `null` renders a centered hero card
  /// (used for the welcome / finish steps).
  final Rect? target;

  /// Lazily resolves the target rectangle at the moment the step is shown,
  /// so the hole always covers the exact, current position of the feature
  /// (preferred over [target], which is captured when the tour is built).
  final Rect? Function()? targetBuilder;

  Rect? resolve() => targetBuilder?.call() ?? target;
}

/// Animated, skippable first-run tour that spotlights UI elements one by one.
class AppTour {
  AppTour._();

  /// Screen rect of the navigation bar (via [TourKeys.navBarKey]).
  static Rect? navBarRect() {
    final box = TourKeys.navBarKey.currentContext?.findRenderObject()
        as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// One rect per tab, dividing the navigation bar into [count] equal parts.
  static List<Rect> navTabRects({required int count}) {
    final rect = navBarRect();
    if (rect == null) return const [];
    final w = rect.width / count;
    return [
      for (var i = 0; i < count; i++)
        Rect.fromLTWH(rect.left + i * w, rect.top, w, rect.height),
    ];
  }

  /// Rects of the four stat tiles, measured from the actual rendered cards
  /// (via [TourKeys.statTileKeys]) so each hole matches its card exactly.
  static List<Rect> statTileRects() {
    return [
      for (final key in TourKeys.statTileKeys)
        if (keyRect(key) case final rect?) rect,
    ];
  }

  /// Screen rect of a [GlobalKey]'s render object, or null if not laid out.
  static Rect? keyRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Lazy resolver for tab [index] of a [count]-tab bar — resolves the rect
  /// fresh each time the step is shown.
  static Rect? Function() tabTarget(int index, int count) => () {
    final rects = navTabRects(count: count);
    return index < rects.length ? rects[index] : null;
  };

  /// Lazy resolver for stat tile [index] — resolves the rect fresh each time
  /// the step is shown.
  static Rect? Function() statTarget(int index) => () {
    final rects = statTileRects();
    return index < rects.length ? rects[index] : null;
  };

  /// Shows the tour overlay and completes when it is finished or skipped.
  static Future<void> start(
    BuildContext context, {
    required List<TourStep> steps,
  }) async {
    if (steps.isEmpty) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: steps,
        onFinished: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    await completer.future;
  }
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onFinished});

  final List<TourStep> steps;
  final VoidCallback onFinished;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _stepController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _holeCurve = CurvedAnimation(
    parent: _stepController,
    curve: Curves.easeInOutCubic,
  );

  int _index = 0;
  Rect? _prevRect;
  Rect? _nextRect;

  @override
  void initState() {
    super.initState();
    _nextRect = widget.steps.first.target;
  }

  @override
  void dispose() {
    _stepController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Rect? get _currentRect {
    if (_prevRect == null || _nextRect == null) return _nextRect;
    return Rect.lerp(_prevRect, _nextRect, _holeCurve.value);
  }

  void _goTo(int index) {
    if (index >= widget.steps.length) {
      widget.onFinished();
      return;
    }
    setState(() {
      _prevRect = _currentRect;
      _index = index;
      _nextRect = widget.steps[index].resolve();
    });
    _stepController.forward(from: 0);
  }

  void _next() => _goTo(_index + 1);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final step = widget.steps[_index];
    final target = _currentRect;
    final below = target == null || target.center.dy < size.height * 0.52;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // Absorb touches so nothing behind the tour is tappable.
          child: Stack(
            children: [
              // Dimmed scrim with a spotlight hole + glow ring.
              Positioned.fill(
                child: CustomPaint(
                  painter: _TourPainter(
                    prev: _prevRect,
                    next: _nextRect,
                    curve: _holeCurve,
                    pulse: _pulseController,
                  ),
                ),
              ),
              // Tooltip card.
              if (target == null)
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 340),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale:
                            Tween<double>(begin: 0.88, end: 1).animate(anim),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_index),
                      child: _buildCard(step, hero: true),
                    ),
                  ),
                )
              else ...[
                Positioned.fromRect(
                  rect: _cardRect(target, size),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_index),
                      child: _buildCard(step, hero: false),
                    ),
                  ),
                ),
                // Pointer arrow connecting the card to the spotlight — always
                // sits ON the card's edge, aimed at the hole center even when
                // the card is clamped at a screen edge.
                Positioned(
                  left: _arrowX(target, size) - 7,
                  top: below
                      ? _cardRect(target, size).top - 9
                      : _cardRect(target, size).bottom - 7,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        border: Border.all(color: AppColors.borderColor),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Rect _cardRect(Rect target, Size size) {
    const cardW = 348.0;
    const cardH = 232.0;
    final left = (target.center.dx - cardW / 2)
        .clamp(16.0, math.max(16.0, size.width - cardW - 16.0))
        .toDouble();
    final below = target.center.dy < size.height * 0.52;
    final top = below ? target.bottom + 28 : target.top - cardH - 28;
    final safeTop = top
        .clamp(10.0, math.max(10.0, size.height - cardH - 10.0))
        .toDouble();
    return Rect.fromLTWH(left, safeTop, cardW, cardH);
  }

  /// Horizontal screen position of the pointer arrow: on the card's edge,
  /// horizontally aligned with the hole's center but clamped INSIDE the card
  /// so the arrow never floats disconnected from it.
  double _arrowX(Rect target, Size size) {
    final card = _cardRect(target, size);
    final dxFromLeft = (target.center.dx - card.left)
        .clamp(18.0, card.width - 18.0)
        .toDouble();
    return card.left + dxFromLeft;
  }

  Widget _buildCard(TourStep step, {required bool hero}) {
    final isLast = _index == widget.steps.length - 1;
    final total = widget.steps.length;
    final height = hero ? 274.0 : 232.0;

    return Container(
      width: 348,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(hero ? 26 : 22),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              onPressed: widget.onFinished,
              icon: const Icon(Icons.close, size: 20),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
              tooltip: 'Skip tour',
            ),
          ),
          Padding(
            padding: hero
                ? const EdgeInsets.fromLTRB(22, 14, 22, 14)
                : const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: hero
                ? _heroLayout(step, isLast, total)
                : _compactLayout(step, isLast, total),
          ),
        ],
      ),
    );
  }

  /// Centered layout for the welcome / finish steps: big animated icon with a
  /// pulsing ring and orbiting sparkles.
  Widget _heroLayout(TourStep step, bool isLast, int total) {
    final icon = step.icon ?? Icons.celebration_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final t = _pulseController.value;
            return SizedBox(
              width: 108,
              height: 108,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Expanding pulse ring.
                  Container(
                    width: 66 + 40 * t,
                    height: 66 + 40 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen
                          .withOpacity(0.16 * (1 - t)),
                    ),
                  ),
                  // Core icon.
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.paleGreen,
                      border: Border.all(
                        color: AppColors.primaryGreen.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon,
                        color: AppColors.primaryGreen, size: 30),
                  ),
                  // Orbiting sparkles (phase-shifted with the pulse).
                  Positioned(
                    top: 6 + 8 * (1 - t),
                    left: 10 + 6 * t,
                    child: _sparkle(t),
                  ),
                  Positioned(
                    bottom: 8 + 7 * t,
                    right: 8 + 9 * (1 - t),
                    child: _sparkle(1 - t),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Text(
          step.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            step.description,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
        const Spacer(),
        _footer(isLast, total, centered: true),
      ],
    );
  }

  Widget _sparkle(double t) {
    return Opacity(
      opacity: 0.25 + 0.75 * t,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentGreen,
        ),
      ),
    );
  }

  /// Compact layout for spotlighted steps: icon + title row on top,
  /// description in the middle, footer with dots + button.
  Widget _compactLayout(TourStep step, bool isLast, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.icon != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon,
                    color: AppColors.primaryGreen, size: 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 24),
                child: Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          step.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        const Spacer(),
        _footer(isLast, total, centered: false),
      ],
    );
  }

  void _prev() {
    if (_index <= 0) return;
    _goTo(_index - 1);
  }

  Widget _arrowButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      color: enabled
          ? AppColors.primaryGreen
          : AppColors.textSecondary.withOpacity(0.35),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }

  Widget _footer(bool isLast, int total, {required bool centered}) {
    final row = Row(
      children: [
        _arrowButton(
          icon: Icons.chevron_left,
          tooltip: 'Previous',
          enabled: _index > 0,
          onTap: _prev,
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress dots.
                ...List.generate(total, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 4),
                    width: active ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        _arrowButton(
          icon: Icons.chevron_right,
          tooltip: 'Next',
          enabled: true,
          onTap: _next,
        ),
        const SizedBox(width: 6),
        Text(
          '${_index + 1}/$total',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor:
                AppColors.isDark ? const Color(0xFF111511) : Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(isLast ? 'Got it' : 'Next'),
        ),
      ],
    );

    if (!centered) return row;
    return Center(
      child: SizedBox(
        width: 348 - 44,
        child: row,
      ),
    );
  }
}

/// Draws the dimmed scrim with a rounded spotlight hole, a soft glow behind
/// the hole and a breathing highlight ring around it. On centered steps
/// (no hole) it dims the screen and draws a soft stage glow in the middle.
class _TourPainter extends CustomPainter {
  _TourPainter({
    required this.prev,
    required this.next,
    required this.curve,
    required this.pulse,
  }) : super(repaint: Listenable.merge([curve, pulse]));

  final Rect? prev;
  final Rect? next;
  final Animation<double> curve;
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;

    // Always dim the screen.
    final scrim = Paint()..color = Colors.black.withOpacity(0.58);
    canvas.drawRect(full, scrim);

    final raw = prev == null || next == null
        ? next
        : Rect.lerp(prev, next, curve.value);

    // Centered hero step: soft pulsing stage glow behind the card.
    if (raw == null) {
      final center = size.center(Offset.zero);
      final glowRadius = size.shortestSide * 0.5;
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryGreen.withOpacity(
                AppColors.isDark ? 0.30 : 0.38),
            AppColors.primaryGreen.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: glowRadius),
        );
      canvas.drawCircle(center, glowRadius, glow);
      return;
    }

    const pad = 10.0;
    final hole = raw.inflate(pad);
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(22));

    // Soft green glow radiating from the spotlight.
    final glowRadius = math.max(hole.width, hole.height) * 1.15;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryGreen.withOpacity(AppColors.isDark ? 0.30 : 0.35),
          AppColors.primaryGreen.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: hole.center, radius: glowRadius),
      );
    canvas.drawCircle(hole.center, glowRadius, glow);

    // Dim scrim with the hole cut out.
    final holePath = Path()..addRRect(rrect);
    final cut = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      holePath,
    );
    canvas.drawPath(cut, scrim);

    // Breathing highlight ring.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.lightGreen.withOpacity(0.55 + 0.45 * pulse.value);
    canvas.drawRRect(rrect, ring);
  }

  @override
  bool shouldRepaint(_TourPainter oldDelegate) =>
      oldDelegate.prev != prev ||
      oldDelegate.next != next ||
      oldDelegate.curve != curve ||
      oldDelegate.pulse != pulse;
}
