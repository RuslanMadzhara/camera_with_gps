import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RotIcon extends StatelessWidget {
  const RotIcon({
    super.key,
    required this.orientation,
    required this.icon,
    this.onPressed,
    this.size = 30,
  });

  final DeviceOrientation orientation;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    int turns;
    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        turns = 1;
        break;
      case DeviceOrientation.landscapeRight:
        turns = 3;
        break;
      default:
        turns = 0;
    }
    return RotatedBox(
      quarterTurns: turns,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}
