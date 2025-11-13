import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rot_icon.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.orientation,
    required this.flash,
    required this.onClose,
    required this.onToggleFlash,
    required this.fourThree,
    required this.onToggleRatio,
  });

  final DeviceOrientation orientation;
  final bool flash;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final bool fourThree;
  final VoidCallback onToggleRatio;

  @override
  Widget build(BuildContext context) {
    final ratioTxt = fourThree ? '4:3' : '16:9';
    final ratioBtn = TextButton(
      onPressed: onToggleRatio,
      child: Text(ratioTxt,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );

    final portrait = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RotIcon(orientation: orientation, icon: Icons.close, onPressed: onClose),
        Row(children: [
          RotIcon(
              orientation: orientation,
              icon: flash ? Icons.flash_on : Icons.flash_off,
              onPressed: onToggleFlash,
              size: 26),
          const SizedBox(width: 16),
          ratioBtn,
        ]),
      ],
    );

    final landscape = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RotIcon(orientation: orientation, icon: Icons.close, onPressed: onClose),
        RotIcon(
            orientation: orientation,
            icon: flash ? Icons.flash_on : Icons.flash_off,
            onPressed: onToggleFlash,
            size: 26),
        const SizedBox(height: 16),
        ratioBtn,
      ],
    );

    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return SafeArea(
          child: Container(
            height: 56,
            color: Colors.black38,
            child: portrait,
          ),
        );
      case DeviceOrientation.landscapeLeft:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(width: 72, color: Colors.black38, child: landscape),
        );
      case DeviceOrientation.landscapeRight:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(width: 72, margin: const EdgeInsets.only(right: 50), color: Colors.black38, child: landscape),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
