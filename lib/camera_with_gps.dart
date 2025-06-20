import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'camera_preview_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CameraWithGps {
  static const MethodChannel _channel = MethodChannel('camera_with_gps');

  static Future<String?> openCamera(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device.');
      }

      final resultPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CameraPreviewPage(cameras: cameras),
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

  static Future<String?> pickFromGallery(BuildContext context) async {
    String? path;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final brand = (deviceInfo.brand).toLowerCase();
      final manufacturer = (deviceInfo.manufacturer).toLowerCase();
      final model = (deviceInfo.model).toLowerCase();

      final isSamsung = brand.contains('samsung') ||
          manufacturer.contains('samsung') ||
          model.startsWith('sm-');

      if (isSamsung) {
        try {
          path = await _channel.invokeMethod<String>('openDocumentImage');
          if (path == null) return null;
        } catch (e) {
          debugPrint('❌ Error opening document picker: $e');
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked == null) return null;
          path = picked.path;
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return null;
        path = picked.path;
      }

      // Check GPS after path is obtained
      if (path != null) {
        final status = await _channel.invokeMethod<String>('checkGps', {'path': path});
        if (status == 'FAKE') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Missing coordinates"),
              content: const Text(
                  "Your device did not save coordinates or removed them from the photo. Add current coordinates?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("No")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Yes")),
              ],
            ),
          );

          if (confirm == true) {
            final pos = await Geolocator.getCurrentPosition();
            await addGps(path: path, latitude: pos.latitude, longitude: pos.longitude);
          }
        }
      }

      return path;
    } else {
      // iOS or other platforms
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      return picked?.path;
    }
  }


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

  static Future<bool> removeGps({required String path}) async {
    final dynamic result = await _channel.invokeMethod(
      'convertPhoto',
      {'path': path},
    );
    return result == true || (result is String && result.isNotEmpty);
  }
}
