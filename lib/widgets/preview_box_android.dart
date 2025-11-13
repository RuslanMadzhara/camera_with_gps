import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Android PreviewBox - завжди показує портретний preview (UI заблокований в portrait)
class PreviewBoxAndroid extends StatelessWidget {
  const PreviewBoxAndroid({
    super.key,
    required this.controller,
    required this.fourThree,
  });

  final CameraController controller;
  final bool fourThree;

  @override
  Widget build(BuildContext context) {
    final wantRatio = fourThree ? 4 / 3 : 16 / 9;
    final sensor = controller.value.previewSize!;
    final rawW = sensor.height;
    final rawH = sensor.width;

    // Android: завжди portrait layout
    final screenW = MediaQuery.of(context).size.width;
    final previewH = screenW * wantRatio;

    return Center(
      child: ClipRect(
        child: SizedBox(
          width: screenW,
          height: previewH,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: rawW,
              height: rawH,
              child: CameraPreview(controller),
            ),
          ),
        ),
      ),
    );
  }
}
