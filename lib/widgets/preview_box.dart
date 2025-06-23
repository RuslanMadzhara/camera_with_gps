import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final wantRatio = fourThree ? 4 / 3 : 16 / 9;
    final sensor = controller.value.previewSize!;
    final rawW = sensor.height;
    final rawH = sensor.width;

    if (orientation == DeviceOrientation.portraitUp) {
      final screenW = MediaQuery.of(context).size.width;
      final previewH = screenW * wantRatio;
      return Center(
        child: ClipRect(
          child: SizedBox(
            width: screenW,
            height: previewH,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: rawW, height: rawH, child: CameraPreview(controller)),
            ),
          ),
        ),
      );
    } else {
      final screenH = MediaQuery.of(context).size.height;
      final previewW = screenH * wantRatio;
      return Center(
        child: ClipRect(
          child: SizedBox(
            width: previewW,
            height: screenH,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: sensor.width, height: sensor.height, child: CameraPreview(controller)),
            ),
          ),
        ),
      );
    }
  }
}