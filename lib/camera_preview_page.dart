import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_with_gps.dart';

class CameraPreviewPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraPreviewPage({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  late CameraController _controller;
  bool _isCapturing = false;
  bool _isFlashOn = false;
  int _cameraIndex = 0;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.cameras.length; i++) {
      if (widget.cameras[i].lensDirection == CameraLensDirection.back) {
        _cameraIndex = i;
        break;
      }
    }
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isInitialized = false;
      });
    }

    try {
      _controller = CameraController(
        widget.cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller.initialize();
      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.torch);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_isInitialized) return;

    try {
      setState(() => _isCapturing = true);
      final file = await _controller.takePicture();
      final pos = await Geolocator.getCurrentPosition();

      final success = await CameraWithGps.addGps(
        path: file.path,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      if (mounted) {
        Navigator.of(context).pop(success ? file.path : null);
      }
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (!_isInitialized) return;

    try {
      setState(() {
        _isInitialized = false;
      });

      int? frontCameraIndex;
      int? backCameraIndex;

      for (int i = 0; i < widget.cameras.length; i++) {
        if (widget.cameras[i].lensDirection == CameraLensDirection.front) {
          frontCameraIndex = i;
        } else if (widget.cameras[i].lensDirection == CameraLensDirection.back) {
          backCameraIndex = i;
        }
      }

      if (widget.cameras[_cameraIndex].lensDirection == CameraLensDirection.front) {
        if (backCameraIndex != null) _cameraIndex = backCameraIndex;
      } else {
        if (frontCameraIndex != null) _cameraIndex = frontCameraIndex;
      }

      await _controller.dispose();

      _controller = CameraController(
        widget.cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller.initialize();

      if (_isFlashOn) {
        await _controller.setFlashMode(FlashMode.torch);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error switching camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch camera: $e')),
        );
        _initializeCamera();
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isInitialized) return;

    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller.setFlashMode(newMode);
      if (mounted) {
        setState(() => _isFlashOn = !_isFlashOn);
      }
    } catch (e) {
      print('Error toggling flash: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle flash: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final pos = await Geolocator.getCurrentPosition();
        final success = await CameraWithGps.addGps(
          path: picked.path,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        if (mounted) {
          Navigator.of(context).pop(success ? picked.path : null);
        }
      }
    } catch (e) {
      print('Error picking from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (e) {
      print('Error disposing camera controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _initializeCamera();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_isInitialized)
            Center(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.previewSize!.height,
                  height: _controller.value.previewSize!.width,
                  child: CameraPreview(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          if (_isInitialized && _errorMessage == null) ...[
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width / 2 - 35,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: _isCapturing ? null : _capturePhoto,
                child: _isCapturing
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: _toggleFlash,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.cameraswitch,
                    color: Colors.white, size: 30),
                onPressed: _switchCamera,
              ),
            ),
          ],
          Positioned(
            bottom: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.photo_library,
                  color: Colors.white, size: 30),
              onPressed: _pickFromGallery,
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}