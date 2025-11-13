import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../pages/camera_preview_page.dart';

class CameraWithGps {
  static const MethodChannel _channel = MethodChannel('camera_with_gps');

  /// Open the full-screen camera preview.
  /// [allowGallery] — whether to show the gallery button in the camera UI.
  static Future<String?> openCamera(
    BuildContext context, {
    bool allowGallery = true,
  }) async {
    try {
      // Location: do not block the camera if permission is denied,
      // the preview page can show a warning if needed.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      // Cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available on this device.');
      }

      // Controller lifecycle is handled by CameraPreviewPage.
      final resultPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CameraPreviewPage(
            cameras: cameras,
            allowGallery: allowGallery,
          ),
        ),
      );

      return resultPath;
    } catch (e) {
      debugPrint('Error opening camera: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
      return null;
    }
  }

  /// Convenience helper:
  /// Open the camera **without** gallery access (photo-only flow).
  static Future<String?> openCameraPhotoOnly(BuildContext context) {
    return openCamera(context, allowGallery: false);
  }

  /// Smart gallery picker:
  ///  - Samsung (Android) → файловий менеджер (SAF / ACTION_OPEN_DOCUMENT)
  ///  - інші → стандартна галерея (ImagePicker)
  static Future<String?> pickFromGallery() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        final brand = (info.brand ?? '').toLowerCase();
        final manufacturer = (info.manufacturer ?? '').toLowerCase();
        final model = (info.model ?? '').toLowerCase();

        final isSamsung = brand.contains('samsung') ||
            manufacturer.contains('samsung') ||
            model.startsWith('sm-');

        String? path;

        if (isSamsung) {
          // 🔹 Samsung → відкриваємо файловий менеджер / документ-пікер
          try {
            path = await _channel.invokeMethod<String>('openDocumentImage');
          } on PlatformException catch (e) {
            debugPrint(
                'openDocumentImage failed on Samsung, fallback to gallery: $e');
          }
        }

        // Якщо не Samsung або SAF не спрацював → стандартна галерея
        if (path == null || path.isEmpty) {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          path = picked?.path;
        }

        if (path == null) return null;

        // Перевіряємо GPS через native checkGps; якщо FAKE → чистимо
        try {
          final status =
              await _channel.invokeMethod<String>('checkGps', {'path': path});
          if (status == 'FAKE') {
            await removeGps(path: path);
          }
        } catch (e) {
          debugPrint('checkGps/removeGps error: $e');
        }

        return path;
      } else {
        // iOS / інші платформи — просто галерея
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        return picked?.path;
      }
    } catch (e) {
      debugPrint('pickFromGallery error: $e');
      return null;
    }
  }

  /// Add GPS EXIF to a saved photo (implemented natively via MethodChannel).
  static Future<bool> addGps({
    required String path,
    required double latitude,
    required double longitude,
  }) async {
    final dynamic result = await _channel.invokeMethod(
      'convertPhoto',
      {
        'path': path,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return result == true || (result is String && result.isNotEmpty);
  }

  /// Remove GPS EXIF from a photo — useful if fake coordinates are detected.
  static Future<bool> removeGps({required String path}) async {
    final dynamic result =
        await _channel.invokeMethod('removeGps', {'path': path});
    return result == true || (result is String && result.isNotEmpty);
  }
}
