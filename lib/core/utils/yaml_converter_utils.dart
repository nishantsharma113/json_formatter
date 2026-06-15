class YamlConverterUtils {
  static String convert(dynamic json) {
    if (json == null) return '~';
    // Trim trailing newline for clean display
    return _toYaml(json, 0, false).trimRight();
  }

  static String _toYaml(dynamic node, int indent, bool startSameLine) {
    final prefix = startSameLine ? '' : ' ' * indent;

    if (node is Map) {
      if (node.isEmpty) return startSameLine ? '{}\n' : '$prefix{}\n';
      final sb = StringBuffer();
      var first = true;
      node.forEach((key, value) {
        final currentPrefix = (first && startSameLine) ? '' : ' ' * indent;
        if (value is Map || value is List) {
          sb.writeln('$currentPrefix$key:');
          sb.write(_toYaml(value, indent + 2, false));
        } else {
          sb.writeln('$currentPrefix$key: ${_escape(value)}');
        }
        first = false;
      });
      return sb.toString();
    } else if (node is List) {
      if (node.isEmpty) return startSameLine ? '[]\n' : '$prefix[]\n';
      final sb = StringBuffer();
      var first = true;
      for (var item in node) {
        final currentPrefix = (first && startSameLine) ? '' : ' ' * indent;
        sb.write('$currentPrefix- ');
        // For items in lists, we start on the same line as the dash
        sb.write(_toYaml(item, indent + 2, true));
        first = false;
      }
      return sb.toString();
    } else {
      // Primitive values (string, number, bool, null)
      return startSameLine ? '${_escape(node)}\n' : '$prefix${_escape(node)}\n';
    }
  }

  static String _escape(dynamic value) {
    if (value == null) return '~';
    if (value is String) {
      final specialChars = RegExp(r'[#\?,\-\[\]\{\}\*!&\|>\"&%@`]|\n|:\s');
      if (value.isEmpty) return "''";
      if (specialChars.hasMatch(value) ||
          value.trim() != value ||
          _isNumericOrBoolean(value)) {
        final escaped = value
            .replaceAll('\\', '\\\\')
            .replaceAll('"', '\\"')
            .replaceAll('\n', '\\n');
        return '"$escaped"';
      }
      return value;
    }
    return value.toString();
  }

  static bool _isNumericOrBoolean(String s) {
    if (s == 'true' || s == 'false' || s == 'null') return true;
    return double.tryParse(s) != null;
  }
}
