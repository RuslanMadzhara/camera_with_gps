import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show DeviceOrientation;

class PhotoProcessorIOS {
  static Future<String> process({
    required XFile shot,
    required DeviceOrientation orientation,
    required bool fourThree,
  }) async {
    print('📸 iOS PhotoProcessor: orientation = $orientation');

    final bytes = await shot.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return shot.path;

    img.Image imgOut = decoded;
    print('📸 iOS: original size = ${decoded.width}x${decoded.height}');

    // iOS rotation logic
    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        print('📸 iOS: rotating 90° (landscapeLeft)');
        imgOut = img.copyRotate(imgOut, angle: 90);
        break;
      case DeviceOrientation.landscapeRight:
        print('📸 iOS: rotating 270° (landscapeRight)');
        imgOut = img.copyRotate(imgOut, angle: 270);
        break;
      case DeviceOrientation.portraitDown:
        print('📸 iOS: rotating 180° (portraitDown)');
        imgOut = img.copyRotate(imgOut, angle: 180);
        break;
      default:
        print('📸 iOS: no rotation (portraitUp or unknown)');
        break;
    }

    print('📸 iOS: after rotation size = ${imgOut.width}x${imgOut.height}');

    // iOS: додаткова корекція для landscape
    if (orientation == DeviceOrientation.landscapeLeft) {
      // Ліва сторона: потрібен додатковий поворот на 270° (або -90°)
      print('📸 iOS: applying additional 270° correction for landscapeLeft');
      imgOut = img.copyRotate(imgOut, angle: 270);
      print('📸 iOS: after correction size = ${imgOut.width}x${imgOut.height}');
    } else if (orientation == DeviceOrientation.landscapeRight) {
      // Права сторона: потрібен додатковий поворот на 90°
      print('📸 iOS: applying additional 90° correction for landscapeRight');
      imgOut = img.copyRotate(imgOut, angle: 90);
      print('📸 iOS: after correction size = ${imgOut.width}x${imgOut.height}');
    }

    // === cropping ===
    final w = imgOut.width, h = imgOut.height;
    // iOS: визначаємо орієнтацію за фактичними розмірами (після повороту)
    final isPortrait = h > w;
    final wantRatio = fourThree
        ? (isPortrait ? 3 / 4 : 4 / 3)
        : (isPortrait ? 9 / 16 : 16 / 9);

    print('📸 iOS: isPortrait=$isPortrait, wantRatio=$wantRatio');

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
