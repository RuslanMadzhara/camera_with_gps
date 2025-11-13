import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'preview_box_android.dart';
import 'preview_box_ios.dart';

/// Platform-agnostic PreviewBox that delegates to platform-specific implementations
class PreviewBox extends StatelessWidget {
  const PreviewBox({
    super.key,
    required this.controller,
    required this.orientation,
    required this.fourThree,
  });

  final CameraController controller;
  final DeviceOrientation orientation;
  final bool fourThree;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return PreviewBoxIOS(
        controller: controller,
        orientation: orientation,
      );
    } else {
      return PreviewBoxAndroid(
        controller: controller,
        fourThree: fourThree,
      );
    }
  }
}
