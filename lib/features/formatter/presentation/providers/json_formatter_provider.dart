import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/json_formatter_utils.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

// Helper structures for Isolate parameters
class _FormatParams {
  final dynamic parsedJson;
  final String indentOption;
  _FormatParams(this.parsedJson, this.indentOption);
}

class _StatsParams {
  final String rawJson;
  final dynamic parsedJson;
  _StatsParams(this.rawJson, this.parsedJson);
}

class _ParseResult {
  final ValidationResult validation;
  final dynamic parsedJson;
  _ParseResult(this.validation, this.parsedJson);
}

// Isolate functions (must be top-level/static for compute)
String _isolateFormat(_FormatParams params) {
  return JsonFormatterUtils.format(params.parsedJson, params.indentOption);
}

String _isolateMinify(dynamic parsedJson) {
  return JsonFormatterUtils.minify(parsedJson);
}

JsonStats _isolateGetStats(_StatsParams params) {
  return JsonFormatterUtils.getStats(params.rawJson, params.parsedJson);
}

_ParseResult _isolateParse(String rawJson) {
  final valResult = JsonFormatterUtils.validate(rawJson);
  if (!valResult.isValid) {
    return _ParseResult(valResult, null);
  }
  try {
    final parsed = json.decode(rawJson);
    return _ParseResult(valResult, parsed);
  } catch (e) {
    return _ParseResult(
      ValidationResult(isValid: false, errorMessage: e.toString(), line: 1, column: 1),
      null,
    );
  }
}

class JsonFormatterState {
  final String rawInput;
  final String formattedOutput;
  final ValidationResult validationResult;
  final JsonStats stats;
  final dynamic parsedJson;
  final bool isLoading;

  JsonFormatterState({
    required this.rawInput,
    required this.formattedOutput,
    required this.validationResult,
    required this.stats,
    this.parsedJson,
    required this.isLoading,
  });

  factory JsonFormatterState.initial() {
    return JsonFormatterState(
      rawInput: '',
      formattedOutput: '',
      validationResult: ValidationResult.valid(),
      stats: JsonStats.empty(),
      parsedJson: null,
      isLoading: false,
    );
  }

  JsonFormatterState copyWith({
    String? rawInput,
    String? formattedOutput,
    ValidationResult? validationResult,
    JsonStats? stats,
    dynamic parsedJson,
    bool? isLoading,
  }) {
    return JsonFormatterState(
      rawInput: rawInput ?? this.rawInput,
      formattedOutput: formattedOutput ?? this.formattedOutput,
      validationResult: validationResult ?? this.validationResult,
      stats: stats ?? this.stats,
      parsedJson: parsedJson ?? this.parsedJson,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class JsonFormatterNotifier extends Notifier<JsonFormatterState> {
  @override
  JsonFormatterState build() {
    return JsonFormatterState.initial();
  }

  /// Updates raw input, runs validation, parsing, and stats compilation in isolates
  Future<void> updateInput(String value) async {
    if (value == state.rawInput) return;

    if (value.trim().isEmpty) {
      state = JsonFormatterState.initial();
      return;
    }

    state = state.copyWith(rawInput: value, isLoading: true);

    try {
      final parseResult = await compute(_isolateParse, value);
      
      if (!parseResult.validation.isValid) {
        state = state.copyWith(
          validationResult: parseResult.validation,
          parsedJson: null,
          stats: JsonStats.empty(),
          isLoading: false,
        );
        return;
      }

      final stats = await compute(
        _isolateGetStats,
        _StatsParams(value, parseResult.parsedJson),
      );

      state = state.copyWith(
        validationResult: parseResult.validation,
        parsedJson: parseResult.parsedJson,
        stats: stats,
        isLoading: false,
      );

      final settings = ref.read(settingsProvider);
      if (settings.autoFormat) {
        format();
      }
    } catch (e) {
      state = state.copyWith(
        validationResult: ValidationResult(
          isValid: false,
          errorMessage: 'An error occurred during parsing: ${e.toString()}',
          line: 1,
          column: 1,
        ),
        parsedJson: null,
        stats: JsonStats.empty(),
        isLoading: false,
      );
    }
  }

  /// Sets raw input and formats it in a single operation
  Future<void> setInputAndFormat(String raw) async {
    state = state.copyWith(rawInput: raw, isLoading: true);
    
    try {
      final parseResult = await compute(_isolateParse, raw);
      if (!parseResult.validation.isValid) {
        state = state.copyWith(
          validationResult: parseResult.validation,
          parsedJson: null,
          stats: JsonStats.empty(),
          formattedOutput: '',
          isLoading: false,
        );
        return;
      }

      final stats = await compute(
        _isolateGetStats,
        _StatsParams(raw, parseResult.parsedJson),
      );

      state = state.copyWith(
        validationResult: parseResult.validation,
        parsedJson: parseResult.parsedJson,
        stats: stats,
      );

      await format();
    } catch (e) {
      state = state.copyWith(
        validationResult: ValidationResult(
          isValid: false,
          errorMessage: 'An error occurred during parsing: ${e.toString()}',
          line: 1,
          column: 1,
        ),
        parsedJson: null,
        stats: JsonStats.empty(),
        formattedOutput: '',
        isLoading: false,
      );
    }
  }

  /// Formats the current parsed JSON structure in an isolate
  Future<void> format() async {
    if (state.parsedJson == null) return;
    
    state = state.copyWith(isLoading: true);
    final settings = ref.read(settingsProvider);
    final indentOption = settings.indentSize == 2 
        ? '2 Spaces' 
        : settings.indentSize == 4 
            ? '4 Spaces' 
            : 'Tab';

    try {
      final formatted = await compute(
        _isolateFormat,
        _FormatParams(state.parsedJson, indentOption),
      );
      state = state.copyWith(
        formattedOutput: formatted,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Minifies the current parsed JSON structure in an isolate
  Future<void> minify() async {
    if (state.parsedJson == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final minified = await compute(_isolateMinify, state.parsedJson);
      state = state.copyWith(
        formattedOutput: minified,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Clears the input, output, stats, and errors
  void clear() {
    state = JsonFormatterState.initial();
  }

  /// Loads a beautiful structured demo JSON object
  void loadDemo() {
    const demo = '''{
  "appName": "JSON Formatter Pro",
  "version": 1.0,
  "isActive": true,
  "developer": {
    "name": "Antigravity",
    "location": "Jaipur, India",
    "skills": ["Flutter", "Dart", "Clean Architecture", "UI Design"]
  },
  "features": [
    {
      "id": "val",
      "name": "Real-time Validation",
      "supported": true
    },
    {
      "id": "fmt",
      "name": "Pretty Formatting",
      "supported": true
    },
    {
      "id": "cmp",
      "name": "Side-by-Side Comparison",
      "supported": true
    },
    {
      "id": "tree",
      "name": "Interactive Tree View",
      "supported": true
    }
  ],
  "tags": ["developer-tool", "saas", "json-utility", "flutter-web"]
}''';
    setInputAndFormat(demo);
  }
}

final jsonFormatterProvider = NotifierProvider<JsonFormatterNotifier, JsonFormatterState>(() {
  return JsonFormatterNotifier();
});
