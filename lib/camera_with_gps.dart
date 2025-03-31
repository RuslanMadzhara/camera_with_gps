import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'camera_preview_page.dart';

/// The main plugin class for capturing photos and embedding GPS EXIF metadata.
class CameraWithGps {
  static const MethodChannel _channel = MethodChannel('camera_with_gps');

  /// Launches a full-screen camera UI.
  /// Returns the local file path if successful.
  /// This method now accepts a [BuildContext] parameter for navigation.
  static Future<String?> openCamera(BuildContext context) async {
    // 1) Check if location services are enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }

    // 2) Check and request location permissions
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

    // 3) Initialize the camera
    final cameras = await availableCameras();
    final controller = CameraController(cameras.first, ResolutionPreset.high);
    // Do NOT dispose the controller here – the CameraPreviewPage will handle it.
    await controller.initialize();

    // 4) Navigate to the camera page
    final resultPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CameraPreviewPage(controller)),
    );

    // Do NOT call controller.dispose() here – the page will do it.
    return resultPath;
  }

  /// Adds GPS metadata to the photo at [path] if it's missing.
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

    // iOS/Android might return either a bool or a String.
    return result == true || (result is String && result.isNotEmpty);
  }
}
