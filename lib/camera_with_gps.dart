import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'camera_preview_page.dart';
import 'package:image_picker/image_picker.dart';

class CameraWithGps {
  static const MethodChannel _channel = MethodChannel('camera_with_gps');

  /// Відкриває повноекранну камеру або вибір з галереї
  static Future<String?> openCamera(BuildContext context) async {
    try {
      // Check location permission (but don't require GPS to be enabled)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // We allow camera to open even if location permission is denied
        // The warning will be displayed on the camera preview page
      }
      // We allow camera to open even if location permission is permanently denied
      // The warning will be displayed on the camera preview page

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device.');
      }

      // Let the CameraPreviewPage handle controller initialization and disposal
      final resultPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CameraPreviewPage(
            cameras: cameras,
          ),
        ),
      );

      return resultPath;
    } catch (e) {
      print('Error opening camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open camera: $e')),
      );
      return null;
    }
  }

  static Future<String?> pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    return picked?.path;
  }

  /// Додає GPS-метадані до фото
  static Future<bool> addGps({
    required String path,
    required double latitude,
    required double longitude,
  }) async {
    final dynamic result = await _channel.invokeMethod(
      'convertPhoto',
      {'path': path, 'latitude': latitude, 'longitude': longitude},
    );
    return result == true || (result is String && result.isNotEmpty);
  }
}
