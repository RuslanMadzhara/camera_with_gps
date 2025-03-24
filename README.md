Below is a neatly formatted version of the README for the **Camera With GPS Flutter Plugin**:

---

# Camera With GPS Flutter Plugin

A Flutter plugin for capturing photos with embedded GPS metadata. It provides a full-screen camera experience and automatically tags photos with the device's location (latitude and longitude).

---

## Overview

**CameraWithGps** offers:

- **Full-screen camera UI:** For high-resolution photo capture.
- **Automatic GPS metadata:** Embeds latitude and longitude into photos.
- **Cross-platform support:** Works on both iOS and Android.
- **Lightweight & efficient:** Easy integration into your Flutter projects.

---

## Installation

1. **Add the dependency** to your `pubspec.yaml` file:

   ```yaml
   dependencies:
     camera_with_gps: ^1.0.0
   ```

2. **Install the package** by running:

   ```shell
   flutter pub get
   ```

---

## Platform Setup

### Android

1. **Permissions:** Add the following to your `AndroidManifest.xml`:

   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-feature android:name="android.hardware.camera" />
   <uses-feature android:name="android.hardware.location.gps" />
   ```

2. **Minimum SDK:** Ensure your `android/app/build.gradle` includes:

   ```text
   android {
     defaultConfig {
       minSdkVersion 21 // Ensure minSdkVersion is 21 or higher
       ...
     }
   }
   ```

3. **Runtime Permissions:** Make sure your app requests location permissions during runtime as needed.

### iOS

1. **Info.plist:** Add these keys for camera and location usage:

   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app requires camera access to take photos.</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app requires location access to add GPS data to photos.</string>
   ```

2. **Image I/O Framework:** Ensure it is included in your project.

---

## Usage

### Importing the Plugin

Include the package in your Dart file:

```dart
import 'package:camera_with_gps/camera_with_gps.dart';
```

### Initializing the Plugin

Assign the plugin’s `navigatorKey` to your app’s Navigator:

```dart
void main() {
  runApp(MaterialApp(
    navigatorKey: CameraWithGps.navigatorKey,
    home: const MyApp(),
  ));
}
```

### Opening the Camera

Launch the camera UI and capture a photo:

```dart
Future<void> openCamera() async {
  try {
    final photoPath = await CameraWithGps.openCamera();
    if (photoPath != null) {
      print('Photo saved at: $photoPath');
    }
  } catch (e) {
    print('Failed to open camera: $e');
  }
}
```

### Embedding GPS Metadata

To manually add GPS metadata, call:

```dart
final success = await CameraWithGps.addGps(
  path: '/path/to/photo.jpg',
  latitude: 37.4219983,
  longitude: -122.084,
);
print(success ? "GPS metadata added!" : "Failed to add GPS metadata.");
```

---

## Structure

The plugin consists of the following components:

1. **CameraWithGps:** Main class handling camera launching and EXIF editing.
2. **CameraPreviewPage:** Provides the full-screen UI for capturing photos.
3. **CameraWithGpsPlugin (Kotlin):** Manages Android EXIF metadata and native communication.
4. **CameraWithGpsPlugin (Swift):** Manages iOS EXIF metadata and native communication.

---

## API Reference

| Method                               | Description                                                                          |
|--------------------------------------|--------------------------------------------------------------------------------------|
| `openCamera()`                       | Opens the camera interface and returns the file path of the captured photo.          |
| `addGps(String, double, double)`     | Embeds GPS data (latitude and longitude) into an image file. Returns success/failure.  |

---

## Example

Below is a complete example of using the plugin in a Flutter application:

```dart
import 'package:camera_with_gps/camera_with_gps.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    navigatorKey: CameraWithGps.navigatorKey,
    home: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _capturePhoto() async {
    try {
      final path = await CameraWithGps.openCamera();
      if (path != null) {
        print('Photo captured at: $path');
      } else {
        print('Capture canceled or failed.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera With GPS Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: _capturePhoto,
          child: const Text('Capture Photo'),
        ),
      ),
    );
  }
}
```

---

## Cross-platform Implementation

### Android

- **GPS Metadata Handling:** Uses Android's `ExifInterface` from Jetpack.
- **Key File:** `CameraWithGpsPlugin.kt` handles native communication and metadata embedding.

### iOS

- **GPS Metadata Handling:** Uses the `Image I/O` framework.
- **Key File:** `CameraWithGpsPlugin.swift` handles native communication and metadata embedding.

---

## Contributing

Contributions are welcome! To contribute:

1. **Fork** the repository.
2. **Create** a new branch for your feature or bug fix.
3. **Make** your enhancements or corrections.
4. **Submit** a pull request.

---

## License

Released under the [MIT License](https://opensource.org/licenses/MIT). Feel free to use, modify, and distribute.

---

## Changelog

### v1.0.0

- Initial release.
- Full-screen camera integration for Flutter.
- GPS metadata embedding for iOS and Android.

---

## Maintainers

Developed and maintained by https://www.linkedin.com/in/ruslan-madzhara-118714236/.  
For queries or support, please [contact us](mailto:ruslan.madzharaa@gmail.com).

---

This plugin is available on [pub.dev](https://pub.dev/packages/camera_with_gps) for easy access and installation.

---