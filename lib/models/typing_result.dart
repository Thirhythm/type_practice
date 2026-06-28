import '../notifiers/typing_notifier.dart';

/// Immutable result of a completed typing session (practice or test).
class TypingResult {
  final String targetText;
  final int totalCharacters;
  final int correctCharacters;
  final int incorrectCharacters;
  final int totalKeystrokes;
  final double elapsedSeconds;
  final double cpm;
  final double wpm;
  final double accuracyPercent;
  final DateTime timestamp;

  const TypingResult({
    required this.targetText,
    required this.totalCharacters,
    required this.correctCharacters,
    required this.incorrectCharacters,
    required this.totalKeystrokes,
    required this.elapsedSeconds,
    required this.cpm,
    required this.wpm,
    required this.accuracyPercent,
    required this.timestamp,
  });

  /// Derive a result from a finished [TypingNotifier] and the elapsed time.
  factory TypingResult.fromTypingNotifier({
    required TypingNotifier notifier,
    required double elapsedSeconds,
  }) {
    return TypingResult(
      targetText: notifier.rawText,
      totalCharacters: notifier.totalChars,
      correctCharacters: notifier.correctKeystrokes,
      incorrectCharacters: notifier.incorrectKeystrokes,
      totalKeystrokes: notifier.totalKeystrokes,
      elapsedSeconds: elapsedSeconds,
      cpm: notifier.cpm,
      wpm: notifier.wpm,
      accuracyPercent: notifier.accuracyPercent,
      timestamp: DateTime.now(),
    );
  }
}
