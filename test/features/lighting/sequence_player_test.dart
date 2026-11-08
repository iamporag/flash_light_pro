import 'dart:async';

import 'package:flash_light_pro/features/flashlight/services/torch_service.dart';
import 'package:flash_light_pro/features/sequences/domain/light_step.dart';
import 'package:flash_light_pro/features/sequences/services/sequence_player.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flashlight/fake_torch_service.dart';

const _on = LightStep(isOn: true, duration: Duration(milliseconds: 1));
const _off = LightStep(isOn: false, duration: Duration(milliseconds: 1));

void main() {
  group('SequencePlayer', () {
    test('drives a finite sequence and completes', () async {
      final service = FakeTorchService();
      final player = SequencePlayer(torchService: service, delay: (_) async {});
      addTearDown(player.dispose);

      var completed = false;
      await player.play(
        steps: const [_on, _off],
        useTorch: true,
        onComplete: () => completed = true,
      );

      expect(completed, isTrue);
      expect(service.enableCalls, 1);
      expect(service.disableCalls, greaterThanOrEqualTo(1));
      expect(player.isRunning, isFalse);
    });

    test('uses the screen notifier instead of the torch when asked', () async {
      final service = FakeTorchService();
      final player = SequencePlayer(torchService: service, delay: (_) async {});
      addTearDown(player.dispose);

      final flashes = <bool>[];
      player.screenFlash.addListener(() {
        flashes.add(player.screenFlash.value);
      });

      await player.play(steps: const [_on, _off], useTorch: false);

      expect(flashes, [true, false]);
      expect(service.enableCalls, 0);
      expect(service.disableCalls, 0);
      expect(player.screenFlash.value, isFalse);
    });

    test('surfaces typed failures and always releases the light', () async {
      final service = FakeTorchService()
        ..enableError = const TorchFailure(TorchFailureKind.cameraInUse);
      final player = SequencePlayer(torchService: service, delay: (_) async {});
      addTearDown(player.dispose);

      TorchFailure? failure;
      var completed = false;
      await player.play(
        steps: const [_on],
        useTorch: true,
        onComplete: () => completed = true,
        onError: (error) => failure = error,
      );

      expect(failure?.kind, TorchFailureKind.cameraInUse);
      expect(completed, isFalse);
      expect(player.isRunning, isFalse);
      expect(service.disableCalls, greaterThanOrEqualTo(1));
    });

    test('stop prevents pending work from toggling the light again', () async {
      final service = FakeTorchService();
      final gate = Completer<void>();
      final player = SequencePlayer(
        torchService: service,
        delay: (_) => gate.future,
      );
      addTearDown(player.dispose);

      final playback = player.play(
        steps: const [_on, _off],
        useTorch: true,
        repeat: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.enableCalls, 1);

      final stop = player.stop();
      gate.complete();
      await playback;
      await stop;

      expect(player.isRunning, isFalse);
      expect(service.enableCalls, 1);
      expect(service.disableCalls, 1);
    });

    test('a new session cancels the previous one', () async {
      final service = FakeTorchService();
      final gate = Completer<void>();
      final player = SequencePlayer(
        torchService: service,
        delay: (_) => gate.future,
      );
      addTearDown(player.dispose);

      final first = player.play(
        steps: const [_on, _off],
        useTorch: true,
        repeat: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.enableCalls, 1);
      expect(player.isRunning, isTrue);

      final second = player.play(
        steps: const [_on, _off],
        useTorch: true,
        repeat: true,
      );
      await Future<void>.delayed(Duration.zero);

      await player.stop();
      gate.complete();
      await first;
      await second;

      expect(player.isRunning, isFalse);
      expect(service.enableCalls, 2);
      expect(service.disableCalls, greaterThanOrEqualTo(2));
    });
  });
}
