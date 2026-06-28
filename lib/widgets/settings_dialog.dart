import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/settings_notifier.dart';

/// Settings dialog for test duration, font size, and theme mode.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late final TextEditingController _customDurationCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsNotifier>();
    _customDurationCtrl =
        TextEditingController(text: s.testDurationSeconds.toString());
  }

  @override
  void dispose() {
    _customDurationCtrl.dispose();
    super.dispose();
  }

  void _applyCustomDuration(String raw) {
    final seconds = int.tryParse(raw.trim());
    if (seconds != null && seconds > 0) {
      final settings = context.read<SettingsNotifier>();
      settings.setTestDuration(seconds);
      // Sync field back to clamped value.
      _customDurationCtrl.text = settings.testDurationSeconds.toString();
    }
  }

  void _onPresetSelected(int seconds) {
    final settings = context.read<SettingsNotifier>();
    settings.setTestDuration(seconds);
    // Sync text field to preset.
    _customDurationCtrl.text = seconds.toString();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings),
          SizedBox(width: 8),
          Text('设置'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Test duration ──────────────────────────────────────
            _SectionLabel('测试时长（秒）'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: SettingsNotifier.durationPresets.map((d) {
                final isSelected = d == settings.testDurationSeconds;
                return ChoiceChip(
                  label: Text('${d}s'),
                  selected: isSelected,
                  onSelected: (_) => _onPresetSelected(d),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 4),
                const Text('自定义：', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _customDurationCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                      suffixText: 's',
                    ),
                    onSubmitted: _applyCustomDuration,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(5 – 3600)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Font size ──────────────────────────────────────────
            _SectionLabel('字体大小'),
            const SizedBox(height: 6),
            SegmentedButton<double>(
              segments: SettingsNotifier.fontSizeOptions
                  .map((s) =>
                      ButtonSegment(value: s, label: Text('${s.toInt()}px')))
                  .toList(),
              selected: {settings.targetFontSize},
              onSelectionChanged: (v) => settings.setFontSize(v.first),
            ),
            const SizedBox(height: 20),

            // ── Theme ──────────────────────────────────────────────
            _SectionLabel('主题'),
            const SizedBox(height: 6),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system, label: Text('跟随系统')),
                ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => settings.setThemeMode(v.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            settings.resetAll();
            Navigator.of(context).pop();
          },
          child: const Text('恢复默认'),
        ),
        FilledButton(
          onPressed: () {
            _applyCustomDuration(_customDurationCtrl.text);
            Navigator.of(context).pop();
          },
          child: const Text('完成'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
