import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twq/saturation_color_filter.dart';

enum TappableType { opacity, press, none }

class Tappable extends StatefulWidget {
  const Tappable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.behavior,
    this.type = TappableType.press,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior? behavior;
  final TappableType type;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  var pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    final (onLongPress, onTap) = (widget.onLongPress, widget.onTap);

    return GestureDetector(
      behavior: widget.behavior,
      onLongPress:
          onLongPress == null
              ? null
              : () {
                onLongPress();
                HapticFeedback.heavyImpact();
              },
      onTap:
          onTap == null
              ? null
              : () {
                onTap();
                HapticFeedback.lightImpact();
              },
      onTapDown: (_) {
        setState(() => pressed = true);
      },
      onTapUp: (_) {
        setState(() => pressed = false);
      },
      onTapCancel: () {
        setState(() => pressed = false);
      },
      child: switch (widget.type) {
        TappableType.opacity => Opacity(
          opacity:
              disabled
                  ? 0.8
                  : pressed
                  ? 0.5
                  : 1.0,
          child: widget.child,
        ),
        TappableType.press => Opacity(
          opacity: disabled ? 0.5 : 1,
          child: ColorFiltered(
            colorFilter: saturationColorFilter(disabled ? 0.25 : 1),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              scale: pressed && !disabled ? 0.97 : 1.0,
              child: widget.child,
            ),
          ),
        ),
        TappableType.none => widget.child,
      },
    );
  }
}
