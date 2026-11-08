import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/shake_detector.dart';
import '../domain/shake_sensitivity.dart';

/// Emits one event per deliberate shake. Implementations must only listen to
/// hardware while [start] has been called and the app is in the foreground.
abstract interface class ShakeService {
  Stream<void> get shakes;

  void start({required ShakeSensitivity sensitivity});

  Future<void> stop();

  Future<void> dispose();
}

class SensorShakeService implements ShakeService {
  SensorShakeService();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  StreamSubscription<AccelerometerEvent>? _subscription;
  ShakeDetector? _detector;

  @override
  Stream<void> get shakes => _controller.stream;

  @override
  void start({required ShakeSensitivity sensitivity}) {
    if (_controller.isClosed) return;

    unawaited(_subscription?.cancel());
    _detector = ShakeDetector(sensitivity: sensitivity);

    try {
      _subscription =
          accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
              .listen((event) {
                final detected = _detector?.addSample(
                  event.x,
                  event.y,
                  event.z,
                  DateTime.now(),
                );
                if (detected == true && !_controller.isClosed) {
                  _controller.add(null);
                }
              }, onError: (Object _) {});
    } catch (_) {
      // A device without an accelerometer simply never reports a shake.
      _subscription = null;
    }
  }

  @override
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    _detector = null;
    await subscription?.cancel();
  }

  @override
  Future<void> dispose() async {
    await stop();
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
