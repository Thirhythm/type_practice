import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

/// Character-by-character status for typing display coloring.
enum CharStatus {
  pending,
  correct,
  incorrect,
  current,
}

/// Core typing engine for multi-line typing practice.
///
/// Text is split into lines (by the widget layer using [initializeLines])
/// based on available display width. Each line has its own target text
/// and a corresponding [TextField] for user input.
class TypingNotifier extends ChangeNotifier {
  // ── Text state ─────────────────────────────────────────────────────

  String _rawText = '';
  List<String> _targetLines = [];
  int _currentLineIndex = 0;
  List<String> _lineInputs = [];
  List<List<CharStatus>> _lineCharStatuses = [];
  bool _linesInitialized = false;

  // ── Global stats ───────────────────────────────────────────────────

  DateTime? _startTimestamp;
  DateTime? _endTimestamp;
  bool _isStarted = false;
  bool _isFinished = false;

  /// Cached count of correct keystrokes, recomputed once per input change
  /// instead of per-getter-invocation (avoiding 3+× O(n) per build).
  int _cachedCorrectKeystrokes = 0;

  // ══════════════════════════════════════════════════════════════════════
  // Getters
  // ══════════════════════════════════════════════════════════════════════

  String get rawText => _rawText;
  List<String> get targetLines => List.unmodifiable(_targetLines);
  int get currentLineIndex => _currentLineIndex;
  List<String> get lineInputs => List.unmodifiable(_lineInputs);
  List<List<CharStatus>> get lineCharStatuses => _lineCharStatuses;
  bool get linesInitialized => _linesInitialized;
  bool get isStarted => _isStarted;
  bool get isFinished => _isFinished;

  /// Total characters across all target lines.
  int get totalChars =>
      _targetLines.fold(0, (sum, line) => sum + line.characters.length);

  /// Total keystrokes = characters typed across all lines.
  int get totalKeystrokes =>
      _lineInputs.fold(0, (sum, s) => sum + s.characters.length);

  /// Correctly typed characters (matching positions across all lines).
  int get correctKeystrokes => _cachedCorrectKeystrokes;

  /// Recompute [correctKeystrokes] from [_lineCharStatuses]. Called
  /// once per [updateLineInput] so that downstream getters (cpm, wpm,
  /// accuracyPercent) never trigger redundant O(n) scans.
  void _recountCorrect() {
    int count = 0;
    for (final statuses in _lineCharStatuses) {
      for (final s in statuses) {
        if (s == CharStatus.correct) count++;
      }
    }
    _cachedCorrectKeystrokes = count;
  }

  int get incorrectKeystrokes => totalKeystrokes - correctKeystrokes;

  double get accuracyPercent {
    if (totalKeystrokes == 0) return 100.0;
    return (correctKeystrokes / totalKeystrokes) * 100.0;
  }

  double get elapsedSeconds {
    if (_startTimestamp == null) return 0.0;
    final end = _endTimestamp ?? DateTime.now();
    return end.difference(_startTimestamp!).inMilliseconds / 1000.0;
  }

  double get cpm {
    if (correctKeystrokes == 0) return 0.0;
    final secs = elapsedSeconds;
    final clamped = secs < 0.1 ? 0.1 : secs;
    return correctKeystrokes / (clamped / 60.0);
  }

  double get wpm => cpm / 5.0;

  /// Progress percentage across all target characters.
  double get progressPercent {
    final total = totalChars;
    if (total == 0) return 0.0;
    int completed = 0;
    for (int li = 0; li < _targetLines.length; li++) {
      if (li < _currentLineIndex) {
        completed += _targetLines[li].characters.length;
      } else if (li == _currentLineIndex && li < _lineInputs.length) {
        final inputLen = _lineInputs[li].characters.length;
        final targetLen = _targetLines[li].characters.length;
        completed += inputLen < targetLen ? inputLen : targetLen;
      }
    }
    return (completed / total) * 100.0;
  }

  // ══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ══════════════════════════════════════════════════════════════════════

  /// Load raw text. The widget layer must call [initializeLines] to
  /// split the text into display lines based on available width.
  void loadText(String text) {
    _rawText = text;
    _targetLines = [];
    _currentLineIndex = 0;
    _lineInputs = [];
    _lineCharStatuses = [];
    _linesInitialized = false;
    _startTimestamp = null;
    _endTimestamp = null;
    _isStarted = false;
    _isFinished = false;
    _cachedCorrectKeystrokes = 0;
    notifyListeners();
  }

  /// Set the display lines (called by the widget after computing line
  /// breaks via [TextPainter]). Must be called exactly once after each
  /// [loadText].
  void initializeLines(List<String> lines) {
    _targetLines = List.of(lines);
    _lineInputs = List.filled(_targetLines.length, '');
    _lineCharStatuses = _targetLines.map((line) {
      final statuses = List.filled(line.characters.length, CharStatus.pending);
      return statuses;
    }).toList();
    _linesInitialized = true;

    // Mark first character of first line as current.
    if (_lineCharStatuses.isNotEmpty && _lineCharStatuses[0].isNotEmpty) {
      _lineCharStatuses[0][0] = CharStatus.current;
    }

    _recountCorrect();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════
  // Input handling
  // ══════════════════════════════════════════════════════════════════════

  /// Process a change in user input for [lineIndex].
  ///
  /// Compares the full input against the target line character-by-character
  /// and rebuilds [CharStatus] for that line. If the user has typed at
  /// least as many characters as the target line, the engine advances to
  /// the next line automatically. Excess characters **spill over** into
  /// the next line (e.g. when IME commits a multi-character phrase).
  void updateLineInput(int lineIndex, String newInput) {
    if (_isFinished) return;
    if (lineIndex != _currentLineIndex) return;
    if (!_linesInitialized) return;

    if (!_isStarted) {
      _isStarted = true;
      _startTimestamp = DateTime.now();
    }

    final targetChars = _targetLines[lineIndex].characters;
    final inputChars = Characters(newInput);

    if (inputChars.length <= targetChars.length) {
      // Normal case: input fits within this line.
      _applyToLine(lineIndex, newInput);
      // Auto-advance when fully typed.
      if (inputChars.length >= targetChars.length) {
        _advanceToLine(lineIndex + 1);
      }
    } else {
      // Overflow: IME committed more chars than this line has room for.
      // Split at the target boundary: "fit" stays, "overflow" cascades.
      final fit =
          inputChars.getRange(0, targetChars.length).string;
      final overflow = inputChars
          .getRange(targetChars.length, inputChars.length)
          .string;

      _applyToLine(lineIndex, fit);
      _advanceToLine(lineIndex + 1);

      // Cascade overflow to the next line(s). This naturally handles
      // multi-line overflow (e.g. pasting a long phrase).
      if (!_isFinished) {
        updateLineInput(_currentLineIndex, overflow);
        return; // notifyListeners already called by nested call
      }
    }

    _recountCorrect();
    notifyListeners();
  }

  /// Apply [text] as the full input for [lineIndex] and rebuild char
  /// statuses. Does NOT handle auto-advance or overflow.
  void _applyToLine(int lineIndex, String text) {
    final target = _targetLines[lineIndex];
    final targetChars = target.characters;
    final inputChars = Characters(text);
    final statuses = <CharStatus>[];

    for (int i = 0; i < targetChars.length; i++) {
      if (i < inputChars.length) {
        if (inputChars.elementAt(i) == targetChars.elementAt(i)) {
          statuses.add(CharStatus.correct);
        } else {
          statuses.add(CharStatus.incorrect);
        }
      } else if (i == inputChars.length) {
        statuses.add(CharStatus.current);
      } else {
        statuses.add(CharStatus.pending);
      }
    }

    _lineInputs[lineIndex] = text;
    _lineCharStatuses[lineIndex] = statuses;
  }

  /// Move the cursor to [nextIndex] or finish if past the last line.
  void _advanceToLine(int nextIndex) {
    if (nextIndex < _targetLines.length) {
      _currentLineIndex = nextIndex;
      final next = _lineCharStatuses[_currentLineIndex];
      if (next.isNotEmpty) {
        next[0] = CharStatus.current;
      }
    } else {
      _isFinished = true;
      _endTimestamp = DateTime.now();
    }
  }

  /// Manually advance to the next line (e.g. on Tab or Enter key).
  void advanceToNextLine() {
    if (_currentLineIndex + 1 >= _targetLines.length) return;
    _currentLineIndex++;
    final next = _lineCharStatuses[_currentLineIndex];
    if (next.isNotEmpty) {
      next[0] = CharStatus.current;
    }
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════

  /// Restart with the same raw text (requires re-initializeLines).
  void restart() {
    final text = _rawText;
    loadText(text);
  }

  /// Force-finish the session (timer expiry in test mode).
  void forceFinish() {
    _isFinished = true;
    _endTimestamp = DateTime.now();
    notifyListeners();
  }
}
