import 'package:flutter_test/flutter_test.dart';
import 'package:type_practice/notifiers/typing_notifier.dart';

void main() {
  group('TypingNotifier', () {
    late TypingNotifier notifier;

    setUp(() {
      notifier = TypingNotifier();
    });

    // Helper: load and initialize with a single line.
    void loadSingleLine(String text) {
      notifier.loadText(text);
      notifier.initializeLines([text]);
    }

    group('loadText', () {
      test('stores raw text and resets state', () {
        notifier.loadText('你好世界');

        expect(notifier.rawText, '你好世界');
        expect(notifier.linesInitialized, false);
        expect(notifier.targetLines, isEmpty);
        expect(notifier.isStarted, false);
        expect(notifier.isFinished, false);
      });

      test('resets state when reloading', () {
        loadSingleLine('你好');
        notifier.updateLineInput(0, '你好');

        notifier.loadText('新文本');
        expect(notifier.rawText, '新文本');
        expect(notifier.linesInitialized, false);
      });
    });

    group('initializeLines', () {
      test('sets up target lines and status arrays', () {
        notifier.loadText('你好。世界。');
        notifier.initializeLines(['你好。', '世界。']);

        expect(notifier.linesInitialized, true);
        expect(notifier.targetLines, ['你好。', '世界。']);
        expect(notifier.currentLineIndex, 0);
        expect(notifier.lineInputs, ['', '']);
        expect(notifier.lineCharStatuses.length, 2);
        expect(notifier.lineCharStatuses[0][0], CharStatus.current);
        expect(notifier.lineCharStatuses[0][1], CharStatus.pending);
      });

      test('handles single line', () {
        notifier.loadText('测试');
        notifier.initializeLines(['测试']);

        expect(notifier.targetLines.length, 1);
        expect(notifier.lineCharStatuses[0][0], CharStatus.current);
      });

      test('handles empty lines gracefully', () {
        notifier.loadText('');
        notifier.initializeLines([]);

        expect(notifier.lineCharStatuses, isEmpty);
      });
    });

    group('updateLineInput', () {
      test('marks correct characters correctly', () {
        loadSingleLine('你好');
        notifier.updateLineInput(0, '你');

        expect(notifier.lineCharStatuses[0][0], CharStatus.correct);
        expect(notifier.lineCharStatuses[0][1], CharStatus.current);
        expect(notifier.lineInputs[0], '你');
      });

      test('marks incorrect characters correctly', () {
        loadSingleLine('你好');
        notifier.updateLineInput(0, '他');

        expect(notifier.lineCharStatuses[0][0], CharStatus.incorrect);
        expect(notifier.lineCharStatuses[0][1], CharStatus.current);
      });

      test('handles multi-line input', () {
        notifier.loadText('你好啊世界');
        notifier.initializeLines(['你好啊', '世界']);

        notifier.updateLineInput(0, '你好啊');
        expect(notifier.lineCharStatuses[0][0], CharStatus.correct);
        expect(notifier.lineCharStatuses[0][1], CharStatus.correct);
        expect(notifier.lineCharStatuses[0][2], CharStatus.correct);
        // Auto-advanced to line 1.
        expect(notifier.currentLineIndex, 1);
        expect(notifier.lineCharStatuses[1][0], CharStatus.current);
      });

      test('auto-advances when line is fully typed', () {
        loadSingleLine('你');
        notifier.updateLineInput(0, '你');

        expect(notifier.isFinished, true);
      });

      test('sets isStarted on first input', () {
        loadSingleLine('测试');
        expect(notifier.isStarted, false);

        notifier.updateLineInput(0, '测');
        expect(notifier.isStarted, true);
      });

      test('ignores input for non-current line', () {
        notifier.loadText('你好啊。世界。');
        notifier.initializeLines(['你好啊。', '世界。']);

        // Try to type on line 1 while line 0 is current.
        notifier.updateLineInput(1, '世界');
        expect(notifier.lineInputs[1], '');
      });

      test('handles backspace (user deletes characters)', () {
        loadSingleLine('你好世界');
        notifier.updateLineInput(0, '你好啊'); // typed wrong
        expect(notifier.lineCharStatuses[0][2], CharStatus.incorrect);

        notifier.updateLineInput(0, '你好'); // deleted back
        expect(notifier.lineCharStatuses[0][2], CharStatus.current); // cursor
        expect(notifier.lineCharStatuses[0][0], CharStatus.correct);
        expect(notifier.lineCharStatuses[0][1], CharStatus.correct);
      });

      test('ignores input after finished', () {
        loadSingleLine('你好');
        notifier.updateLineInput(0, '你好');
        expect(notifier.isFinished, true);

        notifier.updateLineInput(0, '你好世界');
        // No crash, no state change beyond finish.
      });
    });

    group('derived stats', () {
      test('totalChars sums all target lines', () {
        notifier.loadText('你好。世界。');
        notifier.initializeLines(['你好。', '世界。']);
        expect(notifier.totalChars, 6); // 你好。 + 世界。
      });

      test('totalKeystrokes sums input across all lines', () {
        notifier.loadText('你好啊。世界。');
        notifier.initializeLines(['你好啊。', '世界。']);
        notifier.updateLineInput(0, '你好啊。');
        expect(notifier.totalKeystrokes, 4); // 你好啊。 = 4 chars

        notifier.updateLineInput(1, '世');
        expect(notifier.totalKeystrokes, 5); // + 1 = 5
      });

      test('correctKeystrokes counts matching characters', () {
        notifier.loadText('你好啊。世界。');
        notifier.initializeLines(['你好啊。', '世界。']);
        notifier.updateLineInput(0, '你好哦'); // last char wrong
        expect(notifier.correctKeystrokes, 2);
        expect(notifier.incorrectKeystrokes, 1);
      });

      test('accuracy is 100% with all correct', () {
        notifier.loadText('你好。世界。');
        notifier.initializeLines(['你好。', '世界。']);
        notifier.updateLineInput(0, '你好。');
        notifier.updateLineInput(1, '世界。');
        expect(notifier.accuracyPercent, 100.0);
      });

      test('accuracy is 50% with half wrong', () {
        loadSingleLine('测试');
        notifier.updateLineInput(0, '测X'); // 1 correct, 1 wrong
        expect(notifier.accuracyPercent, 50.0);
      });

      test('accuracy is 100% when no keystrokes', () {
        loadSingleLine('测试');
        expect(notifier.accuracyPercent, 100.0);
      });

      test('cpm returns 0 when no correct keystrokes', () {
        loadSingleLine('测试');
        expect(notifier.cpm, 0.0);
      });

      test('cpm is positive after typing correct characters', () async {
        loadSingleLine('你好世界');
        notifier.updateLineInput(0, '你');
        await Future.delayed(const Duration(milliseconds: 100));
        expect(notifier.cpm, greaterThan(0.0));
      });

      test('wpm is cpm divided by 5', () {
        loadSingleLine('你好世界');
        notifier.updateLineInput(0, '你');
        // CPM/WPM relationship holds always.
        expect(notifier.wpm, notifier.cpm / 5.0);
      });

      test('progressPercent reflects multi-line completion', () {
        notifier.loadText('你好。世界。');
        notifier.initializeLines(['你好。', '世界。']); // 6 chars total
        expect(notifier.progressPercent, 0.0);

        notifier.updateLineInput(0, '你好。');
        expect(notifier.progressPercent, closeTo(50.0, 1.0));

        notifier.updateLineInput(1, '世界。');
        expect(notifier.progressPercent, 100.0);
      });
    });

    group('forceFinish', () {
      test('sets isFinished to true', () {
        loadSingleLine('你好世界');
        notifier.forceFinish();
        expect(notifier.isFinished, true);
      });
    });

    group('restart', () {
      test('resets but keeps raw text', () {
        loadSingleLine('你好世界');
        notifier.updateLineInput(0, '你好');

        notifier.restart();

        expect(notifier.rawText, '你好世界');
        expect(notifier.linesInitialized, false);
        expect(notifier.isStarted, false);
        expect(notifier.isFinished, false);
      });
    });
  });
}
