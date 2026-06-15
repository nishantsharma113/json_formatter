class DartModelGenerator {
  final Map<String, String> _generatedClasses = {};

  String generate(dynamic jsonInput, String rootClassName) {
    _generatedClasses.clear();
    final cleanClassName = _toPascalCase(
      rootClassName.isEmpty ? 'RootModel' : rootClassName,
    );

    if (jsonInput is Map<String, dynamic>) {
      _generateClass(cleanClassName, jsonInput);
    } else if (jsonInput is List && jsonInput.isNotEmpty) {
      final first = jsonInput.first;
      if (first is Map<String, dynamic>) {
        _generateClass(cleanClassName, first);
      } else {
        return '// Top-level lists of primitive types do not require a custom class.';
      }
    } else {
      return '// Invalid JSON structure for Dart model generation. Please provide an Object or List of Objects.';
    }

    final sb = StringBuffer();
    if (_generatedClasses.containsKey(cleanClassName)) {
      sb.writeln(_generatedClasses[cleanClassName]);
      sb.writeln();
    }
    _generatedClasses.forEach((className, code) {
      if (className != cleanClassName) {
        sb.writeln(code);
        sb.writeln();
      }
    });

    return sb.toString();
  }

  void _generateClass(String className, Map<String, dynamic> jsonMap) {
    if (_generatedClasses.containsKey(className)) return;

    // Temporary addition to avoid circular dependency loop
    _generatedClasses[className] = '';

    final fields = <_DartField>[];

    jsonMap.forEach((key, value) {
      final fieldName = _toCamelCase(key);
      final fieldType = _determineFieldType(key, value);
      fields.add(
        _DartField(
          originalKey: key,
          fieldName: fieldName,
          type: fieldType,
          isNullable: value == null,
        ),
      );
    });

    final sb = StringBuffer();
    sb.writeln('class $className {');

    // Field declarations
    for (var field in fields) {
      sb.writeln(
        '  final ${field.type}${field.isNullable ? "?" : ""} ${field.fieldName};',
      );
    }
    sb.writeln();

    // Constructor
    sb.writeln('  $className({');
    for (var field in fields) {
      sb.writeln('    required this.${field.fieldName},');
    }
    sb.writeln('  });');
    sb.writeln();

    // fromJson Factory
    sb.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    sb.writeln('    return $className(');
    for (var field in fields) {
      final key = field.originalKey;
      final name = field.fieldName;
      final type = field.type;

      if (field.isNestedObject) {
        sb.writeln(
          '      $name: json[\'$key\'] != null ? $type.fromJson(json[\'$key\']) : null,',
        );
      } else if (field.isNestedObjectList) {
        final nestedType = field.nestedListType;
        sb.writeln(
          '      $name: json[\'$key\'] != null ? List<$nestedType>.from(json[\'$key\'].map((x) => $nestedType.fromJson(x))) : [],',
        );
      } else if (field.isPrimitiveList) {
        sb.writeln(
          '      $name: json[\'$key\'] != null ? List<${field.primitiveListType}>.from(json[\'$key\']) : [],',
        );
      } else {
        sb.writeln('      $name: json[\'$key\'],');
      }
    }
    sb.writeln('    );');
    sb.writeln('  }');
    sb.writeln();

    // toJson Method
    sb.writeln('  Map<String, dynamic> toJson() {');
    sb.writeln('    return {');
    for (var field in fields) {
      final key = field.originalKey;
      final name = field.fieldName;

      if (field.isNestedObject) {
        sb.writeln('      \'$key\': $name?.toJson(),');
      } else if (field.isNestedObjectList) {
        sb.writeln('      \'$key\': $name.map((x) => x.toJson()).toList(),');
      } else if (field.isPrimitiveList) {
        sb.writeln('      \'$key\': $name,');
      } else {
        sb.writeln('      \'$key\': $name,');
      }
    }
    sb.writeln('    };');
    sb.writeln('  }');

    sb.writeln('}');

    _generatedClasses[className] = sb.toString();
  }

  String _determineFieldType(String key, dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is Map<String, dynamic>) {
      final nestedClassName = _toPascalCase(key);
      _generateClass(nestedClassName, value);
      return nestedClassName;
    }
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final first = value.first;
      if (first is Map<String, dynamic>) {
        final nestedClassName = '${_toPascalCase(key)}Item';
        _generateClass(nestedClassName, first);
        return 'List<$nestedClassName>';
      } else {
        return 'List<${_determineFieldType(key, first)}>';
      }
    }
    return 'dynamic';
  }

  String _toPascalCase(String name) {
    if (name.isEmpty) return 'Model';
    final parts = name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').split('_');
    return parts
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
        .join('');
  }

  String _toCamelCase(String name) {
    if (name.isEmpty) return 'field';
    final pascal = _toPascalCase(name);
    return pascal[0].toLowerCase() + pascal.substring(1);
  }
}

class _DartField {
  final String originalKey;
  final String fieldName;
  final String type;
  final bool isNullable;

  _DartField({
    required this.originalKey,
    required this.fieldName,
    required this.type,
    required this.isNullable,
  });

  bool get isNestedObject {
    return !type.startsWith('List<') &&
        type != 'String' &&
        type != 'int' &&
        type != 'double' &&
        type != 'bool' &&
        type != 'dynamic';
  }

  bool get isNestedObjectList {
    if (!type.startsWith('List<')) return false;
    final insideType = type.substring(5, type.length - 1);
    return insideType != 'String' &&
        insideType != 'int' &&
        insideType != 'double' &&
        insideType != 'bool' &&
        insideType != 'dynamic';
  }

  bool get isPrimitiveList {
    if (!type.startsWith('List<')) return false;
    return !isNestedObjectList;
  }

  String get nestedListType {
    return type.substring(5, type.length - 1);
  }

  String get primitiveListType {
    return type.substring(5, type.length - 1);
  }
}
