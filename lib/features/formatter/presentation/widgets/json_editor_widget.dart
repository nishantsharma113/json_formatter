// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/download_helper.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/json_formatter_provider.dart';

class JsonHighlightController extends TextEditingController {
  final bool isDark;
  final bool enableHighlight;

  JsonHighlightController({
    required this.isDark,
    required this.enableHighlight,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!enableHighlight || text.length > 80000) {
      // Fallback for large files (>80KB) to ensure flawless scrolling and typing performance
      return TextSpan(text: text, style: style);
    }

    final List<TextSpan> children = [];
    final regExp = RegExp(
      r'("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"\s*:)|'
      r'("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*")|'
      r'(\b-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?\b)|'
      r'(\b(true|false)\b)|'
      r'(\bnull\b)|'
      r'([\{\}\[\]])',
      multiLine: true,
    );

    int lastMatchEnd = 0;

    final keyColor = isDark
        ? AppColors.syntaxKeyDark
        : AppColors.syntaxKeyLight;
    final stringColor = isDark
        ? AppColors.syntaxStringDark
        : AppColors.syntaxStringLight;
    final numberColor = isDark
        ? AppColors.syntaxNumberDark
        : AppColors.syntaxNumberLight;
    final boolColor = isDark
        ? AppColors.syntaxBoolDark
        : AppColors.syntaxBoolLight;
    final nullColor = isDark
        ? AppColors.syntaxNullDark
        : AppColors.syntaxNullLight;
    final bracketColor = isDark
        ? AppColors.syntaxBracketDark
        : AppColors.syntaxBracketLight;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        children.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }

      final matchText = match.group(0)!;

      if (match.group(1) != null) {
        final colonIndex = matchText.lastIndexOf(':');
        if (colonIndex != -1) {
          children.add(
            TextSpan(
              text: matchText.substring(0, colonIndex),
              style: style?.copyWith(
                color: keyColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
          children.add(
            TextSpan(
              text: matchText.substring(colonIndex),
              style: style?.copyWith(color: bracketColor),
            ),
          );
        } else {
          children.add(
            TextSpan(
              text: matchText,
              style: style?.copyWith(
                color: keyColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
      } else if (match.group(3) != null) {
        children.add(
          TextSpan(
            text: matchText,
            style: style?.copyWith(color: stringColor),
          ),
        );
      } else if (match.group(5) != null) {
        children.add(
          TextSpan(
            text: matchText,
            style: style?.copyWith(color: numberColor),
          ),
        );
      } else if (match.group(6) != null) {
        children.add(
          TextSpan(
            text: matchText,
            style: style?.copyWith(
              color: boolColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (match.group(8) != null) {
        children.add(
          TextSpan(
            text: matchText,
            style: style?.copyWith(
              color: nullColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else if (match.group(9) != null) {
        children.add(
          TextSpan(
            text: matchText,
            style: style?.copyWith(color: bracketColor),
          ),
        );
      } else {
        children.add(TextSpan(text: matchText, style: style));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return TextSpan(children: children, style: style);
  }
}

class JsonEditorWidget extends ConsumerStatefulWidget {
  final bool isReadOnly;
  final String title;

  const JsonEditorWidget({
    super.key,
    this.isReadOnly = false,
    required this.title,
  });

  @override
  ConsumerState<JsonEditorWidget> createState() => _JsonEditorWidgetState();
}

class _JsonEditorWidgetState extends ConsumerState<JsonEditorWidget> {
  late JsonHighlightController _controller;
  late ScrollController _textScrollController;
  late ScrollController _lineScrollController;
  late FocusNode _focusNode;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  List<int> _searchIndices = [];
  int _currentSearchMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _textScrollController = ScrollController();
    _lineScrollController = ScrollController();
    _focusNode = FocusNode();

    _textScrollController.addListener(() {
      if (_lineScrollController.hasClients) {
        _lineScrollController.jumpTo(_textScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textScrollController.dispose();
    _lineScrollController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchIndices = [];
        _currentSearchMatchIndex = -1;
      });
      return;
    }

    final text = _controller.text;
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();

    final indices = <int>[];
    int index = lowercaseText.indexOf(lowercaseQuery);
    while (index != -1) {
      indices.add(index);
      index = lowercaseText.indexOf(lowercaseQuery, index + query.length);
    }

    setState(() {
      _searchIndices = indices;
      _currentSearchMatchIndex = indices.isNotEmpty ? 0 : -1;
    });

    if (indices.isNotEmpty) {
      _selectAndScrollToMatch(indices[0], query.length);
    }
  }

  void _selectAndScrollToMatch(int start, int length) {
    _controller.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + length,
    );
    _focusNode.requestFocus();
  }

  void _nextSearchMatch() {
    if (_searchIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex =
          (_currentSearchMatchIndex + 1) % _searchIndices.length;
    });
    _selectAndScrollToMatch(
      _searchIndices[_currentSearchMatchIndex],
      _searchController.text.length,
    );
  }

  void _prevSearchMatch() {
    if (_searchIndices.isEmpty) return;
    setState(() {
      _currentSearchMatchIndex =
          (_currentSearchMatchIndex - 1 + _searchIndices.length) %
          _searchIndices.length;
    });
    _selectAndScrollToMatch(
      _searchIndices[_currentSearchMatchIndex],
      _searchController.text.length,
    );
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );
      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        ref.read(jsonFormatterProvider.notifier).setInputAndFormat(content);
        _showSnackBar('File uploaded successfully', isError: false);
      }
    } catch (e) {
      _showSnackBar('Failed to read file: $e', isError: true);
    }
  }

  void _downloadFile() {
    final text = _controller.text;
    if (text.isEmpty) {
      _showSnackBar('No content to download', isError: true);
      return;
    }

    try {
      final isMinified = text.trim().startsWith('{') && !text.contains('\n');
      final filename = isMinified ? 'minified_json.json' : 'formatted_json.json';
      
      downloadFile(text, filename);
      _showSnackBar('Downloading file...', isError: false);
    } catch (e) {
      _showSnackBar('Download failed: $e', isError: true);
    }
  }

  void _copyToClipboard() {
    final text = _controller.text;
    if (text.isEmpty) {
      _showSnackBar('No content to copy', isError: true);
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard', isError: false);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      ref.read(jsonFormatterProvider.notifier).setInputAndFormat(data!.text!);
      _showSnackBar('Pasted from clipboard', isError: false);
    } else {
      _showSnackBar('Clipboard is empty', isError: true);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _controller = JsonHighlightController(
      isDark: isDark,
      enableHighlight: true,
    );

    // Synchronize state changes into controller text
    final stateText = widget.isReadOnly
        ? formatterState.formattedOutput
        : formatterState.rawInput;
    if (_controller.text != stateText) {
      final oldSelection = _controller.selection;
      _controller.text = stateText;
      if (oldSelection.isValid && oldSelection.end <= stateText.length) {
        _controller.selection = oldSelection;
      }
    }

    final int lineCount = '\n'.allMatches(_controller.text).length + 1;
    final codeFont = GoogleFonts.getFont(
      settings.fontFamily,
      fontSize: settings.fontSize,
      height: 1.5,
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!widget.isReadOnly) {
            ref.read(jsonFormatterProvider.notifier).format();
            _showSnackBar('Formatted JSON', isError: false);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
          _copyToClipboard();
        },
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {
          if (!widget.isReadOnly) {
            _pasteFromClipboard();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          _downloadFile();
        },
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () {
          if (!widget.isReadOnly) {
            ref.read(jsonFormatterProvider.notifier).clear();
            _showSnackBar('Cleared Editor', isError: false);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          setState(() {
            _isSearchOpen = !_isSearchOpen;
            if (!_isSearchOpen) {
              _searchController.clear();
              _onSearchChanged('');
            }
          });
        },
      },
      child: Column(
        children: [
          // Toolbar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightPrimaryContainer.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!widget.isReadOnly) ...[
                          IconButton(
                            icon: const Icon(Icons.paste, size: 18),
                            tooltip: 'Paste JSON (Ctrl+V)',
                            onPressed: _pasteFromClipboard,
                          ),
                          IconButton(
                            icon: const Icon(Icons.upload_file, size: 18),
                            tooltip: 'Upload File (.json, .txt)',
                            onPressed: _uploadFile,
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy JSON (Ctrl+C)',
                          onPressed: _copyToClipboard,
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, size: 18),
                          tooltip: 'Download JSON (Ctrl+S)',
                          onPressed: _downloadFile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, size: 18),
                          tooltip: 'Find Text (Ctrl+F)',
                          onPressed: () {
                            setState(() {
                              _isSearchOpen = !_isSearchOpen;
                              if (!_isSearchOpen) {
                                _searchController.clear();
                                _onSearchChanged('');
                              }
                            });
                          },
                        ),
                        if (!widget.isReadOnly)
                          IconButton(
                            icon: const Icon(Icons.clear_all, size: 18),
                            tooltip: 'Clear Editor (Ctrl+L)',
                            onPressed: () {
                              ref.read(jsonFormatterProvider.notifier).clear();
                              _showSnackBar('Cleared Editor', isError: false);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search box overlay
          if (_isSearchOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: GoogleFonts.inter(fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkBackground
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _searchIndices.isEmpty
                        ? 'No matches'
                        : '${_currentSearchMatchIndex + 1} of ${_searchIndices.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 16),
                    onPressed: _prevSearchMatch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    onPressed: _nextSearchMatch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      setState(() {
                        _isSearchOpen = false;
                        _searchController.clear();
                        _onSearchChanged('');
                      });
                    },
                  ),
                ],
              ),
            ),

          // Main Input Editor Panel
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Line Numbers Sidebar
                if (settings.showLineNumbers)
                  Container(
                    width: 45,
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1222)
                          : const Color(0xFFF1F5F9),
                      border: Border(
                        right: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      controller: _lineScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lineCount,
                      itemBuilder: (context, index) {
                        return Container(
                          height: settings.fontSize * 1.5,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.getFont(
                              settings.fontFamily,
                              fontSize: settings.fontSize - 1,
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Actual Editing Space
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 8,
                      top: 12,
                      bottom: 12,
                    ),
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      scrollController: _textScrollController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      readOnly: widget.isReadOnly,
                      onChanged: (val) {
                        if (!widget.isReadOnly) {
                          ref
                              .read(jsonFormatterProvider.notifier)
                              .updateInput(val);
                        }
                      },
                      style: codeFont,
                      strutStyle: StrutStyle(
                        fontFamily: settings.fontFamily,
                        fontSize: settings.fontSize,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
