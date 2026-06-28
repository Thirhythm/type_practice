import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/typing_notifier.dart';
import '../notifiers/timer_notifier.dart';
import '../notifiers/test_notifier.dart';
import '../notifiers/settings_notifier.dart';
import 'typing_line_list.dart';
import 'typing_stats_bar.dart';

/// The core timed test area — stats bar + line list with countdown.
///
/// Monitors both typing completion and timer expiry, navigating to
/// `/result` when either triggers. Does NOT include an [AppBar].
class TestBody extends StatefulWidget {
  const TestBody({super.key});

  @override
  State<TestBody> createState() => _TestBodyState();
}

class _TestBodyState extends State<TestBody> {
  bool _navigatingToResult = false;
  bool _postFrameScheduled = false;

  void _schedulePostFrameCheck() {
    if (_postFrameScheduled) return;
    _postFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameScheduled = false;
      if (mounted) {
        _checkFinished();
        _checkTimerExpired();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final testNotifier = context.read<TestNotifier>();
      final typingNotifier = context.read<TypingNotifier>();
      if (typingNotifier.rawText.isEmpty) {
        testNotifier
            .startTestWithPassage(testNotifier.wordBank.getRandomTestPassage());
      }
    });
  }

  void _checkFinished() {
    final typingNotifier = context.read<TypingNotifier>();
    final testNotifier = context.read<TestNotifier>();

    if (typingNotifier.isFinished &&
        testNotifier.mode == AppMode.test &&
        !_navigatingToResult) {
      testNotifier.onTypingFinished();
      _goToResult();
    }
  }

  void _checkTimerExpired() {
    final timer = context.read<TimerNotifier>();
    if (timer.isExpired && !_navigatingToResult) {
      final testNotifier = context.read<TestNotifier>();
      testNotifier.onTimerExpired();
      _goToResult();
    }
  }

  void _goToResult() {
    _navigatingToResult = true;
    Navigator.pushNamed(context, '/result');
  }

  @override
  Widget build(BuildContext context) {
    final typingNotifier = context.watch<TypingNotifier>();
    context.watch<TimerNotifier>(); // triggers rebuild on timer ticks
    final fontSize = context.watch<SettingsNotifier>().targetFontSize;

    // Reset the navigation guard when a fresh test starts (e.g. after
    // "再来一次" pops back from the result page). At that point the
    // typing engine has been reloaded and isStarted is false.
    if (!typingNotifier.isStarted) {
      _navigatingToResult = false;
    }

    _schedulePostFrameCheck();

    return Column(
      children: [
        const TypingStatsBar(),
        Expanded(child: TypingLineList(fontSize: fontSize)),
      ],
    );
  }
}
