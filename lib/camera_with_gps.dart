import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'camera_preview_page.dart';

/// The main plugin class for capturing photos and embedding GPS EXIF metadata.
class CameraWithGps {
  /// This [navigatorKey] is used to push the full‑screen camera page from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const MethodChannel _channel = MethodChannel('camera_with_gps');

  /// Launches a full‑screen camera UI. Returns the local file path if successful.
  static Future<String?> openCamera() async {
    // 1) Check location services
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }

    // 2) Check & request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    // 3) Initialize camera
    final cameras = await availableCameras();
    final controller = CameraController(cameras.first, ResolutionPreset.high);
    // We do NOT dispose here. The page will handle dispose.
    await controller.initialize();

    // 4) Push the camera page
    final resultPath = await Navigator.of(navigatorKey.currentContext!).push<String>(
      MaterialPageRoute(builder: (_) => CameraPreviewPage(controller)),
    );

    // Do NOT call controller.dispose() here – the page will do it.
    return resultPath;
  }

  /// Adds GPS metadata if missing in the file at [path].
  /// Returns true if successful, false otherwise.
  static Future<bool> addGps({
    required String path,
    required double latitude,
    required double longitude,
  }) async {
    final dynamic result = await _channel.invokeMethod(
      'convertPhoto',
      {'path': path, 'latitude': latitude, 'longitude': longitude},
    );

    // Because iOS/Android might return either bool or String
    return result == true || (result is String && result.isNotEmpty);
  }
}
