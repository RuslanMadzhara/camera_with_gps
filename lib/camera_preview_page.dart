import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'camera_with_gps.dart';

/// A separate, full-screen camera preview page.
/// This page is responsible for disposing [CameraController].
class CameraPreviewPage extends StatefulWidget {
  final CameraController controller;
  const CameraPreviewPage(this.controller, {Key? key}) : super(key: key);

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  bool _isCapturing = false;

  /// Capture a photo, embed GPS, pop the result path or null
  Future<void> _capturePhoto() async {
    if (_isCapturing || !widget.controller.value.isInitialized) return;
    setState(() => _isCapturing = true);

    final file = await widget.controller.takePicture();
    final pos = await Geolocator.getCurrentPosition();

    final success = await CameraWithGps.addGps(
      path: file.path,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );

    if (mounted) {
      Navigator.of(context).pop(success ? file.path : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(fit: StackFit.expand, children: [
        CameraPreview(widget.controller),
        Positioned(
          bottom: 20,
          left: MediaQuery.of(context).size.width / 2 - 35,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: _capturePhoto,
            child: const Icon(Icons.camera_alt, color: Colors.black),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    // We dispose the controller here, so no 'disposed camera' errors occur later.
    widget.controller.dispose();
    super.dispose();
  }
}
