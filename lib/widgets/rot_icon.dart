import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RotIcon extends StatelessWidget {
  const RotIcon({
    super.key,
    required this.orientation,
    required this.icon,
    this.onPressed,
    this.size = 30,
    this.animate = true,
    this.duration = const Duration(milliseconds: 160),
    this.curve = Curves.easeOut,
    this.color = Colors.white,
  });

  final DeviceOrientation orientation;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  /// Анімація повороту (можна вимкнути)
  final bool animate;
  final Duration duration;
  final Curve curve;

  final Color color;

  int _quarterTurns(DeviceOrientation o) {
    switch (o) {
      case DeviceOrientation.landscapeLeft:
        return 1; // 90°
      case DeviceOrientation.portraitDown:
        return 2; // 180°
      case DeviceOrientation.landscapeRight:
        return 3; // 270°
      case DeviceOrientation.portraitUp:
      default:
        return 0; // 0°
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _quarterTurns(orientation);

    final btn = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: size, color: color),
    );

    if (!animate) {
      return RotatedBox(quarterTurns: q, child: btn);
    }

    // 1 turn = 360°. quarterTurns/4 дає 0, 0.25, 0.5, 0.75
    return AnimatedRotation(
      turns: q / 4,
      duration: duration,
      curve: curve,
      child: btn,
    );
  }
}
