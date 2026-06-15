import 'dart:convert';

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? line;
  final int? column;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.line,
    this.column,
  });

  factory ValidationResult.valid() => ValidationResult(isValid: true);
}

class JsonStats {
  final int objectsCount;
  final int arraysCount;
  final int keysCount;
  final int charactersCount;
  final int linesCount;
  final double fileSizeKb;
  final int maxDepth;

  JsonStats({
    required this.objectsCount,
    required this.arraysCount,
    required this.keysCount,
    required this.charactersCount,
    required this.linesCount,
    required this.fileSizeKb,
    required this.maxDepth,
  });

  factory JsonStats.empty() {
    return JsonStats(
      objectsCount: 0,
      arraysCount: 0,
      keysCount: 0,
      charactersCount: 0,
      linesCount: 0,
      fileSizeKb: 0,
      maxDepth: 0,
    );
  }
}

class JsonFormatterUtils {
  /// Validates a raw JSON string. If invalid, parses details of FormatException to compute line/column info.
  static ValidationResult validate(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Input is empty',
        line: 1,
        column: 1,
      );
    }
    try {
      json.decode(rawJson);
      return ValidationResult.valid();
    } on FormatException catch (e) {
      final offset = e.offset;
      if (offset != null) {
        int line = 1;
        int column = 1;
        for (int i = 0; i < offset && i < rawJson.length; i++) {
          if (rawJson[i] == '\n') {
            line++;
            column = 1;
          } else {
            column++;
          }
        }
        return ValidationResult(
          isValid: false,
          errorMessage: e.message,
          line: line,
          column: column,
        );
      }
      return ValidationResult(
        isValid: false,
        errorMessage: e.message,
        line: 1,
        column: 1,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: e.toString(),
        line: 1,
        column: 1,
      );
    }
  }

  /// Formats JSON string with selected indent level
  static String format(dynamic parsedJson, String indentOption) {
    String indent = '  ';
    if (indentOption == '4 Spaces') {
      indent = '    ';
    } else if (indentOption == 'Tab') {
      indent = '\t';
    }
    final encoder = JsonEncoder.withIndent(indent);
    return encoder.convert(parsedJson);
  }

  /// Minifies JSON string into a compact format
  static String minify(dynamic parsedJson) {
    final encoder = const JsonEncoder();
    return encoder.convert(parsedJson);
  }

  /// Compiles metadata and statistics of a parsed JSON object
  static JsonStats getStats(String rawJson, dynamic parsedJson) {
    if (rawJson.trim().isEmpty || parsedJson == null) {
      return JsonStats.empty();
    }

    final collector = StatsCollector()..collect(parsedJson);
    final characterCount = rawJson.length;
    final linesCount = '\n'.allMatches(rawJson).length + 1;
    final fileSizeKb = characterCount / 1024.0;
    final maxDepth = _getMaxDepth(parsedJson);

    return JsonStats(
      objectsCount: collector.objects,
      arraysCount: collector.arrays,
      keysCount: collector.keys,
      charactersCount: characterCount,
      linesCount: linesCount,
      fileSizeKb: fileSizeKb,
      maxDepth: maxDepth,
    );
  }

  static int _getMaxDepth(dynamic value) {
    if (value is Map) {
      if (value.isEmpty) return 1;
      int maxSubDepth = 0;
      for (var val in value.values) {
        final d = _getMaxDepth(val);
        if (d > maxSubDepth) maxSubDepth = d;
      }
      return maxSubDepth + 1;
    } else if (value is List) {
      if (value.isEmpty) return 1;
      int maxSubDepth = 0;
      for (var val in value) {
        final d = _getMaxDepth(val);
        if (d > maxSubDepth) maxSubDepth = d;
      }
      return maxSubDepth + 1;
    }
    return 1;
  }
}

class StatsCollector {
  int objects = 0;
  int arrays = 0;
  int keys = 0;

  void collect(dynamic value) {
    if (value is Map) {
      objects++;
      keys += value.length;
      value.values.forEach(collect);
    } else if (value is List) {
      arrays++;
      value.forEach(collect);
    }
  }
}
