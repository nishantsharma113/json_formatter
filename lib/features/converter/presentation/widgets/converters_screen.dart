import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/dart_model_generator.dart';
import '../../../../core/utils/yaml_converter_utils.dart';
import '../../../../core/utils/download_helper.dart';
import '../../../formatter/presentation/providers/json_formatter_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class ConvertersScreen extends ConsumerStatefulWidget {
  const ConvertersScreen({super.key});

  @override
  ConsumerState<ConvertersScreen> createState() => _ConvertersScreenState();
}

class _ConvertersScreenState extends ConsumerState<ConvertersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _classNameController = TextEditingController(
    text: 'RootModel',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _classNameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _classNameController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String format) {
    if (text.isEmpty) {
      _showSnackBar('No content to copy', isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied $format code to clipboard', isError: false);
  }

  void _downloadFile(String text, String filename) {
    if (text.isEmpty) {
      _showSnackBar('No content to download', isError: true);
      return;
    }
    try {
      downloadFile(text, filename);
      _showSnackBar('Downloading $filename...', isError: false);
    } catch (e) {
      _showSnackBar('Download failed: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        width: 320,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final formatterState = ref.watch(jsonFormatterProvider);
    final parsedJson = formatterState.parsedJson;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final codeFont = GoogleFonts.getFont(
      settings.fontFamily,
      fontSize: settings.fontSize,
      height: 1.5,
    );

    String dartCode = '';
    String yamlCode = '';

    if (parsedJson != null) {
      dartCode = DartModelGenerator().generate(
        parsedJson,
        _classNameController.text,
      );
      yamlCode = YamlConverterUtils.convert(parsedJson);
    } else {
      dartCode = '// Please enter valid JSON in the Editor tab first';
      yamlCode = '# Please enter valid JSON in the Editor tab first';
    }

    return Row(
      children: [
        // Left Column (Live JSON input preview)
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkBackground : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightPrimaryContainer.withValues(
                            alpha: 0.5,
                          ),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Original JSON Input',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      formatterState.rawInput.isEmpty
                          ? '{\n  // Enter JSON in the main editor to begin\n}'
                          : formatterState.rawInput,
                      style: codeFont.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: borderColor),
        // Right Column (Dart & YAML Outputs)
        Expanded(
          child: Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Column(
              children: [
                // Converter tabs
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightPrimaryContainer.withValues(
                            alpha: 0.5,
                          ),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    labelColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    unselectedLabelColor: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Dart Model'),
                      Tab(text: 'YAML Converter'),
                    ],
                  ),
                ),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Dart Model Generator Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom class name input
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _classNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Root Class Name',
                                        labelStyle: GoogleFonts.inter(
                                          fontSize: 12,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () =>
                                      _copyToClipboard(dartCode, 'Dart Model'),
                                  tooltip: 'Copy Dart Code',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadFile(
                                    dartCode,
                                    '${_classNameController.text.toLowerCase()}.dart',
                                  ),
                                  tooltip: 'Download Dart File',
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          // Output Dart Code
                          Expanded(
                            child: Container(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Text(dartCode, style: codeFont),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // YAML Converter Tab
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Text(
                                  'YAML Output',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () =>
                                      _copyToClipboard(yamlCode, 'YAML'),
                                  tooltip: 'Copy YAML',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadFile(
                                    yamlCode,
                                    'converted_yaml.yaml',
                                  ),
                                  tooltip: 'Download YAML File',
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          // Output YAML Code
                          Expanded(
                            child: Container(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : Colors.white,
                              padding: const EdgeInsets.all(16),
                              child: SingleChildScrollView(
                                child: Text(yamlCode, style: codeFont),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
