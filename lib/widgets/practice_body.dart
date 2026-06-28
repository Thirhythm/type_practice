import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/typing_notifier.dart';
import '../notifiers/test_notifier.dart';
import '../notifiers/settings_notifier.dart';
import 'typing_line_list.dart';
import 'typing_stats_bar.dart';

/// The core typing practice area — stats bar + line list.
///
/// This widget manages completion detection and shows a dialog when
/// all lines are typed. It does NOT include an [AppBar] so it can
/// be embedded in a tab view or a custom scaffold.
class PracticeBody extends StatefulWidget {
  const PracticeBody({super.key});

  @override
  State<PracticeBody> createState() => _PracticeBodyState();
}

class _PracticeBodyState extends State<PracticeBody> {
  bool _postFrameScheduled = false;

  void _schedulePostFrameCheck() {
    if (_postFrameScheduled) return;
    _postFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameScheduled = false;
      if (mounted) _checkFinished();
    });
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final testNotifier = context.read<TestNotifier>();
      final typingNotifier = context.read<TypingNotifier>();
      if (typingNotifier.rawText.isEmpty) {
        testNotifier.startPractice();
      }
    });
  }

  void _checkFinished() {
    final typingNotifier = context.read<TypingNotifier>();
    final testNotifier = context.read<TestNotifier>();

    if (typingNotifier.isFinished && testNotifier.mode == AppMode.practice) {
      testNotifier.onTypingFinished();
      if (mounted) _showCompleteDialog();
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 完成！'),
        content: const Text('你已经完成了这段文本的练习。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TestNotifier>().restartPractice();
            },
            child: const Text('再来一次'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TestNotifier>().restartPractice();
            },
            child: const Text('换一段'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<TypingNotifier>();
    final fontSize = context.watch<SettingsNotifier>().targetFontSize;
    _schedulePostFrameCheck();

    return Column(
      children: [
        const TypingStatsBar(),
        Expanded(child: TypingLineList(fontSize: fontSize)),
      ],
    );
  }
}
