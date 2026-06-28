import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/test_notifier.dart';
import '../widgets/practice_body.dart';

/// Standalone practice page (kept for direct navigation compatibility).
/// Prefer the tabbed [HomePage] for normal use.
class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('练习模式'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '换一段文字',
            onPressed: () {
              context.read<TestNotifier>().restartPractice();
            },
          ),
        ],
      ),
      body: const PracticeBody(),
    );
  }
}
