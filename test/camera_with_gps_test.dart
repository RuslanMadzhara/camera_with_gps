// import 'package:flutter_test/flutter_test.dart';
// import 'package:camera_with_gps/camera_with_gps.dart';
// import 'package:camera_with_gps/camera_with_gps_platform_interface.dart';
// import 'package:camera_with_gps/camera_with_gps_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockCameraWithGpsPlatform
//     with MockPlatformInterfaceMixin
//     implements CameraWithGpsPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final CameraWithGpsPlatform initialPlatform = CameraWithGpsPlatform.instance;
//
//   test('$MethodChannelCameraWithGps is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelCameraWithGps>());
//   });
//
//   test('getPlatformVersion', () async {
//     CameraWithGps cameraWithGpsPlugin = CameraWithGps();
//     MockCameraWithGpsPlatform fakePlatform = MockCameraWithGpsPlatform();
//     CameraWithGpsPlatform.instance = fakePlatform;
//
//     expect(await cameraWithGpsPlugin.getPlatformVersion(), '42');
//   });
// }
