import 'package:flutter/material.dart';

/// Wraps a child and gently scales it down while it is being pressed,
/// giving cards, tiles and buttons a tactile "push" feedback.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 110),
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
