import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera_with_gps/camera_with_gps.dart';
import 'package:exif/exif.dart';

void main() {
  runApp(MaterialApp(
    // The navigatorKey is no longer needed
    home: const TestPage(),
  ));
}

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Uint8List? _imageData;

  Future<void> _capturePhoto() async {
    // Pass BuildContext to openCamera
    final path = await CameraWithGps.openCamera(context);
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error capturing photo')),
      );
      return;
    }

    final bytes = await File(path).readAsBytes();
    final Map<String?, IfdTag>? tags = await readExifFromBytes(bytes);

    final lat = tags?['GPS GPSLatitude']?.printable;
    final latRef = tags?['GPS GPSLatitudeRef']?.printable;
    final lon = tags?['GPS GPSLongitude']?.printable;
    final lonRef = tags?['GPS GPSLongitudeRef']?.printable;

    setState(() => _imageData = bytes);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo Metadata'),
        content: Text(
          (lat != null && lon != null)
              ? 'Latitude: $lat $latRef\nLongitude: $lon $lonRef'
              : 'No GPS metadata found',
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
      appBar: AppBar(
        title: const Text('Camera with GPS'),
      ),
      body: Center(
        child: _imageData != null
            ? Image.memory(_imageData!, fit: BoxFit.cover)
            : const Text('No image captured yet.'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _capturePhoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
