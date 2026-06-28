import 'package:flutter/foundation.dart';
import '../models/typing_result.dart';
import '../services/word_bank_service.dart';
import 'typing_notifier.dart';
import 'timer_notifier.dart';
import 'settings_notifier.dart';

/// App mode state machine.
enum AppMode { idle, practice, test, finished }

/// Orchestrates the typing test flow: coordinates [TypingNotifier] and
/// [TimerNotifier], loads text from [WordBankService], and manages the
/// current [AppMode].
class TestNotifier extends ChangeNotifier {
  final TypingNotifier typingNotifier;
  final TimerNotifier timerNotifier;
  final SettingsNotifier settings;
  final WordBankService wordBank = WordBankService();

  AppMode _mode = AppMode.idle;
  TypingResult? _result;
  TestPassage? _selectedPassage;

  TestNotifier({
    required this.typingNotifier,
    required this.timerNotifier,
    required this.settings,
  });

  AppMode get mode => _mode;
  TypingResult? get result => _result;
  TestPassage? get selectedPassage => _selectedPassage;

  // ── Actions ────────────────────────────────────────────────────────

  /// Start a practice session with a random phrase or custom text.
  void startPractice() {
    _result = null;
    _mode = AppMode.practice;
    timerNotifier.reset();
    final text = settings.hasCustomText
        ? settings.customText!
        : wordBank.getRandomPracticeText();
    typingNotifier.loadText(text);
    notifyListeners();
  }

  /// Start a test session with the given [passage] (or a random one).
  void startTestWithPassage(TestPassage passage) {
    _result = null;
    _selectedPassage = passage;
    _mode = AppMode.test;
    typingNotifier.loadText(passage.text);
    timerNotifier.start(seconds: settings.testDurationSeconds);
    notifyListeners();
  }

  /// Start a test session with custom text from settings.
  void startTestWithCustomText() {
    _result = null;
    _selectedPassage = null;
    _mode = AppMode.test;
    typingNotifier.loadText(settings.customText!);
    timerNotifier.start(seconds: settings.testDurationSeconds);
    notifyListeners();
  }

  /// Called when the user finishes typing all characters.
  void onTypingFinished() {
    if (_mode != AppMode.test && _mode != AppMode.practice) return;

    timerNotifier.pause();
    _result = TypingResult.fromTypingNotifier(
      notifier: typingNotifier,
      elapsedSeconds: typingNotifier.elapsedSeconds,
    );
    _mode = AppMode.finished;
    notifyListeners();
  }

  /// Called when the test timer expires.
  void onTimerExpired() {
    if (_mode != AppMode.test) return;

    typingNotifier.forceFinish();
    _result = TypingResult.fromTypingNotifier(
      notifier: typingNotifier,
      elapsedSeconds: typingNotifier.elapsedSeconds,
    );
    _mode = AppMode.finished;
    notifyListeners();
  }

  /// Restart practice with a fresh random phrase (or custom text).
  void restartPractice() {
    _result = null;
    _mode = AppMode.practice;
    final text = settings.hasCustomText
        ? settings.customText!
        : wordBank.getRandomPracticeText();
    typingNotifier.loadText(text);
    notifyListeners();
  }

  /// Restart test with the same passage (or custom text), using the
  /// configured duration.
  void restartTest() {
    if (_selectedPassage != null) {
      startTestWithPassage(_selectedPassage!);
    } else if (settings.hasCustomText) {
      startTestWithCustomText();
    } else {
      startTestWithPassage(wordBank.getRandomTestPassage());
    }
  }

  /// Return to the home screen.
  void returnToHome() {
    _result = null;
    _mode = AppMode.idle;
    timerNotifier.reset();
    typingNotifier.loadText('');
    notifyListeners();
  }
}
