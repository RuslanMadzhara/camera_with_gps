import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show DeviceOrientation;

class PhotoProcessor {

  static Future<String> process({
    required XFile shot,
    required DeviceOrientation orientation,
    required bool fourThree,
  }) async {
    print('📸 PhotoProcessor: Platform = ${Platform.operatingSystem}, orientation = $orientation');

    final bytes = await shot.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return shot.path;

    img.Image imgOut = decoded;
    print('📸 PhotoProcessor: original size = ${decoded.width}x${decoded.height}');

    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        print('📸 PhotoProcessor: rotating 270° (landscapeLeft)');
        imgOut = img.copyRotate(imgOut, angle: 270);
        break;
      case DeviceOrientation.landscapeRight:
        print('📸 PhotoProcessor: rotating 90° (landscapeRight)');
        imgOut = img.copyRotate(imgOut, angle: 90);
        break;
      case DeviceOrientation.portraitDown:
        print('📸 PhotoProcessor: rotating 180° (portraitDown)');
        imgOut = img.copyRotate(imgOut, angle: 180);
        break;
      default:
        print('📸 PhotoProcessor: no rotation (portraitUp or unknown)');
        break;
    }

    print('📸 PhotoProcessor: after rotation size = ${imgOut.width}x${imgOut.height}');

    // === cropping ===
    final w = imgOut.width, h = imgOut.height;
    final isPortrait = orientation == DeviceOrientation.portraitUp;
    final wantRatio = fourThree
        ? (isPortrait ? 3 / 4 : 4 / 3)
        : (isPortrait ? 9 / 16 : 16 / 9);

    final curRatio = w / h;
    const eps = 0.01;
    if ((curRatio - wantRatio).abs() > eps) {
      int cropW, cropH;
      if (curRatio > wantRatio) {
        cropH = h;
        cropW = (h * wantRatio).round();
      } else {
        cropW = w;
        cropH = (w / wantRatio).round();
      }
      final x = ((w - cropW) / 2).round();
      final y = ((h - cropH) / 2).round();
      imgOut = img.copyCrop(imgOut, x: x, y: y, width: cropW, height: cropH);
    }

    await File(shot.path).writeAsBytes(img.encodeJpg(imgOut));
    return shot.path;
  }
}