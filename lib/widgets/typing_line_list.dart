import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/typing_notifier.dart';
import 'typing_line.dart';

/// Renders a scrollable list of typing lines.
///
/// Splits text using [LayoutBuilder] constraints and the configured
/// [fontSize], then renders each line as a [TypingLine].
class TypingLineList extends StatefulWidget {
  final double fontSize;

  const TypingLineList({super.key, this.fontSize = 22});

  @override
  State<TypingLineList> createState() => _TypingLineListState();
}

class _TypingLineListState extends State<TypingLineList> {
  double? _initializedFontSize;

  /// Splits [text] into lines that fit within [maxWidth] when rendered
  /// at the given [fontSize].
  static List<String> splitText(
      String text, double maxWidth, double fontSize, TextScaler scaler) {
    if (maxWidth <= 80) maxWidth = 80;

    final textStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    );

    final result = <String>[];
    final chars = text.characters;
    int start = 0;

    while (start < chars.length) {
      final remaining = chars.getRange(start, chars.length).string;
      textPainter.text = TextSpan(text: remaining, style: textStyle);
      textPainter.layout(maxWidth: double.infinity);

      if (textPainter.width <= maxWidth) {
        result.add(remaining);
        break;
      }

      int lo = start + 1;
      int hi = chars.length;

      while (lo < hi) {
        final mid = (lo + hi + 1) ~/ 2;
        final substring = chars.getRange(start, mid).string;
        textPainter.text = TextSpan(text: substring, style: textStyle);
        textPainter.layout(maxWidth: double.infinity);
        if (textPainter.width > maxWidth) {
          hi = mid - 1;
        } else {
          lo = mid;
        }
      }

      if (lo == start) lo = start + 1;
      result.add(chars.getRange(start, lo).string);
      start = lo;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final notifier = context.watch<TypingNotifier>();
        final fs = widget.fontSize;

        // Re-initialize if raw text loaded, not yet initialized, or font size changed.
        final needsInit = notifier.rawText.isNotEmpty &&
            (!notifier.linesInitialized || _initializedFontSize != fs);

        if (needsInit) {
          _initializedFontSize = fs;
          // ListView padding (16×2) + TypingLine padding (14×2) + safety (16)
          final textWidth = constraints.maxWidth - 32 - 28 - 16;
          final lines = splitText(
            notifier.rawText,
            textWidth,
            fs,
            MediaQuery.of(context).textScaler,
          );
          notifier.initializeLines(lines);
        }

        if (!notifier.linesInitialized || notifier.targetLines.isEmpty) {
          return const Center(
            child: Text(
              '准备开始...',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
          );
        }

        return _buildLineList(notifier, fs);
      },
    );
  }

  Widget _buildLineList(TypingNotifier notifier, double fontSize) {
    final lines = notifier.targetLines;
    final inputs = notifier.lineInputs;
    final allStatuses = notifier.lineCharStatuses;
    final currentIdx = notifier.currentLineIndex;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemBuilder: (ctx, i) {
        final statuses =
            i < allStatuses.length ? allStatuses[i] : <CharStatus>[];
        return TypingLine(
          key: ValueKey('line_$i'),
          targetLine: lines[i],
          currentInput: i < inputs.length ? inputs[i] : '',
          charStatuses: statuses,
          isActive: i == currentIdx,
          lineIndex: i,
          fontSize: fontSize,
          onChanged: (lineIndex, value) {
            notifier.updateLineInput(lineIndex, value);
          },
        );
      },
    );
  }
}
