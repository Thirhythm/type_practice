import 'dart:async';
import 'package:flutter/foundation.dart';

/// A countdown timer notifier for test mode.
///
/// Emits [ChangeNotifier] updates every second so the UI can display
/// remaining time in real-time.
class TimerNotifier extends ChangeNotifier {
  Timer? _timer;
  int _totalSeconds = 60;
  int _remainingSeconds = 60;
  bool _isRunning = false;
  bool _isExpired = false;

  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isExpired => _isExpired;

  /// Start a countdown of [seconds] duration.
  void start({int seconds = 60}) {
    _cancelTimer();
    _totalSeconds = seconds;
    _remainingSeconds = seconds;
    _isRunning = true;
    _isExpired = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _isExpired = true;
        _isRunning = false;
        _cancelTimer();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Pause the countdown without resetting.
  void pause() {
    _cancelTimer();
    _isRunning = false;
    notifyListeners();
  }

  /// Resume a paused countdown.
  void resume() {
    if (_isExpired || _remainingSeconds <= 0) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _isExpired = true;
        _isRunning = false;
        _cancelTimer();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Update the total duration while the timer is running (or idle).
  ///
  /// If the timer is running and the new duration is shorter than the
  /// already-elapsed time, the timer expires immediately. Otherwise the
  /// remaining time is preserved (progress is kept).
  void changeDuration(int newTotalSeconds) {
    if (newTotalSeconds <= 0) return;
    if (newTotalSeconds == _totalSeconds) return;

    final elapsed = _totalSeconds - _remainingSeconds;
    _totalSeconds = newTotalSeconds;

    if (elapsed >= newTotalSeconds) {
      // Already typed longer than the new duration — expire now.
      _remainingSeconds = 0;
      _isExpired = true;
      _isRunning = false;
      _cancelTimer();
    } else {
      _remainingSeconds = newTotalSeconds - elapsed;
    }
    notifyListeners();
  }

  /// Stop the timer and restore to the initially set duration.
  void reset() {
    _cancelTimer();
    _remainingSeconds = _totalSeconds;
    _isRunning = false;
    _isExpired = false;
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
