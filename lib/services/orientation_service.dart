import 'dart:async';

import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// Broadcasts [DeviceOrientation] changes based on sensors (works on Android & iOS).
class OrientationService {
  static final OrientationService _i = OrientationService._();
  factory OrientationService() => _i;
  OrientationService._();

  final _ctrl = StreamController<DeviceOrientation>.broadcast();
  Stream<DeviceOrientation> get stream => _ctrl.stream;

  StreamSubscription? _sub;

  void start() {
    _sub ??= NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((n) => _ctrl.add(_map(n)));
  }

  DeviceOrientation _map(NativeDeviceOrientation n) {
    switch (n) {
      case NativeDeviceOrientation.landscapeLeft:
        return DeviceOrientation.landscapeLeft;
      case NativeDeviceOrientation.landscapeRight:
        return DeviceOrientation.landscapeRight;
      case NativeDeviceOrientation.portraitDown:
        return DeviceOrientation.portraitDown;
      default:
        return DeviceOrientation.portraitUp;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
