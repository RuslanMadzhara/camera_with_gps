import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../services/camera_with_gps.dart';
import '../services/orientation_service.dart';
import '../services/photo_processor.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/error_ui.dart';
import '../widgets/gps_banner.dart';
import '../widgets/preview_box.dart';
import '../widgets/top_bar.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({
    super.key,
    required this.cameras,
    this.allowGallery = true,
  });

  final List<CameraDescription> cameras;
  final bool allowGallery;

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

  /* UI */
  static const DeviceOrientation _fixedOri =
      DeviceOrientation.portraitUp; // 🔒 UI тільки портрет
  bool _fourThree = false;

  /* GPS */
  bool _gpsOn = false;
  LocationPermission? _gpsPerm;
  Timer? _gpsT;

  /* Orientation */
  DeviceOrientation _deviceOri = DeviceOrientation.portraitUp;
  StreamSubscription<DeviceOrientation>? _oriSub;

  String? _err;

  DeviceOrientation get _curOri => _deviceOri;

  /* ───────── lifecycle ───────── */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

    _pickBackCam();
    _checkGps();
    _initCam();
    _gpsT = Timer.periodic(const Duration(seconds: 3), (_) => _checkGps());

    final oriService = OrientationService();
    oriService.start();
    _oriSub = oriService.stream.listen((ori) {
      if (mounted) {
        setState(() {
          _deviceOri = ori;
          print('📱 Device orientation changed: $ori');
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (_ready) {
          setState(() => _ready = false);
          try {
            await _ctl.dispose();
          } catch (_) {}
        }
        break;
      case AppLifecycleState.resumed:
        await _initCam();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsT?.cancel();
    _oriSub?.cancel();
    try {
      _ctl.dispose();
    } catch (_) {}
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /* ───────── GPS helpers ───────── */
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

  /* ───────── camera helpers ───────── */
  void _pickBackCam() {
    final idx = widget.cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _camIdx = idx >= 0 ? idx : 0;
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

      // ❗ НЕ лочимо capture-орієнтацію — покладаємося на EXIF у файлі
      try {
        await _ctl.unlockCaptureOrientation();
      } catch (_) {}

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
      final shot = await _ctl.takePicture();

      final path = await PhotoProcessor.process(
        shot: shot,
        fourThree: _fourThree,
        orientation: _curOri, // ← передаємо поточну орієнтацію
      );

      await _handleGps(path);

      // Закриваємо камеру ПЕРЕД pop → чисті логи
      try {
        setState(() => _ready = false);
        await _ctl.dispose();
      } catch (_) {}

      if (mounted) Navigator.pop(context, path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Capture error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleGps(String path) async {
    if (!_gpsOn) {
      await CameraWithGps.removeGps(path: path);
    } else if (_canGps) {
      try {
        final p = await Geolocator.getCurrentPosition();
        if (p.latitude != 0.0 || p.longitude != 0.0) {
          await CameraWithGps.addGps(
              path: path, latitude: p.latitude, longitude: p.longitude);
        } else {
          await CameraWithGps.removeGps(path: path);
        }
      } catch (_) {
        await CameraWithGps.removeGps(path: path);
      }
    }
  }

  Future<void> _switchCam() async {
    if (!_ready) return;
    final cur = widget.cameras[_camIdx];
    final next = widget.cameras.firstWhere(
      (c) => c.lensDirection != cur.lensDirection,
      orElse: () => cur,
    );
    if (next == cur) return;
    setState(() => _ready = false);
    try {
      await _ctl.dispose();
    } catch (_) {}
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Flash not available on this camera')));
      }
    }
  }

  Future<void> _pickGallery() async {
    try {
      final imgPath = await CameraWithGps.pickFromGallery();
      if (imgPath == null) return;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) Navigator.pop(context, imgPath);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gallery error: $e')));
      }
    }
  }

  void _toggleRatio() => setState(() => _fourThree = !_fourThree);

  /* ───────── build ───────── */
  @override
  Widget build(BuildContext context) {
    final gps = _gpsMsg();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_err != null)
            ErrorUi(msg: _err!, retry: _initCam)
          else if (_ready)
            PreviewBox(
              controller: _ctl,
              fourThree: _fourThree,
              orientation: _fixedOri,
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (gps != null && _ready && _err == null) GpsBanner(message: gps),
          if (_ready && _err == null) ...[
            SafeArea(
              top: true,
              child: TopBar(
                orientation: _fixedOri,
                flash: _flash,
                fourThree: _fourThree,
                onClose: () => Navigator.pop(context),
                onToggleFlash: _toggleFlash,
                onToggleRatio: _toggleRatio,
              ),
            ),
            SafeArea(
              bottom: true,
              minimum: const EdgeInsets.only(bottom: 8),
              child: BottomBar(
                orientation: _fixedOri,
                busy: _busy,
                onShoot: () => unawaited(_shoot()),
                onGallery: () => unawaited(_pickGallery()),
                onSwitchCam: () => unawaited(_switchCam()),
                allowGallery: widget.allowGallery,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
