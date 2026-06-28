import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/settings_notifier.dart';

/// Dialog for entering custom practice/test text.
class CustomTextDialog extends StatefulWidget {
  const CustomTextDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const CustomTextDialog(),
    );
  }

  @override
  State<CustomTextDialog> createState() => _CustomTextDialogState();
}

class _CustomTextDialogState extends State<CustomTextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsNotifier>();
    _controller = TextEditingController(text: settings.customText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note),
          SizedBox(width: 8),
          Text('自定义文本'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: _controller,
          maxLines: 8,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '在此粘贴或输入你想要练习的文本...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        if (settings.hasCustomText)
          TextButton(
            onPressed: () {
              settings.clearCustomText();
              _controller.clear();
            },
            child: const Text('恢复默认词库'),
          ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () {
            settings.setCustomText(_controller.text);
            Navigator.of(context).pop();
          },
          child: const Text('确认使用'),
        ),
      ],
    );
  }
}
