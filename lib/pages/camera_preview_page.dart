import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../services/camera_with_gps.dart';
import '../services/orientation_service.dart';
import '../utils/photo_processor.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/error_ui.dart';
import '../widgets/gps_banner.dart';
import '../widgets/preview_box.dart';
import '../widgets/top_bar.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({
    super.key,
    required this.cameras,
    this.allowGallery = true, // new: toggle gallery button in the UI
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
  DeviceOrientation _ori = DeviceOrientation.portraitUp;
  bool _fourThree = false;

  /* GPS */
  bool _gpsOn = false;
  LocationPermission? _gpsPerm;
  Timer? _gpsT;

  String? _err;
  late final OrientationService _oriSvc;
  StreamSubscription<DeviceOrientation>? _oriSub;

  /* ───────── lifecycle ───────── */
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _oriSvc = OrientationService()..start();
    _oriSub = _oriSvc.stream.listen((o) {
      if (mounted && o != _ori) setState(() => _ori = o);
    });

    _pickBackCam();
    _checkGps();
    _initCam();
    _gpsT = Timer.periodic(const Duration(seconds: 3), (_) => _checkGps());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _oriSub?.cancel();
    _oriSvc.stop();
    _gpsT?.cancel();
    _ctl.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
    if (_gpsPerm == LocationPermission.deniedForever)
      return 'GPS permission permanently denied…';
    return null;
  }

  /* ───────── camera helpers ───────── */
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
      final shot = await _ctl.takePicture();
      await PhotoProcessor.process(
        shot: shot,
        orientation: _ori,
        fourThree: _fourThree,
      );
      await _handleGps(shot.path);
      if (mounted) Navigator.pop(context, shot.path);
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
                controller: _ctl, orientation: _ori, fourThree: _fourThree)
          else
            const Center(child: CircularProgressIndicator()),
          if (gps != null && _ready && _err == null) GpsBanner(message: gps),
          if (_ready && _err == null) ...[
            SafeArea(
              top: true,
              child: TopBar(
                orientation: _ori,
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
                orientation: _ori,
                busy: _busy,
                onShoot: () {
                  unawaited(_shoot());
                },
                onGallery: widget.allowGallery
                    ? () {
                        unawaited(_pickGallery());
                      }
                    : () => {},
                onSwitchCam: () {
                  unawaited(_switchCam());
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
