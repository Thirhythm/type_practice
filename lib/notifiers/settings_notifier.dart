import 'package:flutter/material.dart';

/// User-configurable settings for the typing app.
///
/// Injected globally via [MultiProvider]. When settings change,
/// widgets that [watch] this notifier rebuild automatically.
class SettingsNotifier extends ChangeNotifier {
  int _testDurationSeconds = 60;
  double _targetFontSize = 22;
  ThemeMode _themeMode = ThemeMode.system;
  String? _customText;

  // ── Getters ────────────────────────────────────────────────────────

  int get testDurationSeconds => _testDurationSeconds;
  double get targetFontSize => _targetFontSize;
  ThemeMode get themeMode => _themeMode;
  String? get customText => _customText;
  bool get hasCustomText => _customText != null && _customText!.isNotEmpty;

  // ── Duration ───────────────────────────────────────────────────────

  static const durationPresets = [60, 120, 300, 600];

  void setTestDuration(int seconds) {
    final clamped = seconds.clamp(5, 3600); // 5s – 1 hour
    if (clamped != _testDurationSeconds) {
      _testDurationSeconds = clamped;
      notifyListeners();
    }
  }

  // ── Font size ──────────────────────────────────────────────────────

  static const fontSizeOptions = [18.0, 22.0, 26.0];

  void setFontSize(double size) {
    if (fontSizeOptions.contains(size) && size != _targetFontSize) {
      _targetFontSize = size;
      notifyListeners();
    }
  }

  // ── Theme ──────────────────────────────────────────────────────────

  void setThemeMode(ThemeMode mode) {
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // ── Custom text ────────────────────────────────────────────────────

  void setCustomText(String text) {
    _customText = text.trim().isEmpty ? null : text.trim();
    notifyListeners();
  }

  void clearCustomText() {
    _customText = null;
    notifyListeners();
  }

  // ── Reset ──────────────────────────────────────────────────────────

  void resetAll() {
    _testDurationSeconds = 60;
    _targetFontSize = 22;
    _themeMode = ThemeMode.system;
    _customText = null;
    notifyListeners();
  }
}
