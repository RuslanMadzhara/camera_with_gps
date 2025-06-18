import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'camera_with_gps.dart';

/* ───────────────── helper: rotated icon ───────────────── */
class _RotIcon extends StatelessWidget {
  const _RotIcon({
    required this.orientation,
    required this.icon,
    required this.onPressed,
    this.size = 30,
  });

  final DeviceOrientation orientation;
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    int turns;
    switch (orientation) {
      case DeviceOrientation.landscapeLeft:
        turns = 1;   // +90°
        break;
      case DeviceOrientation.landscapeRight:
        turns = 3;   // −90° (270°)
        break;
      default: // portraitUp та інші
        turns = 0;
    }

    return RotatedBox(
      quarterTurns: turns,
      child: IconButton(
        icon: Icon(icon, size: size, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/* ───────────────── GPS banner ───────────────── */
class _GpsBanner extends StatelessWidget {
  const _GpsBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color.fromRGBO(255, 0, 0, 0.8),
          child: Text(
            message,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

/* ───────────────── main page ───────────────── */
class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage>
    with WidgetsBindingObserver {
  /* camera */
  late CameraController _ctl;
  int _camIdx = 0;
  bool _ready = false;
  bool _busy = false;
  bool _flash = false;

  /* UI / ratio */
  late DeviceOrientation _ori;
  bool _fourThree = false; // false = 16:9, true = 4:3

  /* GPS */
  bool _gpsOn = false;
  LocationPermission? _gpsPerm;
  Timer? _gpsT;

  String? _err;

  /* ───────── lifecycle ───────── */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ori = DeviceOrientation.portraitUp;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _pickBackCam();
    _checkGps();
    _initCam();
    _gpsT = Timer.periodic(const Duration(seconds: 3), (_) => _checkGps());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsT?.cancel();
    _ctl.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /* ───────── orientation listener ───────── */
  @override
  void didChangeMetrics() {
    final sz =
        WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final portrait = sz.height >= sz.width;
    final newOri = portrait
        ? DeviceOrientation.portraitUp
        : (WidgetsBinding.instance.platformDispatcher.views.first.viewInsets
                    .bottom ==
                0
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.landscapeRight);
    if (newOri != _ori) setState(() => _ori = newOri);
  }

  /* ───────── GPS ───────── */
  Future<void> _checkGps() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      _gpsOn = enabled;
      _gpsPerm = perm;
    });
  }

  bool get _canGps =>
      _gpsOn &&
          (_gpsPerm == LocationPermission.always ||
              _gpsPerm == LocationPermission.whileInUse);

  String? _gpsMsg() {
    if (!_gpsOn) return 'GPS is disabled…';
    if (_gpsPerm == LocationPermission.denied) return 'GPS permission denied…';
    if (_gpsPerm == LocationPermission.deniedForever) {
      return 'GPS permission permanently denied…';
    }
    return null;
  }

  /* ───────── camera ───────── */
  void _pickBackCam() {
    for (var i = 0; i < widget.cameras.length; i++) {
      if (widget.cameras[i].lensDirection == CameraLensDirection.back) {
        _camIdx = i;
        break;
      }
    }
  }

  Future<void> _initCam() async {
    setState(() {
      _err = null;
      _ready = false;
    });
    try {
      _ctl = CameraController(
        widget.cameras[_camIdx],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _ctl.initialize();
      if (_flash) {
        try {
          await _ctl.setFlashMode(FlashMode.torch);
        } catch (_) {
          _flash = false;
        }
      }
    if (mounted) setState(() => _ready = true);
    } catch (e) {
    if (!mounted) return;
    setState(() {
    _err = 'Failed to initialise camera: $e';
    _ready = false;
    });
    }
  }

/* ───────── actions ───────── */
  Future<void> _shoot() async {
    if (_busy || !_ready) return;
    setState(() => _busy = true);

    try {
      final file = await _ctl.takePicture();

      final imageBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        // First, rotate the image if in landscape mode
        img.Image processedImage = originalImage;

        // Check if running on iOS
        final bool isIOS = Platform.isIOS;

        // Explicitly rotate the image based on device orientation
        if (_ori == DeviceOrientation.landscapeLeft) {
          // Rotate 270 degrees clockwise (90 + 180 for the additional rotation)
          processedImage = img.copyRotate(originalImage, angle: 270);
          // Additional 90 degree rotation for iOS in landscape mode
          if (isIOS) {
            processedImage = img.copyRotate(processedImage, angle: 90);
          }
        } else if (_ori == DeviceOrientation.landscapeRight) {
          // Rotate 90 degrees clockwise (270 + 180 = 450, which is equivalent to 90 degrees)
          processedImage = img.copyRotate(originalImage, angle: 90);
          // Additional 90 degree rotation for iOS in landscape mode
          if (isIOS) {
            processedImage = img.copyRotate(processedImage, angle: 90);
          }
        }

        final height = processedImage.height;
        final width = processedImage.width;

        // Determine if the image should be treated as portrait based on device orientation
        final bool isPortraitImage = _ori == DeviceOrientation.portraitUp ? true : false;

        double desiredRatio;
        if (_fourThree) {
          desiredRatio = isPortraitImage ? 3 / 4 : 4 / 3;
        } else {
          desiredRatio = isPortraitImage ? 9 / 16 : 16 / 9;
        }

        // Calculate the ratio based on orientation
        final imageRatio = width / height;
        const epsilon = 0.01;
        if ((imageRatio - desiredRatio).abs() < epsilon) {
          // No cropping needed, just save the rotated image
          final rotatedBytes = img.encodeJpg(processedImage);
          await File(file.path).writeAsBytes(rotatedBytes);
        } else {
          int cropWidth, cropHeight;

          // iOS-specific cropping logic for landscape mode
          if (isIOS && !isPortraitImage) {
            if (imageRatio > desiredRatio) {
              cropWidth = width;
              cropHeight = (width / desiredRatio).round();
            } else {
              cropHeight = height;
              cropWidth = (height * desiredRatio).round();
            }
          } else {
            // Standard cropping logic for Android and iOS portrait
            if (imageRatio > desiredRatio) {
              cropHeight = height;
              cropWidth = (height * desiredRatio).round();
            } else {
              cropWidth = width;
              cropHeight = (width / desiredRatio).round();
            }
          }

          final offsetX = ((width - cropWidth) / 2).round();
          final offsetY = ((height - cropHeight) / 2).round();

          final croppedImage = img.copyCrop(
            processedImage,
            x: offsetX,
            y: offsetY,
            width: cropWidth,
            height: cropHeight,
          );

          final croppedBytes = img.encodeJpg(croppedImage);
          await File(file.path).writeAsBytes(croppedBytes);
        }
      }

      if (_canGps) {
        try {
          final p = await Geolocator.getCurrentPosition();
          await CameraWithGps.addGps(
              path: file.path, latitude: p.latitude, longitude: p.longitude);
        } catch (_) {}
      }

      if (mounted) Navigator.pop(context, file.path);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Capture error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switchCam() async {
    if (!_ready) return;
    final cur = widget.cameras[_camIdx];
    final next = widget.cameras
        .firstWhere((c) => c.lensDirection != cur.lensDirection, orElse: () => cur);
    if (next == cur) return;
    setState(() => _ready = false);
    await _ctl.dispose();
    _camIdx = widget.cameras.indexOf(next);
    await _initCam();
  }

  Future<void> _toggleFlash() async {
    if (!_ready) return;
    try {
      final m = _flash ? FlashMode.off : FlashMode.torch;
      await _ctl.setFlashMode(m);
      setState(() => _flash = !_flash);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash not available on this camera')));
    }
  }

  Future<void> _pickGallery() async {
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img == null) return;
      // Don't add GPS data to photos selected from the gallery
      if (mounted) Navigator.pop(context, img.path);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gallery error: $e')));
    }
  }

  void _toggleRatio() => setState(() => _fourThree = !_fourThree);

  /* ───────── top & bottom bars ───────── */
  Widget _topBar() {
    final ratioTxt = _fourThree ? '4:3' : '16:9';
    final ratioBtn = TextButton(
      onPressed: _toggleRatio,
      child: Text(
        ratioTxt,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // For portrait orientation
    final portraitCol = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RotIcon(
            orientation: _ori,
            icon: Icons.close,
            onPressed: () => Navigator.pop(context)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RotIcon(
                orientation: _ori,
                icon: _flash ? Icons.flash_on : Icons.flash_off,
                onPressed: _toggleFlash,
                size: 26),
            const SizedBox(width: 16),
            ratioBtn,
          ],
        ),
      ],
    );

    // For landscape orientation
    final landscapeCol = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _RotIcon(
            orientation: _ori,
            icon: Icons.close,
            onPressed: () => Navigator.pop(context)),
        _RotIcon(
            orientation: _ori,
            icon: _flash ? Icons.flash_on : Icons.flash_off,
            onPressed: _toggleFlash,
            size: 26),
        const SizedBox(height: 16),
        ratioBtn,
      ],
    );

    switch (_ori) {
      case DeviceOrientation.portraitUp:
        return SafeArea(
          child: Container(
            height: 56,
            color: Colors.black38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: portraitCol.children,
            ),
          ),
        );
      case DeviceOrientation.landscapeLeft:
        return Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 72, color: Colors.black38, child: landscapeCol));
      case DeviceOrientation.landscapeRight:
        return Align(
            alignment: Alignment.centerRight,
            child: Container(width: 72, color: Colors.black38, child: landscapeCol));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _bottomBar() {
    final portrait = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RotIcon(orientation: _ori, icon: Icons.photo_library, onPressed: _pickGallery),
        GestureDetector(
            onTap: _busy ? null : _shoot, child: _Shutter(busy: _busy)),
        _RotIcon(orientation: _ori, icon: Icons.cameraswitch, onPressed: _switchCam),
      ],
    );

    final side = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RotIcon(orientation: _ori, icon: Icons.photo_library, onPressed: _pickGallery),
        GestureDetector(
            onTap: _busy ? null : _shoot, child: _Shutter(busy: _busy)),
        _RotIcon(orientation: _ori, icon: Icons.cameraswitch, onPressed: _switchCam),
      ],
    );

    switch (_ori) {
      case DeviceOrientation.portraitUp:
        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              height: 120,
              color: Colors.black38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: portrait,
            ),
          ),
        );
      case DeviceOrientation.landscapeLeft:
        return Align(
            alignment: Alignment.centerRight,
            child: Container(
                width: 72,
                color: Colors.black38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: side));
      case DeviceOrientation.landscapeRight:
        return Align(
            alignment: Alignment.centerLeft,
            child: Container(
                width: 72,
                color: Colors.black38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: side));
      default:
        return const SizedBox.shrink();
    }
  }

  /* ───────── build ───────── */
  @override
  Widget build(BuildContext context) {
    final gps = _gpsMsg();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_err != null)
            _ErrorUi(msg: _err!, retry: _initCam)
          else if (_ready)
            _Preview(ctrl: _ctl, ori: _ori, fourThree: _fourThree)
          else
            const Center(child: CircularProgressIndicator()),
          if (gps != null && _ready && _err == null) _GpsBanner(message: gps),
          if (_ready && _err == null) ...[_topBar(), _bottomBar()],
        ],
      ),
    );
  }
}

/* ───────────────── preview (letter-box) ───────────────── */
class _Preview extends StatelessWidget {
  const _Preview(
      {required this.ctrl,
        required this.ori,
        required this.fourThree});

  final CameraController ctrl;
  final DeviceOrientation ori;
  final bool fourThree;

  @override
  Widget build(BuildContext context) {
    final wantRatio = fourThree ? 4 / 3 : 16 / 9; // width ÷ height

    final sensor = ctrl.value.previewSize!;
    final rawW = sensor.height;
    final rawH = sensor.width;

    if (ori == DeviceOrientation.portraitUp) {
      final screenW = MediaQuery.of(context).size.width;
      final previewH = screenW * wantRatio; // ширина * (H/W) = W·R

      return Center(
        child: ClipRect(
          child: SizedBox(
            width: screenW,
            height: previewH,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: rawW, height: rawH, child: CameraPreview(ctrl)),
            ),
          ),
        ),
      );
    } else {
      final screenH = MediaQuery.of(context).size.height;
      final previewW = screenH * wantRatio; // портрет-інвертоване ratio

      return Center(
        child: ClipRect(
          child: SizedBox(
            width: previewW,
            height: screenH,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: sensor.width, height: sensor.height, child: CameraPreview(ctrl)),
            ),
          ),
        ),
      );
    }
  }
}

/* ───────────────── shutter ───────────────── */
class _Shutter extends StatelessWidget {
  const _Shutter({required this.busy});
  final bool busy;
  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: busy ? Colors.white54 : Colors.white,
      shape: BoxShape.circle,
    ),
    child: busy
        ? const Center(child: CircularProgressIndicator())
        : const Icon(Icons.camera_alt, color: Colors.black),
  );
}

/* ───────────────── error ───────────────── */
class _ErrorUi extends StatelessWidget {
  const _ErrorUi({required this.msg, required this.retry});
  final String msg;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(msg,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: retry, child: const Text('Retry')),
      ],
    ),
  );
}
