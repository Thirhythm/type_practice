import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../notifiers/timer_notifier.dart';
import '../notifiers/test_notifier.dart';
import '../notifiers/settings_notifier.dart';
import '../widgets/practice_body.dart';
import '../widgets/test_body.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/custom_text_dialog.dart';
import '../widgets/test_selection_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  int _lastDuration = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        context.read<TestNotifier>().startPractice();
      } else {
        _promptTestSelection();
      }
    }
  }

  Future<void> _promptTestSelection() async {
    final started = await TestSelectionDialog.show(context);
    if (!started && mounted) {
      // User cancelled — switch back to practice tab.
      _tabController.animateTo(0);
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: '打字练习',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.keyboard, size: 48),
      children: [
        Column(
          children: [
            const Text('一款开源的打字练习与速度测试工具。'),
            Row(
              children: [
                TextButton(
                  onPressed: () => launchUrl(Uri.parse('https://github.com/Thirhythm/type_practice')),
                  child: const Text('GitHub')),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse('https://gitcode.com/Thirhythm/type_practice')),
                    child: const Text('GitCode')),
                ],)
        ],
            )
      ]
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTestTab = _tabController.index == 1;
    final timer = context.watch<TimerNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final remaining = timer.remainingSeconds;

    // Propagate duration setting changes to the running timer.
    final dur = settings.testDurationSeconds;
    if (dur != _lastDuration) {
      _lastDuration = dur;
      if (timer.isRunning) {
        timer.changeDuration(dur);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: isTestTab
            ? Text(
                _formatTime(remaining),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: remaining <= 10 && timer.isRunning
                      ? Colors.red
                      : null,
                ),
              )
            : const Text('打字练习'),
        centerTitle: true,
        actions: [
          if (isTestTab)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '更换篇目',
              onPressed: _promptTestSelection,
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '换一段文字',
              onPressed: () {
                context.read<TestNotifier>().restartPractice();
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: '自定义文本',
            onPressed: () => CustomTextDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => SettingsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '关于',
            onPressed: _showAbout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '打字练习'),
            Tab(text: '速度测试'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PracticeBody(),
          TestBody(),
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
