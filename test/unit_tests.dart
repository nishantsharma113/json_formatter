import 'package:flutter_test/flutter_test.dart';
import 'package:json_formatter/core/utils/json_formatter_utils.dart';
import 'package:json_formatter/core/utils/dart_model_generator.dart';
import 'package:json_formatter/core/utils/yaml_converter_utils.dart';
import 'package:json_formatter/core/utils/json_compare_utils.dart';

void main() {
  group('JSON Formatter & Validator Tests', () {
    test('Valid JSON Validation', () {
      final res = JsonFormatterUtils.validate('{"name": "John", "age": 30}');
      expect(res.isValid, isTrue);
      expect(res.errorMessage, isNull);
    });

    test('Invalid JSON Validation (Coordinates)', () {
      final res = JsonFormatterUtils.validate('{\n  "name": "John",\n  "age": 30,\n  "nested": {\n    "test": "value"\n  \n}');
      expect(res.isValid, isFalse);
      expect(res.line, isNotNull);
      expect(res.column, isNotNull);
    });

    test('JSON Formatting (2 Spaces)', () {
      final parsed = {"name": "John"};
      final formatted = JsonFormatterUtils.format(parsed, '2 Spaces');
      expect(formatted, equals('{\n  "name": "John"\n}'));
    });

    test('JSON Formatting (4 Spaces)', () {
      final parsed = {"name": "John"};
      final formatted = JsonFormatterUtils.format(parsed, '4 Spaces');
      expect(formatted, equals('{\n    "name": "John"\n}'));
    });

    test('JSON Minification', () {
      final parsed = {"name": "John", "age": 30};
      final minified = JsonFormatterUtils.minify(parsed);
      expect(minified, equals('{"name":"John","age":30}'));
    });

    test('JSON Statistics', () {
      final raw = '{"name": "John", "hobbies": ["reading", "coding"]}';
      final parsed = {"name": "John", "hobbies": ["reading", "coding"]};
      final stats = JsonFormatterUtils.getStats(raw, parsed);
      expect(stats.objectsCount, equals(1));
      expect(stats.arraysCount, equals(1));
      expect(stats.keysCount, equals(2));
      expect(stats.maxDepth, equals(3)); 
    });
  });

  group('JSON Compare Utility Tests', () {
    test('Simple Comparison', () {
      final original = '{"name": "John", "age": 30}';
      final modified = '{"name": "John", "age": 31, "city": "NY"}';
      final diff = JsonCompareUtils.compare(original, modified);

      expect(diff.addedCount, equals(1)); // city
      expect(diff.modifiedCount, equals(1)); // age
      expect(diff.removedCount, equals(0));
    });
  });

  group('YAML Converter Tests', () {
    test('JSON to YAML conversion', () {
      final json = {"name": "John", "hobbies": ["reading", "coding"]};
      final yaml = YamlConverterUtils.convert(json);
      expect(yaml, contains('name: John'));
      expect(yaml, contains('hobbies:'));
      expect(yaml, contains('- reading'));
    });
  });

  group('Dart Model Generator Tests', () {
    test('Dart class generation', () {
      final json = {"id": 1, "name": "John"};
      final code = DartModelGenerator().generate(json, 'User');
      expect(code, contains('class User'));
      expect(code, contains('final int id;'));
      expect(code, contains('final String name;'));
      expect(code, contains('factory User.fromJson'));
      expect(code, contains('Map<String, dynamic> toJson'));
    });
  });
}
