import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PreviewBoxIOS extends StatelessWidget {
  const PreviewBoxIOS({
    super.key,
    required this.controller,
    required this.orientation,
  });

  final CameraController controller;
  final DeviceOrientation orientation;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final aspect = controller.value.aspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        final isPortrait = orientation == DeviceOrientation.portraitUp ||
            orientation == DeviceOrientation.portraitDown;

        // ===== PORTRAIT: заповнюємо не 100%, а ~80% висоти =====
        if (isPortrait) {
          final boxW = maxW;
          final boxH = maxH * 0.8; // 80% висоти (по 10% зверху/знизу)

          // Рахуємо розмір превʼю з тим самим aspectRatio під BoxFit.cover
          final heightFromWidth = boxW / aspect;
          double childW;
          double childH;

          if (heightFromWidth >= boxH) {
            // Тягнемо по ширині
            childW = boxW;
            childH = heightFromWidth;
          } else {
            // Тягнемо по висоті
            childH = boxH;
            childW = boxH * aspect;
          }

          return SizedBox(
            width: maxW,
            height: maxH, // повний простір, щоб можна було центрувати
            child: Center(
              child: ClipRect(
                child: SizedBox(
                  width: boxW,
                  height: boxH, // 80% висоти всередині
                  child: Center(
                    child: SizedBox(
                      width: childW,
                      height: childH,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // ===== LANDSCAPE: повертаємо превʼю на 90° =====
        final quarterTurns =
            orientation == DeviceOrientation.landscapeLeft ? 1 : 3;

        return SizedBox(
          width: maxW,
          height: maxH,
          child: Center(
            child: RotatedBox(
              quarterTurns: quarterTurns,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}
