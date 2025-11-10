import 'dart:io';
import 'dart:typed_data';

import 'package:camera_with_gps/camera_with_gps.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
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

  // Common post-capture handler: reads bytes, parses EXIF, shows GPS metadata
  Future<void> _handleCapturedPath(String path) async {
    final bytes = await File(path).readAsBytes();
    final Map<String?, IfdTag>? tags = await readExifFromBytes(bytes);
    final exifData = img.decodeJpgExif(
      bytes,
    ); // keep if you also need binary EXIF

    // Debug print of all EXIF
    // Group tags by IFD for readability
    // (safe in debug; remove if too verbose)
    // ignore: avoid_print
    print('===== EXIF DATA =====');
    if (tags != null) {
      final ifdGroups = <String, Map<String, String>>{};
      for (final entry in tags.entries) {
        if (entry.key == null) continue;
        String group = 'other';
        if (entry.key!.startsWith('Image'))
          group = 'ifd0';
        else if (entry.key!.startsWith('EXIF'))
          group = 'exif';
        else if (entry.key!.startsWith('GPS'))
          group = 'gps';
        ifdGroups.putIfAbsent(group, () => {});
        ifdGroups[group]![entry.key!] = entry.value.printable;
      }
      for (final group in ifdGroups.keys) {
        // ignore: avoid_print
        print(group);
        for (final entry in ifdGroups[group]!.entries) {
          // ignore: avoid_print
          print('\t${entry.key}: ${entry.value}');
        }
      }
    }

    // Extract GPS tags for the dialog
    final gpsData = <String, String>{};
    if (tags != null) {
      for (final entry in tags.entries) {
        if (entry.key != null && entry.key!.startsWith('GPS')) {
          gpsData[entry.key!] = entry.value.printable;
        }
      }
    }

    setState(() => _imageData = bytes);

    // Show GPS-only metadata
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Photo Metadata'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gpsData.isEmpty)
                    const Text('No GPS metadata found')
                  else
                    ...gpsData.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('${e.key}: ${e.value}'),
                      ),
                    ),
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

  // Default flow: camera UI with gallery button (existing)
  Future<void> _capturePhoto() async {
    final path = await CameraWithGps.openCamera(context);
    if (path == null) return;
    await _handleCapturedPath(path);
  }

  // New flow: camera UI with NO gallery button
  Future<void> _capturePhotoNoGallery() async {
    final path = await CameraWithGps.openCameraPhotoOnly(context);
    if (path == null) return;
    await _handleCapturedPath(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera with GPS')),
      body: Center(
        child:
            _imageData != null
                ? Image.memory(_imageData!, fit: BoxFit.cover)
                : const Text('No image captured yet.'),
      ),
      // Two FABs: default (with gallery) and no-gallery
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_with_gallery',
              onPressed: _capturePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: 'fab_no_gallery',
              onPressed: _capturePhotoNoGallery,
              icon: const Icon(Icons.photo_camera_back),
              label: const Text('No gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
