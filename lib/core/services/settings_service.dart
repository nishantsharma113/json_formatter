import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const String _themeKey = 'setting_theme';
  static const String _fontSizeKey = 'setting_font_size';
  static const String _fontFamilyKey = 'setting_font_family';
  static const String _wordWrapKey = 'setting_word_wrap';
  static const String _lineNumbersKey = 'setting_line_numbers';
  static const String _indentSizeKey = 'setting_indent_size';
  static const String _autoFormatKey = 'setting_auto_format';

  ThemeMode get themeMode {
    final val = _prefs.getString(_themeKey);
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
  }

  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 14.0;
  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }

  String get fontFamily => _prefs.getString(_fontFamilyKey) ?? 'JetBrains Mono';
  Future<void> setFontFamily(String family) async {
    await _prefs.setString(_fontFamilyKey, family);
  }

  bool get wordWrap => _prefs.getBool(_wordWrapKey) ?? true;
  Future<void> setWordWrap(bool wrap) async {
    await _prefs.setBool(_wordWrapKey, wrap);
  }

  bool get showLineNumbers => _prefs.getBool(_lineNumbersKey) ?? true;
  Future<void> setShowLineNumbers(bool show) async {
    await _prefs.setBool(_lineNumbersKey, show);
  }

  int get indentSize => _prefs.getInt(_indentSizeKey) ?? 2;
  Future<void> setIndentSize(int size) async {
    await _prefs.setInt(_indentSizeKey, size);
  }

  bool get autoFormat => _prefs.getBool(_autoFormatKey) ?? false;
  Future<void> setAutoFormat(bool auto) async {
    await _prefs.setBool(_autoFormatKey, auto);
  }
}
