import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_with_gps_platform_interface.dart';

/// An implementation of [CameraWithGpsPlatform] that uses method channels.
class MethodChannelCameraWithGps extends CameraWithGpsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('camera_with_gps');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
