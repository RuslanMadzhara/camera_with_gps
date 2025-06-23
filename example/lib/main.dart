import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera_with_gps/camera_with_gps.dart';
import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Uint8List? _imageData;

  Future<void> _capturePhoto() async {

    final path = await CameraWithGps.openCamera(context);
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    final Map<String?, IfdTag>? tags = await readExifFromBytes(bytes);
    final exifData = img.decodeJpgExif(bytes);

    if (tags != null) {
      // Group tags by IFD
      final ifdGroups = <String, Map<String, String>>{};

      for (final entry in tags.entries) {
        if (entry.key == null) continue;

        String group = 'other';
        if (entry.key!.startsWith('Image')) group = 'ifd0';
        else if (entry.key!.startsWith('EXIF')) group = 'exif';
        else if (entry.key!.startsWith('GPS')) group = 'gps';

        ifdGroups.putIfAbsent(group, () => {});
        ifdGroups[group]![entry.key!] = entry.value.printable;
      }

      // Print each group
      for (final group in ifdGroups.keys) {
        print('$group');
        for (final entry in ifdGroups[group]!.entries) {
          print('\t${entry.key}: ${entry.value}');
        }
      }
    }

    // Extract all GPS related tags for display
    final gpsData = <String, String>{};
    if (tags != null) {
      for (final entry in tags.entries) {
        if (entry.key != null && entry.key!.startsWith('GPS')) {
          gpsData[entry.key!] = entry.value.printable;
        }
      }
    }

    setState(() => _imageData = bytes);

    // Display all GPS metadata
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo Metadata'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gpsData.isEmpty)
                const Text('No GPS metadata found')
              else
                ...gpsData.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('${e.key}: ${e.value}'),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    print('DEBUG: Example App - Calling pickFromGallery');
    final path = await CameraWithGps.pickFromGallery(context);
    print('DEBUG: Example App - pickFromGallery returned path: $path');
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    final Map<String?, IfdTag>? tags = await readExifFromBytes(bytes);

    // Print all EXIF data for debugging
    print('===== GALLERY IMAGE EXIF DATA =====');
    if (tags != null) {
      // Group tags by IFD
      final ifdGroups = <String, Map<String, String>>{};

      for (final entry in tags.entries) {
        if (entry.key == null) continue;

        String group = 'other';
        if (entry.key!.startsWith('Image')) group = 'ifd0';
        else if (entry.key!.startsWith('EXIF')) group = 'exif';
        else if (entry.key!.startsWith('GPS')) group = 'gps';

        ifdGroups.putIfAbsent(group, () => {});
        ifdGroups[group]![entry.key!] = entry.value.printable;
      }

      // Print each group
      for (final group in ifdGroups.keys) {
        print('$group');
        for (final entry in ifdGroups[group]!.entries) {
          print('\t${entry.key}: ${entry.value}');
        }
      }

      // Debug logging for GPS data
      print('DEBUG: Example App - GPS data in EXIF:');
      bool hasGpsData = false;
      for (final entry in tags.entries) {
        if (entry.key != null && entry.key!.startsWith('GPS')) {
          hasGpsData = true;
          print('DEBUG: Example App - ${entry.key}: ${entry.value.printable}');
        }
      }
      if (!hasGpsData) {
        print('DEBUG: Example App - No GPS data found in EXIF');
      }
    } else {
      print('DEBUG: Example App - No EXIF data found');
    }

    // Extract all GPS related tags for display
    final gpsData = <String, String>{};
    if (tags != null) {
      for (final entry in tags.entries) {
        if (entry.key != null && entry.key!.startsWith('GPS')) {
          gpsData[entry.key!] = entry.value.printable;
        }
      }
    }

    setState(() => _imageData = bytes);

    // Display all GPS metadata
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Gallery Photo Metadata'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gpsData.isEmpty)
                const Text('No GPS metadata found')
              else
                ...gpsData.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text('${e.key}: ${e.value}'),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera with GPS')),
      body: Center(
        child: _imageData != null
            ? Image.memory(_imageData!, fit: BoxFit.cover)
            : const Text('No image captured yet.'),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickFromGallery,
            heroTag: 'gallery',
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _capturePhoto,
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
