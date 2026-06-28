import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_practice/notifiers/typing_notifier.dart';
import 'package:type_practice/notifiers/timer_notifier.dart';
import 'package:type_practice/notifiers/test_notifier.dart';
import 'package:type_practice/notifiers/settings_notifier.dart';

/// Helper: simulate the widget layer by loading text and initializing
/// it as a single line.
void _initFromNotifier(TypingNotifier typing, String text) {
  typing.loadText(text);
  typing.initializeLines([text]);
}

/// Helper: start a test with a random passage.
void _startTest(TestNotifier tn) {
  tn.startTestWithPassage(tn.wordBank.getRandomTestPassage());
}

void main() {
  group('TestNotifier', () {
    late TypingNotifier typingNotifier;
    late TimerNotifier timerNotifier;
    late SettingsNotifier settingsNotifier;
    late TestNotifier testNotifier;

    setUp(() {
      typingNotifier = TypingNotifier();
      timerNotifier = TimerNotifier();
      settingsNotifier = SettingsNotifier();
      testNotifier = TestNotifier(
        typingNotifier: typingNotifier,
        timerNotifier: timerNotifier,
        settings: settingsNotifier,
      );
    });

    tearDown(() {
      timerNotifier.dispose();
    });

    group('startPractice', () {
      test('sets mode to practice and loads text', () {
        testNotifier.startPractice();

        expect(testNotifier.mode, AppMode.practice);
        expect(typingNotifier.rawText.isNotEmpty, true);
      });

      test('resets any previous result', () {
        _startTest(testNotifier);
        _initFromNotifier(typingNotifier, typingNotifier.rawText);
        typingNotifier.updateLineInput(0, typingNotifier.rawText);
        testNotifier.onTypingFinished();
        expect(testNotifier.result, isNotNull);

        testNotifier.startPractice();
        expect(testNotifier.result, isNull);
      });
    });

    group('startTest', () {
      test('uses configured duration from settings', () {
        settingsNotifier.setTestDuration(30);
        _startTest(testNotifier);

        expect(testNotifier.mode, AppMode.test);
        expect(typingNotifier.rawText.isNotEmpty, true);
        expect(typingNotifier.rawText.length, greaterThan(100));
        expect(timerNotifier.isRunning, true);
        expect(timerNotifier.totalSeconds, 30);
      });

      test('startTestWithCustomText uses custom text', () {
        settingsNotifier.setCustomText('自定义测试文本内容');
        testNotifier.startTestWithCustomText();

        expect(typingNotifier.rawText, '自定义测试文本内容');
      });

      test('startTestWithPassage stores selected passage', () {
        final passage = testNotifier.wordBank.testPassages.first;
        testNotifier.startTestWithPassage(passage);

        expect(testNotifier.selectedPassage, passage);
        expect(typingNotifier.rawText, passage.text);
      });
    });

    group('onTypingFinished', () {
      test('creates result and sets mode to finished', () {
        testNotifier.startPractice();
        _initFromNotifier(typingNotifier, typingNotifier.rawText);
        final text = typingNotifier.rawText;
        typingNotifier.updateLineInput(0, text);

        testNotifier.onTypingFinished();

        expect(testNotifier.mode, AppMode.finished);
        expect(testNotifier.result, isNotNull);
        expect(testNotifier.result!.correctCharacters,
            typingNotifier.correctKeystrokes);
      });

      test('does nothing when mode is idle', () {
        testNotifier.onTypingFinished();
        expect(testNotifier.mode, AppMode.idle);
        expect(testNotifier.result, isNull);
      });
    });

    group('onTimerExpired', () {
      test('force-finishes typing and creates result', () {
        _startTest(testNotifier);
        _initFromNotifier(typingNotifier, typingNotifier.rawText);
        typingNotifier.updateLineInput(
            0, typingNotifier.rawText.characters.first);

        testNotifier.onTimerExpired();

        expect(testNotifier.mode, AppMode.finished);
        expect(testNotifier.result, isNotNull);
        expect(typingNotifier.isFinished, true);
      });

      test('does nothing when not in test mode', () {
        testNotifier.startPractice();
        testNotifier.onTimerExpired();
        expect(testNotifier.mode, AppMode.practice);
      });
    });

    group('restartPractice', () {
      test('loads fresh text and stays in practice mode', () {
        testNotifier.startPractice();
        _initFromNotifier(typingNotifier, typingNotifier.rawText);

        testNotifier.restartPractice();

        expect(testNotifier.mode, AppMode.practice);
        expect(typingNotifier.rawText.isNotEmpty, true);
        expect(typingNotifier.linesInitialized, false);
      });
    });

    group('restartTest', () {
      test('loads text and restarts timer with configured duration', () {
        settingsNotifier.setTestDuration(30);
        _startTest(testNotifier);
        _initFromNotifier(typingNotifier, typingNotifier.rawText);

        testNotifier.restartTest();

        expect(testNotifier.mode, AppMode.test);
        expect(typingNotifier.rawText.isNotEmpty, true);
        expect(typingNotifier.linesInitialized, false);
        expect(timerNotifier.totalSeconds, 30);
        expect(timerNotifier.isRunning, true);
      });
    });

    group('returnToHome', () {
      test('resets everything to idle', () {
        _startTest(testNotifier);
        _initFromNotifier(typingNotifier, typingNotifier.rawText);
        typingNotifier.updateLineInput(
            0, typingNotifier.rawText.characters.first);

        testNotifier.returnToHome();

        expect(testNotifier.mode, AppMode.idle);
        expect(testNotifier.result, isNull);
        expect(typingNotifier.rawText, '');
        expect(timerNotifier.isRunning, false);
      });
    });

    group('word bank', () {
      test('practice phrases differ between calls', () {
        testNotifier.startPractice();
        final first = typingNotifier.rawText;
        final texts = <String>{first};

        for (var i = 0; i < 5; i++) {
          testNotifier.restartPractice();
          texts.add(typingNotifier.rawText);
        }

        expect(texts.length, greaterThanOrEqualTo(2));
      });

      test('test passages are 300+ characters', () {
        for (final p in testNotifier.wordBank.testPassages) {
          expect(p.charCount, greaterThanOrEqualTo(300));
          expect(p.charCount, lessThanOrEqualTo(700));
        }
      });

      test('test passages have 6+ entries', () {
        expect(testNotifier.wordBank.testPassages.length, greaterThanOrEqualTo(6));
      });
    });
  });
}
