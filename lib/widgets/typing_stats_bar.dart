import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/typing_notifier.dart';
import '../notifiers/timer_notifier.dart';
import '../notifiers/test_notifier.dart';

/// Displays real-time typing statistics: CPM, WPM, accuracy, and either
/// progress (practice mode) or remaining time (test mode).
class TypingStatsBar extends StatelessWidget {
  const TypingStatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final typing = context.watch<TypingNotifier>();
    final timer = context.watch<TimerNotifier>();
    final test = context.watch<TestNotifier>();

    final isTestMode = test.mode == AppMode.test;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            icon: Icons.speed,
            label: 'CPM',
            value: typing.cpm.toStringAsFixed(0),
          ),
          _StatChip(
            icon: Icons.speed_outlined,
            label: 'WPM',
            value: typing.wpm.toStringAsFixed(0),
          ),
          _StatChip(
            icon: Icons.check_circle_outline,
            label: '正确率',
            value: '${typing.accuracyPercent.toStringAsFixed(1)}%',
          ),
          if (isTestMode)
            _StatChip(
              icon: Icons.timer_outlined,
              label: '剩余',
              value: _formatTime(timer.remainingSeconds),
              urgent: timer.remainingSeconds <= 10 && timer.isRunning,
            )
          else
            _StatChip(
              icon: Icons.edit_note,
              label: '进度',
              value: typing.targetLines.isEmpty
                  ? '0/0'
                  : '${typing.currentLineIndex + 1}/${typing.targetLines.length}',
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool urgent;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = urgent ? Colors.red : Colors.black87;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
        ),
      ],
    );
  }
}
