import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/test_notifier.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final testNotifier = context.watch<TestNotifier>();
    final result = testNotifier.result;

    if (result == null) {
      // No result — already navigated away, show blank.
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('测试结果'),
        centerTitle: true,
        leading: const SizedBox.shrink(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon
                  Icon(
                    _trophyIcon(result.accuracyPercent),
                    size: 56,
                    color: _trophyColor(result.accuracyPercent),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    '你的打字成绩',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Core metrics: CPM + WPM
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BigMetric(
                        value: result.cpm.toStringAsFixed(0),
                        label: '字/分钟 (CPM)',
                      ),
                      _BigMetric(
                        value: result.wpm.toStringAsFixed(0),
                        label: '词/分钟 (WPM)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Detail rows
                  _DetailRow('正确率', '${result.accuracyPercent.toStringAsFixed(1)}%'),
                  _DetailRow('正确字数', '${result.correctCharacters}'),
                  _DetailRow('错误字数', '${result.incorrectCharacters}'),
                  _DetailRow('总字数', '${result.totalCharacters}'),
                  _DetailRow('用时', '${result.elapsedSeconds.toStringAsFixed(1)} 秒'),

                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          testNotifier.returnToHome();
                          Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text('返回首页'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: () {
                          testNotifier.restartTest();
                          Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text('再来一次'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _trophyIcon(double accuracy) {
    if (accuracy >= 98) return Icons.emoji_events;
    if (accuracy >= 90) return Icons.star;
    return Icons.check_circle;
  }

  Color _trophyColor(double accuracy) {
    if (accuracy >= 98) return Colors.amber;
    if (accuracy >= 90) return Colors.orange;
    return Colors.green;
  }
}

/// A large centered metric display (e.g. CPM value).
class _BigMetric extends StatelessWidget {
  final String value;
  final String label;

  const _BigMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A single detail row in the result table.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
