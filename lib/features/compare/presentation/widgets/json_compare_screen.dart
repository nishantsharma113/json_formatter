import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/json_compare_provider.dart';
import '../../../../core/utils/json_compare_utils.dart';

class JsonCompareScreen extends ConsumerStatefulWidget {
  const JsonCompareScreen({super.key});

  @override
  ConsumerState<JsonCompareScreen> createState() => _JsonCompareScreenState();
}

class _JsonCompareScreenState extends ConsumerState<JsonCompareScreen> {
  late ScrollController _leftScrollController;
  late ScrollController _rightScrollController;
  late ScrollController _leftHeaderScrollController;
  late ScrollController _rightHeaderScrollController;

  late TextEditingController _controllerA;
  late TextEditingController _controllerB;

  bool _isSyncingLeft = false;
  bool _isSyncingRight = false;
  bool _isDiffMode = false;

  @override
  void initState() {
    super.initState();
    _leftScrollController = ScrollController();
    _rightScrollController = ScrollController();
    _leftHeaderScrollController = ScrollController();
    _rightHeaderScrollController = ScrollController();

    _controllerA = TextEditingController();
    _controllerB = TextEditingController();

    // Coordinate vertical scroll offsets
    _leftScrollController.addListener(() {
      if (_isSyncingRight) return;
      _isSyncingLeft = true;
      if (_rightScrollController.hasClients) {
        _rightScrollController.jumpTo(_leftScrollController.offset);
      }
      _isSyncingLeft = false;
    });

    _rightScrollController.addListener(() {
      if (_isSyncingLeft) return;
      _isSyncingRight = true;
      if (_leftScrollController.hasClients) {
        _leftScrollController.jumpTo(_rightScrollController.offset);
      }
      _isSyncingRight = false;
    });
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _leftHeaderScrollController.dispose();
    _rightHeaderScrollController.dispose();
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  void _loadDemoData() {
    const jsonA = '''{
  "name": "JSON Formatter Pro",
  "version": 1.0,
  "features": ["validation", "formatting", "compare"],
  "settings": {
    "theme": "light",
    "fontSize": 14
  }
}''';

    const jsonB = '''{
  "name": "JSON Formatter Pro",
  "version": 1.1,
  "features": ["validation", "formatting", "compare", "conversion"],
  "settings": {
    "theme": "dark",
    "fontSize": 14,
    "wordWrap": true
  },
  "isActive": true
}''';

    setState(() {
      _controllerA.text = jsonA;
      _controllerB.text = jsonB;
      _isDiffMode = true;
    });

    ref.read(jsonCompareProvider.notifier).updateJsonA(jsonA);
    ref.read(jsonCompareProvider.notifier).updateJsonB(jsonB);
  }

  void _clear() {
    setState(() {
      _controllerA.clear();
      _controllerB.clear();
      _isDiffMode = false;
    });
    ref.read(jsonCompareProvider.notifier).clear();
  }

  Future<void> _pickFile(bool isLeft) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );
      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        if (isLeft) {
          _controllerA.text = content;
          ref.read(jsonCompareProvider.notifier).updateJsonA(content);
        } else {
          _controllerB.text = content;
          ref.read(jsonCompareProvider.notifier).updateJsonB(content);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to read file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final compareState = ref.watch(jsonCompareProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final rowHeight = settings.fontSize * 1.5;

    return Column(
      children: [
        // Comparison toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : AppColors.lightPrimaryContainer.withValues(alpha: 0.5),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Text(
                'JSON Compare',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              if (_isDiffMode && compareState.diffResult != null) ...[
                _buildDiffBadge(
                  label: 'Added: ${compareState.diffResult!.addedCount}',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _buildDiffBadge(
                  label: 'Removed: ${compareState.diffResult!.removedCount}',
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                _buildDiffBadge(
                  label: 'Modified: ${compareState.diffResult!.modifiedCount}',
                  color: AppColors.warning,
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                icon: Icon(_isDiffMode ? Icons.edit : Icons.compare, size: 16),
                label: Text(_isDiffMode ? 'Edit JSON' : 'Compare'),
                onPressed: () {
                  setState(() {
                    _isDiffMode = !_isDiffMode;
                  });
                  if (_isDiffMode) {
                    ref
                        .read(jsonCompareProvider.notifier)
                        .updateJsonA(_controllerA.text);
                    ref
                        .read(jsonCompareProvider.notifier)
                        .updateJsonB(_controllerB.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
                onPressed: _clear,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.palette, size: 16),
                label: const Text('Load Demo'),
                onPressed: _loadDemoData,
              ),
            ],
          ),
        ),

        // Editor / Diff Split Pane
        Expanded(
          child: _isDiffMode
              ? _buildDiffView(
                  compareState.diffResult,
                  settings,
                  isDark,
                  rowHeight,
                )
              : _buildEditView(isDark, borderColor),
        ),
      ],
    );
  }

  Widget _buildDiffBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildEditView(bool isDark, Color borderColor) {
    final hintStyle = GoogleFonts.inter(
      color: isDark ? Colors.white30 : Colors.black38,
      fontSize: 13,
    );
    final textStyle = GoogleFonts.getFont('JetBrains Mono', fontSize: 13);

    return Row(
      children: [
        // JSON A Panel
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    Text(
                      'JSON A (Original)',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.upload_file, size: 16),
                      onPressed: () => _pickFile(true),
                      tooltip: 'Upload JSON A',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  child: TextField(
                    controller: _controllerA,
                    maxLines: null,
                    style: textStyle,
                    decoration: InputDecoration(
                      hintText: 'Paste original JSON here...',
                      hintStyle: hintStyle,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: borderColor),
        // JSON B Panel
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                child: Row(
                  children: [
                    Text(
                      'JSON B (Modified)',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.upload_file, size: 16),
                      onPressed: () => _pickFile(false),
                      tooltip: 'Upload JSON B',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  child: TextField(
                    controller: _controllerB,
                    maxLines: null,
                    style: textStyle,
                    decoration: InputDecoration(
                      hintText: 'Paste modified JSON here...',
                      hintStyle: hintStyle,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiffView(
    SideBySideDiff? diff,
    dynamic settings,
    bool isDark,
    double rowHeight,
  ) {
    if (diff == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final codeFont = GoogleFonts.getFont(
      settings.fontFamily,
      fontSize: settings.fontSize,
      height: 1.5,
    );

    final greenBg = Colors.green.withValues(alpha: isDark ? 0.2 : 0.15);
    final redBg = Colors.red.withValues(alpha: isDark ? 0.2 : 0.15);
    final orangeBg = Colors.orange.withValues(alpha: isDark ? 0.2 : 0.15);

    return Row(
      children: [
        // Left Column (JSON A)
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkBackground : Colors.white,
            child: ListView.builder(
              controller: _leftScrollController,
              itemCount: diff.leftLines.length,
              itemExtent: rowHeight,
              itemBuilder: (context, idx) {
                final line = diff.leftLines[idx];
                Color? bgColor;
                if (line != null) {
                  if (line.type == DiffType.removed) bgColor = redBg;
                  if (line.type == DiffType.modified) bgColor = orangeBg;
                }
                return Container(
                  height: rowHeight,
                  color: bgColor ?? Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line?.text ?? '',
                    style: codeFont.copyWith(
                      color: line != null && line.type == DiffType.removed
                          ? AppColors.error
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        // Right Column (JSON B)
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkBackground : Colors.white,
            child: ListView.builder(
              controller: _rightScrollController,
              itemCount: diff.rightLines.length,
              itemExtent: rowHeight,
              itemBuilder: (context, idx) {
                final line = diff.rightLines[idx];
                Color? bgColor;
                if (line != null) {
                  if (line.type == DiffType.added) bgColor = greenBg;
                  if (line.type == DiffType.modified) bgColor = orangeBg;
                }
                return Container(
                  height: rowHeight,
                  color: bgColor ?? Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    line?.text ?? '',
                    style: codeFont.copyWith(
                      color: line != null && line.type == DiffType.added
                          ? AppColors.success
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
