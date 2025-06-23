import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'rot_icon.dart';
import 'shutter_button.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.orientation,
    required this.busy,
    required this.onShoot,
    required this.onGallery,
    required this.onSwitchCam,
  });

  final DeviceOrientation orientation;
  final bool busy;
  final VoidCallback onShoot;
  final VoidCallback onGallery;
  final VoidCallback onSwitchCam;

  @override
  Widget build(BuildContext context) {
    final portrait = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RotIcon(orientation: orientation, icon: Icons.photo_library, onPressed: onGallery),
        GestureDetector(onTap: busy ? null : onShoot, child: ShutterButton(busy: busy)),
        RotIcon(orientation: orientation, icon: Icons.cameraswitch, onPressed: onSwitchCam),
      ],
    );

    final side = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RotIcon(orientation: orientation, icon: Icons.photo_library, onPressed: onGallery),
        GestureDetector(onTap: busy ? null : onShoot, child: ShutterButton(busy: busy)),
        RotIcon(orientation: orientation, icon: Icons.cameraswitch, onPressed: onSwitchCam),
      ],
    );

    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              height: 120,
              color: Colors.black38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: portrait,
            ),
          ),
        );
      case DeviceOrientation.landscapeLeft:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(width: 72, margin: const EdgeInsets.only(right: 50), color: Colors.black38, child: side),
        );
      case DeviceOrientation.landscapeRight:
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(width: 72, margin: const EdgeInsets.only(left: 50), color: Colors.black38, child: side),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
