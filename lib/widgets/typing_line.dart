import 'package:flutter/material.dart';
import '../notifiers/typing_notifier.dart';

/// A single typing line: target text above, input field below.
///
/// ```
/// ┌─────────────────────────────────┐
/// │ 今天天气真好啊我去公园散步       │  ← target text (character-colored RichText)
/// │ [_____________________________] │  ← input TextField
/// └─────────────────────────────────┘
/// ```
class TypingLine extends StatefulWidget {
  final String targetLine;
  final String currentInput;
  final List<CharStatus> charStatuses;
  final bool isActive;
  final int lineIndex;
  final double fontSize;
  final void Function(int lineIndex, String value) onChanged;

  const TypingLine({
    super.key,
    required this.targetLine,
    required this.currentInput,
    required this.charStatuses,
    required this.isActive,
    required this.lineIndex,
    required this.fontSize,
    required this.onChanged,
  });

  @override
  State<TypingLine> createState() => _TypingLineState();
}

class _TypingLineState extends State<TypingLine> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentInput);
    _focusNode = FocusNode();
    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(TypingLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller when notifier state differs (overflow, restart, etc.)
    if (widget.currentInput != _controller.text) {
      final composing = _controller.value.composing;
      if (composing.isValid && !composing.isCollapsed) {
        // IME is actively composing. Only sync when the committed text
        // (excluding composing region) genuinely differs — otherwise
        // preserve the IME composing state.
        final committed = _controller.text.substring(0, composing.start) +
            _controller.text.substring(composing.end);
        if (committed != widget.currentInput) {
          _controller.value = TextEditingValue(
            text: widget.currentInput,
            selection: TextSelection.collapsed(
              offset: widget.currentInput.length,
            ),
          );
        }
      } else {
        _controller.value = TextEditingValue(
          text: widget.currentInput,
          selection: TextSelection.collapsed(
            offset: widget.currentInput.length,
          ),
        );
      }
    }
    // Auto-focus when this line becomes the active one.
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        // Defer cursor reset to after the focus-change frame so that
        // EditableText's own focus handler (which may select-all) does
        // not override our collapsed-end selection.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Extract committed text (filtering out IME composing pinyin) and
  /// forward to the notifier only when it genuinely differs from the
  /// current notifier state.
  void _onControllerChanged() {
    final value = _controller.value;
    final composing = value.composing;

    final String committed;
    if (composing.isValid && !composing.isCollapsed) {
      committed = value.text.substring(0, composing.start) +
          value.text.substring(composing.end);
    } else {
      committed = value.text;
    }

    // Only emit actual user input — skip programmatic syncs where the
    // committed text already matches the notifier's ground truth.
    if (committed != widget.currentInput) {
      widget.onChanged(widget.lineIndex, committed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.targetLine.characters;
    final statuses = widget.charStatuses;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isActive
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(40)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: widget.isActive
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withAlpha(80),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top: Target text as flowing RichText ──────────────────
          _buildTargetText(chars, statuses),
          const SizedBox(height: 10),
          // ── Bottom: Input TextField ───────────────────────────────
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.isActive,
            style: TextStyle(
              fontSize: widget.fontSize - 2,
              height: 1.4,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
            decoration: InputDecoration(
              hintText: widget.isActive ? '在此输入...' : '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Build target text using [RichText] with per-character [TextSpan]
  /// children — avoids per-character [RenderObject] overhead of [Wrap].
  Widget _buildTargetText(Iterable<String> chars, List<CharStatus> statuses) {
    final spans = <InlineSpan>[];
    for (int i = 0; i < chars.length; i++) {
      final char = chars.elementAt(i);
      final status = i < statuses.length ? statuses[i] : CharStatus.pending;
      final colors = _kStatusColors[status]!;

      spans.add(TextSpan(
        text: char,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: colors.text,
          backgroundColor: colors.background,
          decoration:
              status == CharStatus.current ? TextDecoration.underline : null,
          decorationColor: colors.text,
          decorationThickness: 2,
        ),
      ));
    }
    return RichText(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    );
  }
}

class _StatusColors {
  final Color background;
  final Color text;
  const _StatusColors(this.background, this.text);
}

const _kStatusColors = {
  CharStatus.pending:
      _StatusColors(Colors.transparent, Color(0xFF999999)),
  CharStatus.current:
      _StatusColors(Color(0xFFE3F2FD), Color(0xFF1565C0)),
  CharStatus.correct:
      _StatusColors(Colors.transparent, Color(0xFF2E7D32)),
  CharStatus.incorrect:
      _StatusColors(Color(0xFFFFCDD2), Color(0xFFC62828)),
};
