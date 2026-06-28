import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/timer_notifier.dart';
import '../notifiers/test_notifier.dart';
import '../widgets/test_body.dart';

/// Standalone test page (kept for direct navigation compatibility).
/// Prefer the tabbed [HomePage] for normal use.
class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerNotifier>();
    final remaining = timer.remainingSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _formatTime(remaining),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color:
                  remaining <= 10 && timer.isRunning ? Colors.red : null,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: '退出测试',
            onPressed: () => _showExitDialog(context),
          ),
        ),
        body: const TestBody(),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出测试？'),
        content: const Text('当前测试的进度将会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续测试'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TestNotifier>().returnToHome();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
