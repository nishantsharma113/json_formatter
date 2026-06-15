import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/settings_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main()');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

class SettingsState {
  final ThemeMode themeMode;
  final double fontSize;
  final String fontFamily;
  final bool wordWrap;
  final bool showLineNumbers;
  final int indentSize;
  final bool autoFormat;

  SettingsState({
    required this.themeMode,
    required this.fontSize,
    required this.fontFamily,
    required this.wordWrap,
    required this.showLineNumbers,
    required this.indentSize,
    required this.autoFormat,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontSize,
    String? fontFamily,
    bool? wordWrap,
    bool? showLineNumbers,
    int? indentSize,
    bool? autoFormat,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      wordWrap: wordWrap ?? this.wordWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      indentSize: indentSize ?? this.indentSize,
      autoFormat: autoFormat ?? this.autoFormat,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late SettingsService _service;

  @override
  SettingsState build() {
    _service = ref.watch(settingsServiceProvider);
    return SettingsState(
      themeMode: _service.themeMode,
      fontSize: _service.fontSize,
      fontFamily: _service.fontFamily,
      wordWrap: _service.wordWrap,
      showLineNumbers: _service.showLineNumbers,
      indentSize: _service.indentSize,
      autoFormat: _service.autoFormat,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _service.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setFontSize(double size) async {
    await _service.setFontSize(size);
    state = state.copyWith(fontSize: size);
  }

  Future<void> setFontFamily(String family) async {
    await _service.setFontFamily(family);
    state = state.copyWith(fontFamily: family);
  }

  Future<void> setWordWrap(bool wrap) async {
    await _service.setWordWrap(wrap);
    state = state.copyWith(wordWrap: wrap);
  }

  Future<void> setShowLineNumbers(bool show) async {
    await _service.setShowLineNumbers(show);
    state = state.copyWith(showLineNumbers: show);
  }

  Future<void> setIndentSize(int size) async {
    await _service.setIndentSize(size);
    state = state.copyWith(indentSize: size);
  }

  Future<void> setAutoFormat(bool auto) async {
    await _service.setAutoFormat(auto);
    state = state.copyWith(autoFormat: auto);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
