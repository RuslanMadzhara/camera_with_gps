# Camera with GPS

A Flutter plugin for capturing photos with embedded GPS metadata. This package provides a simple way to take photos and automatically embed the current GPS coordinates into the image's EXIF data.

[![pub package](https://img.shields.io/pub/v/camera_with_gps.svg)](https://pub.dev/packages/camera_with_gps)

## Features

- 📸 Take photos with a customizable camera interface
- 🌍 Automatically embed GPS coordinates into photo metadata
- 🔄 Support for both portrait and landscape orientations
- 🔦 Flash control
- 📱 Camera switching (front/back)
- 📐 Aspect ratio toggling (16:9 or 4:3)
- 🖼️ Gallery image picking
- ⚠️ GPS status warnings (disabled, permission denied, etc.)
- 📱 Support for both Android and iOS

## Requirements

### Android

Add the following permissions to your `AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS

Add the following keys to your `Info.plist` file:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos with GPS metadata</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to add GPS metadata to photos</string>
```

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  camera_with_gps: ^1.1.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:camera_with_gps/camera_with_gps.dart';
import 'package:flutter/material.dart';

// Open camera and take a photo with GPS metadata
Future<void> takePhotoWithGPS(BuildContext context) async {
  final String? imagePath = await CameraWithGps.openCamera(context);

  if (imagePath != null) {
    // Use the image path as needed
    print('Image saved at: $imagePath');
  }
}

// Pick an image from gallery
Future<void> pickImageFromGallery() async {
  final String? imagePath = await CameraWithGps.pickFromGallery();

  if (imagePath != null) {
    // Use the image path as needed
    print('Image selected from gallery: $imagePath');
  }
}

// Manually add GPS data to an existing image
Future<void> addGPSToImage(String imagePath, double latitude, double longitude) async {
  final bool success = await CameraWithGps.addGps(
    path: imagePath,
    latitude: latitude,
    longitude: longitude,
  );

  if (success) {
    print('GPS data added successfully');
  } else {
    print('Failed to add GPS data');
  }
}
```

### Complete Example

See the [example](https://github.com/RuslanMadzhara/camera_with_gps/tree/main/example) directory for a complete sample application.

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera_with_gps/camera_with_gps.dart';
import 'package:exif/exif.dart';

class CameraExample extends StatefulWidget {
  const CameraExample({Key? key}) : super(key: key);

  @override
  State<CameraExample> createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  Uint8List? _imageData;
  Map<String, String> _gpsData = {};

  Future<void> _capturePhoto() async {
    final path = await CameraWithGps.openCamera(context);
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    final tags = await readExifFromBytes(bytes);

    // Extract GPS data
    final gpsData = <String, String>{};
    if (tags != null) {
      for (final entry in tags.entries) {
        if (entry.key != null && entry.key!.startsWith('GPS')) {
          gpsData[entry.key!] = entry.value.printable;
        }
      }
    }

    setState(() {
      _imageData = bytes;
      _gpsData = gpsData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera with GPS Example')),
      body: Center(
        child: _imageData != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.memory(_imageData!, height: 300),
                  const SizedBox(height: 20),
                  Text('GPS Data:'),
                  ..._gpsData.entries.map((e) => Text('${e.key}: ${e.value}')),
                ],
              )
            : const Text('No image captured yet.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _capturePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
```

## API Reference

### CameraWithGps.openCamera

**Signature:**
`static Future<String?> openCamera(BuildContext context)`

Opens a camera interface that allows the user to take a photo. If GPS is enabled and permission is granted, the photo will automatically have GPS coordinates embedded in its metadata.

**Parameters:**
- `context`: The BuildContext used for navigation.

**Returns:**
- A `Future<String?>` that resolves to the path of the captured image, or `null` if the operation was cancelled or failed.

### CameraWithGps.pickFromGallery

**Signature:**
`static Future<String?> pickFromGallery()`

Opens the device's gallery to select an existing image.

**Returns:**
- A `Future<String?>` that resolves to the path of the selected image, or `null` if no image was selected.

### CameraWithGps.addGps

**Signature:**
`static Future<bool> addGps({required String path, required double latitude, required double longitude})`

Adds GPS coordinates to an existing image file.

**Parameters:**
- `path`: The file path of the image.
- `latitude`: The latitude coordinate to embed.
- `longitude`: The longitude coordinate to embed.

**Returns:**
- A `Future<bool>` that resolves to `true` if the operation was successful, or `false` otherwise.

## Features and Limitations

- The camera interface supports both portrait and landscape orientations.
- GPS data is only added if location services are enabled and permission is granted.
- Warning messages are displayed when GPS is disabled or permission is denied.
- The camera can still be used even if GPS is disabled or permission is denied.
- Images selected from the gallery do not automatically have GPS data added.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Contact

Developer: [Ruslan Madzhara](https://www.linkedin.com/in/ruslan-madzhara-118714236/)

