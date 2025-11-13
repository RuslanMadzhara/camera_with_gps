# Camera with GPS

A Flutter plugin for capturing photos with embedded GPS metadata. This package provides a simple way to take photos and automatically embed the current GPS coordinates into the image's EXIF data.

[![pub package](https://img.shields.io/pub/v/camera_with_gps.svg)](https://pub.dev/packages/camera_with_gps)

## Features

- 📸 **Take photos with a customizable camera interface**
- 🌍 **Automatically embed GPS coordinates into photo metadata**
- 🔄 **Platform-optimized orientation handling**
  - iOS: Adaptive preview that rotates with device orientation
  - Android: Portrait-locked UI with landscape photo support
- 🔦 **Flash control** with torch mode
- 📱 **Camera switching** (front/back)
- 📐 **Aspect ratio toggling** (16:9 or 4:3)
- 🖼️ **Gallery image picking** with optional toggle
  - Enable/disable gallery button in camera UI
  - `openCamera(context, allowGallery: true/false)`
  - `openCameraPhotoOnly(context)` - camera-only mode
- ⚠️ **GPS status warnings** (disabled, permission denied, etc.)
- 🔍 **Smart GPS metadata handling**
  - Automatic removal of fake/invalid GPS data
  - Optimized for Samsung Galaxy S series phones
  - Manual GPS addition/removal methods
- 📱 **Full Android and iOS support**
- 🎯 **Accurate orientation detection** via device sensors
- 🖼️ **Proper photo rotation** for all device orientations

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
  camera_with_gps: ^2.3.0
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

// Open camera with gallery access (default)
Future<void> takePhotoWithGallery(BuildContext context) async {
  final String? imagePath = await CameraWithGps.openCamera(
    context,
    allowGallery: true, // Show gallery button (default)
  );

  if (imagePath != null) {
    print('Image saved at: $imagePath');
  }
}

// Open camera without gallery access (photo-only mode)
Future<void> takePhotoOnly(BuildContext context) async {
  final String? imagePath = await CameraWithGps.openCameraPhotoOnly(context);

  if (imagePath != null) {
    print('Photo captured at: $imagePath');
  }
}

// Pick an image from gallery
Future<void> pickImageFromGallery() async {
  final String? imagePath = await CameraWithGps.pickFromGallery();

  if (imagePath != null) {
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

// Remove GPS data from an image
Future<void> removeGPSFromImage(String imagePath) async {
  final bool success = await CameraWithGps.removeGps(path: imagePath);

  if (success) {
    print('GPS data removed successfully');
  } else {
    print('Failed to remove GPS data');
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
```dart
static Future<String?> openCamera(
  BuildContext context, {
  bool allowGallery = true,
})
```

Opens a full-screen camera interface for taking photos with optional gallery access.

**Parameters:**
- `context`: The BuildContext used for navigation
- `allowGallery`: Whether to show the gallery button in the camera UI (default: `true`)

**Returns:**
- A `Future<String?>` that resolves to the path of the captured/selected image, or `null` if cancelled

**Features:**
- Automatically embeds GPS coordinates if location permission is granted
- Displays GPS status warnings when disabled or permission denied
- Supports flash control, camera switching, and aspect ratio toggling
- Optional gallery button for selecting existing photos

### CameraWithGps.openCameraPhotoOnly

**Signature:**
```dart
static Future<String?> openCameraPhotoOnly(BuildContext context)
```

Convenience method to open the camera **without** gallery access (photo-only flow).

**Parameters:**
- `context`: The BuildContext used for navigation

**Returns:**
- A `Future<String?>` that resolves to the path of the captured image, or `null` if cancelled

### CameraWithGps.pickFromGallery

**Signature:**
```dart
static Future<String?> pickFromGallery()
```

Opens the device's gallery to select an existing image.

**Returns:**
- A `Future<String?>` that resolves to the path of the selected image, or `null` if no image was selected

### CameraWithGps.addGps

**Signature:**
```dart
static Future<bool> addGps({
  required String path,
  required double latitude,
  required double longitude,
})
```

Adds GPS coordinates to an existing image file's EXIF metadata.

**Parameters:**
- `path`: The file path of the image
- `latitude`: The latitude coordinate to embed
- `longitude`: The longitude coordinate to embed

**Returns:**
- A `Future<bool>` that resolves to `true` if successful, `false` otherwise

**Note:** Automatically removes any existing fake or invalid GPS data before adding new coordinates.

### CameraWithGps.removeGps

**Signature:**
```dart
static Future<bool> removeGps({required String path})
```

Removes GPS coordinates from an image file's EXIF metadata.

**Parameters:**
- `path`: The file path of the image

**Returns:**
- A `Future<bool>` that resolves to `true` if successful, `false` otherwise

**Use case:** Useful when fake coordinates are detected or privacy concerns require GPS data removal.

## Features and Limitations

- The camera interface supports both portrait and landscape orientations.
- GPS data is only added if location services are enabled and permission is granted.
- Warning messages are displayed when GPS is disabled or permission is denied.
- The camera can still be used even if GPS is disabled or permission is denied.
- Images selected from the gallery do not automatically have GPS data added.

## Architecture

The plugin is designed with a modular architecture for better maintainability and testability:

```
lib/
├── main.dart                    ← usual MyApp / routes
│
├── pages/
│   └── camera_preview_page.dart ← stateful shell, holds controller & app-level state
│
├── services/
│   └── orientation_service.dart ← singleton sensor stream
│
├── utils/
│   └── photo_processor.dart     ← pure image/EXIF logic
│
└── widgets/
    ├── rot_icon.dart            ← orientation-aware icon
    ├── gps_banner.dart          ← GPS status warning
    ├── top_bar.dart             ← camera controls (flash, ratio)
    ├── bottom_bar.dart          ← camera controls (shutter, gallery, switch)
    ├── preview_box.dart         ← camera preview with aspect ratio handling
    ├── shutter_button.dart      ← camera shutter button with loading state
    └── error_ui.dart            ← error display with retry option
```

This modular structure allows for:
- Easier testing of individual components
- Clear separation of concerns
- Better code organization
- Improved maintainability

## Samsung Galaxy S Series Compatibility

### Enhanced GPS Metadata Storage for Samsung Galaxy S Series Phones

This plugin provides **specialized support for Samsung Galaxy S series smartphones** (including Samsung Galaxy S10, S20, S21, S22, S23, and S24 models) with optimized GPS metadata handling. Key benefits include:

- **Reliable GPS data storage** specifically tested and optimized for Samsung Galaxy S series devices
- **Accurate location tagging** that preserves precise GPS coordinates in Samsung's gallery app
- **Compatible with Samsung's photo management system** ensuring GPS data remains intact when viewing or sharing photos
- **Optimized for Samsung OneUI** and its camera integration
- **Enhanced metadata preservation** when transferring photos from Samsung Galaxy S series phones to other devices or cloud storage

Our plugin addresses common issues with GPS metadata loss that can occur with standard camera implementations on Samsung devices. If you're developing applications for Samsung Galaxy S series users who need reliable location tagging in their photos, this plugin offers the specialized support required.

For Samsung Galaxy S series users: This plugin ensures your photos maintain their GPS location data throughout the entire photo lifecycle - from capture to sharing.

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
