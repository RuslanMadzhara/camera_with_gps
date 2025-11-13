import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:image/image.dart' as img;

class PhotoProcessorAndroid {
  static Future<String> process({
    required XFile shot,
    required DeviceOrientation orientation,
    required bool fourThree,
  }) async {
    print(
        '📸 PhotoProcessor: platform=${Platform.operatingSystem}, orientation=$orientation');

    final bytes = await shot.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return shot.path;

    img.Image imgOut = decoded;
    print('📸 original size = ${decoded.width}x${decoded.height}');

    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        print('📸 rotating 270° (landscapeLeft)');
        imgOut = img.copyRotate(imgOut, angle: 270);
        break;
      case DeviceOrientation.landscapeRight:
        print('📸 rotating 90° (landscapeRight)');
        imgOut = img.copyRotate(imgOut, angle: 90);
        break;
      case DeviceOrientation.portraitDown:
        print('📸 rotating 180° (portraitDown)');
        imgOut = img.copyRotate(imgOut, angle: 180);
        break;
      default:
        print('📸 no rotation (portraitUp or unknown)');
        break;
    }

    print('📸 after rotation size = ${imgOut.width}x${imgOut.height}');

    final w = imgOut.width;
    final h = imgOut.height;
    final bool isPortrait;
    if (Platform.isAndroid) {
      isPortrait = orientation == DeviceOrientation.portraitUp;
    } else {
      isPortrait = h >= w;
    }

    final wantRatio = fourThree
        ? (isPortrait ? 3 / 4 : 4 / 3)
        : (isPortrait ? 9 / 16 : 16 / 9);

    print('📸 isPortrait=$isPortrait, wantRatio=$wantRatio');

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

      imgOut = img.copyCrop(
        imgOut,
        x: x,
        y: y,
        width: cropW,
        height: cropH,
      );
    }

    await File(shot.path).writeAsBytes(img.encodeJpg(imgOut));
    return shot.path;
  }
}
