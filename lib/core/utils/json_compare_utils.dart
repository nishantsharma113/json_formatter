import 'dart:convert';

enum DiffType {
  identical,
  added,
  removed,
  modified,
}

class DiffLine {
  final DiffType type;
  final String text;
  final int? lineNumber;

  DiffLine({
    required this.type,
    required this.text,
    this.lineNumber,
  });
}

class SideBySideDiff {
  final List<DiffLine?> leftLines;
  final List<DiffLine?> rightLines;
  final int addedCount;
  final int removedCount;
  final int modifiedCount;

  SideBySideDiff({
    required this.leftLines,
    required this.rightLines,
    required this.addedCount,
    required this.removedCount,
    required this.modifiedCount,
  });
}

class StructuralDiff {
  int added = 0;
  int removed = 0;
  int modified = 0;

  void compare(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      for (var key in a.keys) {
        if (!b.containsKey(key)) {
          removed++;
        } else {
          final valA = a[key];
          final valB = b[key];
          if (valA.runtimeType != valB.runtimeType) {
            modified++;
          } else if (valA is Map || valA is List) {
            compare(valA, valB);
          } else if (valA != valB) {
            modified++;
          }
        }
      }
      for (var key in b.keys) {
        if (!a.containsKey(key)) {
          added++;
        }
      }
    } else if (a is List && b is List) {
      final minLength = a.length < b.length ? a.length : b.length;
      for (int i = 0; i < minLength; i++) {
        final valA = a[i];
        final valB = b[i];
        if (valA.runtimeType != valB.runtimeType) {
          modified++;
        } else if (valA is Map || valA is List) {
          compare(valA, valB);
        } else if (valA != valB) {
          modified++;
        }
      }
      if (b.length > a.length) {
        added += b.length - a.length;
      } else if (a.length > b.length) {
        removed += a.length - b.length;
      }
    } else {
      if (a != b) {
        modified++;
      }
    }
  }
}

class JsonCompareUtils {
  static SideBySideDiff compare(String textA, String textB) {
    final linesA = textA.split('\n');
    final linesB = textB.split('\n');

    // Structural diff counts
    dynamic jsonA;
    dynamic jsonB;
    try {
      jsonA = json.decode(textA);
    } catch (_) {}
    try {
      jsonB = json.decode(textB);
    } catch (_) {}

    final structural = StructuralDiff();
    if (jsonA != null && jsonB != null) {
      structural.compare(jsonA, jsonB);
    }

    // Now compute aligned lines using LCS
    final lcs = _computeLcs(linesA, linesB);
    
    final leftResult = <DiffLine?>[];
    final rightResult = <DiffLine?>[];
    
    int i = 0;
    int j = 0;
    
    for (var match in lcs) {
      while (i < match.indexA) {
        leftResult.add(DiffLine(type: DiffType.removed, text: linesA[i], lineNumber: i + 1));
        rightResult.add(null);
        i++;
      }
      while (j < match.indexB) {
        leftResult.add(null);
        rightResult.add(DiffLine(type: DiffType.added, text: linesB[j], lineNumber: j + 1));
        j++;
      }
      leftResult.add(DiffLine(type: DiffType.identical, text: linesA[i], lineNumber: i + 1));
      rightResult.add(DiffLine(type: DiffType.identical, text: linesB[j], lineNumber: j + 1));
      i++;
      j++;
    }
    
    while (i < linesA.length) {
      leftResult.add(DiffLine(type: DiffType.removed, text: linesA[i], lineNumber: i + 1));
      rightResult.add(null);
      i++;
    }
    
    while (j < linesB.length) {
      leftResult.add(null);
      rightResult.add(DiffLine(type: DiffType.added, text: linesB[j], lineNumber: j + 1));
      j++;
    }

    int addedCount = structural.added;
    int removedCount = structural.removed;
    int modifiedCount = structural.modified;

    // Fall back to text-based diff metrics if JSON parsing failed
    if (jsonA == null || jsonB == null) {
      addedCount = 0;
      removedCount = 0;
      modifiedCount = 0;
      for (var line in rightResult) {
        if (line != null && line.type == DiffType.added) addedCount++;
      }
      for (var line in leftResult) {
        if (line != null && line.type == DiffType.removed) removedCount++;
      }
    }

    // Attempt to pair adjacent added/removed lines as "modified" for better UX
    for (int idx = 0; idx < leftResult.length; idx++) {
      final left = leftResult[idx];
      final right = rightResult[idx];
      if (left != null && left.type == DiffType.removed && right == null && idx + 1 < leftResult.length) {
        final nextRight = rightResult[idx + 1];
        final nextLeft = leftResult[idx + 1];
        if (nextRight != null && nextRight.type == DiffType.added && nextLeft == null) {
          // Merge them!
          leftResult[idx] = DiffLine(type: DiffType.modified, text: left.text, lineNumber: left.lineNumber);
          rightResult[idx] = DiffLine(type: DiffType.modified, text: nextRight.text, lineNumber: nextRight.lineNumber);
          // Remove the next element which has been merged
          leftResult.removeAt(idx + 1);
          rightResult.removeAt(idx + 1);
        }
      }
    }

    return SideBySideDiff(
      leftLines: leftResult,
      rightLines: rightResult,
      addedCount: addedCount,
      removedCount: removedCount,
      modifiedCount: modifiedCount,
    );
  }

  static List<_LcsMatch> _computeLcs(List<String> a, List<String> b) {
    final n = a.length;
    final m = b.length;
    
    if (n > 1000 || m > 1000) {
      return _computeHeuristicLcs(a, b);
    }

    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (a[i - 1].trim() == b[j - 1].trim()) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }
    
    final matches = <_LcsMatch>[];
    int i = n, j = m;
    while (i > 0 && j > 0) {
      if (a[i - 1].trim() == b[j - 1].trim()) {
        matches.add(_LcsMatch(i - 1, j - 1));
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    
    return matches.reversed.toList();
  }

  static List<_LcsMatch> _computeHeuristicLcs(List<String> a, List<String> b) {
    final bMap = <String, List<int>>{};
    for (int j = 0; j < b.length; j++) {
      final key = b[j].trim();
      bMap.putIfAbsent(key, () => []).add(j);
    }

    final matches = <_LcsMatch>[];
    int lastBIndex = -1;

    for (int i = 0; i < a.length; i++) {
      final key = a[i].trim();
      if (bMap.containsKey(key)) {
        final indices = bMap[key]!;
        int matchIndex = -1;
        for (var idx in indices) {
          if (idx > lastBIndex) {
            matchIndex = idx;
            break;
          }
        }
        if (matchIndex != -1) {
          matches.add(_LcsMatch(i, matchIndex));
          lastBIndex = matchIndex;
        }
      }
    }
    return matches;
  }
}

class _LcsMatch {
  final int indexA;
  final int indexB;
  _LcsMatch(this.indexA, this.indexB);
}
