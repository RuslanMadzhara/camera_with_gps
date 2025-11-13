import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'camera_with_gps_method_channel.dart';

abstract class CameraWithGpsPlatform extends PlatformInterface {
  /// Constructs a CameraWithGpsPlatform.
  CameraWithGpsPlatform() : super(token: _token);

  static final Object _token = Object();

  static CameraWithGpsPlatform _instance = MethodChannelCameraWithGps();

  /// The default instance of [CameraWithGpsPlatform] to use.
  ///
  /// Defaults to [MethodChannelCameraWithGps].
  static CameraWithGpsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CameraWithGpsPlatform] when
  /// they register themselves.
  static set instance(CameraWithGpsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
