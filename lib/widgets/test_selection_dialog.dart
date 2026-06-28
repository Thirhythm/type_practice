import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/settings_notifier.dart';
import '../notifiers/test_notifier.dart';
import '../services/word_bank_service.dart';
import 'custom_text_dialog.dart';

/// Dialog that lets the user pick a test passage before starting.
class TestSelectionDialog extends StatelessWidget {
  const TestSelectionDialog({super.key});

  /// Show the dialog and start the test when the user picks a passage
  /// or chooses custom text. Returns true if a test was started.
  static Future<bool> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TestSelectionDialog(),
    ).then((started) => started ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final testNotifier = context.read<TestNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final passages = testNotifier.wordBank.testPassages;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.menu_book),
          SizedBox(width: 8),
          Text('选择测试篇目'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '共 ${passages.length} 篇',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: passages.length + (settings.hasCustomText ? 1 : 0),
                itemBuilder: (ctx, i) {
                  // Custom text option at the top if set.
                  if (settings.hasCustomText && i == 0) {
                    return _CustomTextCard(
                      preview: settings.customText!,
                      onTap: () {
                        testNotifier.startTestWithCustomText();
                        Navigator.of(context).pop(true);
                      },
                    );
                  }

                  final idx = settings.hasCustomText ? i - 1 : i;
                  final p = passages[idx];
                  return _PassageCard(
                    passage: p,
                    onTap: () {
                      testNotifier.startTestWithPassage(p);
                      Navigator.of(context).pop(true);
                    },
                  );
                },
              ),
            ),
            const Divider(),
            TextButton.icon(
              onPressed: () async {
                await CustomTextDialog.show(context);
                // After dialog closes, rebuild to show/hide custom entry.
                if (context.mounted) {
                  (context as Element).markNeedsBuild();
                }
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('使用自定义文本'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// Card showing a literary passage with title, author, char count, and preview.
class _PassageCard extends StatelessWidget {
  final TestPassage passage;
  final VoidCallback onTap;

  const _PassageCard({required this.passage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      passage.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    '${passage.charCount} 字',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                passage.author,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                passage.preview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for the custom text option.
class _CustomTextCard extends StatelessWidget {
  final String preview;
  final VoidCallback onTap;

  const _CustomTextCard({required this.preview, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer.withAlpha(80),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '自定义文本',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  Text(
                    '${preview.characters.length} 字',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preview.length > 50 ? '${preview.substring(0, 50)}…' : preview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
