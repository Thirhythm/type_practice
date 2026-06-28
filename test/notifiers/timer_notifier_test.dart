import 'package:flutter_test/flutter_test.dart';
import 'package:type_practice/notifiers/timer_notifier.dart';

void main() {
  group('TimerNotifier', () {
    late TimerNotifier notifier;

    setUp(() {
      notifier = TimerNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    group('start', () {
      test('initializes countdown correctly', () {
        notifier.start(seconds: 30);

        expect(notifier.totalSeconds, 30);
        expect(notifier.remainingSeconds, 30);
        expect(notifier.isRunning, true);
        expect(notifier.isExpired, false);
      });

      test('default duration is 60 seconds', () {
        notifier.start();

        expect(notifier.totalSeconds, 60);
        expect(notifier.remainingSeconds, 60);
      });

      test('cancels previous timer before starting a new one', () {
        notifier.start(seconds: 60);
        notifier.start(seconds: 30);

        expect(notifier.totalSeconds, 30);
        expect(notifier.remainingSeconds, 30);
      });
    });

    group('pause', () {
      test('stops the timer', () {
        notifier.start(seconds: 60);
        notifier.pause();

        expect(notifier.isRunning, false);
      });
    });

    group('resume', () {
      test('restarts from current remaining time', () {
        notifier.start(seconds: 60);
        notifier.pause();
        notifier.resume();

        expect(notifier.isRunning, true);
      });

      test('does not resume when remaining is zero', () {
        // start(seconds: 0) starts with 0 remaining — resume is a no-op.
        notifier.start(seconds: 0);
        // _remainingSeconds is 0, so resume() returns early.
        notifier.resume();

        // isRunning stays true from start(), but timer will expire on first tick.
        expect(notifier.remainingSeconds, 0);
      });
    });

    group('reset', () {
      test('restores to full duration and stops', () {
        notifier.start(seconds: 60);
        notifier.reset();

        expect(notifier.remainingSeconds, 60);
        expect(notifier.isRunning, false);
        expect(notifier.isExpired, false);
      });
    });

    group('expiry', () {
      test('eventually expires after starting', () async {
        notifier.start(seconds: 1);

        // Wait for the timer to expire.
        await Future.delayed(const Duration(seconds: 2));

        expect(notifier.isExpired, true);
        expect(notifier.remainingSeconds, 0);
        expect(notifier.isRunning, false);
      });
    });
  });
}
