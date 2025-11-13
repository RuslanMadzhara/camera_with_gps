import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;

import 'photo_processor_android.dart';
import 'photo_processor_ios.dart';

/// Platform-agnostic PhotoProcessor that delegates to platform-specific implementations
class PhotoProcessor {
  static Future<String> process({
    required XFile shot,
    required DeviceOrientation orientation,
    required bool fourThree,
  }) async {
    if (Platform.isIOS) {
      return PhotoProcessorIOS.process(
        shot: shot,
        orientation: orientation,
        fourThree: fourThree,
      );
    } else {
      return PhotoProcessorAndroid.process(
        shot: shot,
        orientation: orientation,
        fourThree: fourThree,
      );
    }
  }
}