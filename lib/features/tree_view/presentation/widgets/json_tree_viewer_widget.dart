import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/json_tree_node.dart';
import '../providers/json_tree_view_provider.dart';

class JsonTreeViewerWidget extends ConsumerStatefulWidget {
  const JsonTreeViewerWidget({super.key});

  @override
  ConsumerState<JsonTreeViewerWidget> createState() =>
      _JsonTreeViewerWidgetState();
}

class _JsonTreeViewerWidgetState extends ConsumerState<JsonTreeViewerWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  static const double _rowHeight = 28.0;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMatch(
    List<JsonTreeNode> visibleNodes,
    String? currentMatchId,
  ) {
    if (currentMatchId == null || visibleNodes.isEmpty) return;
    final index = visibleNodes.indexWhere((node) => node.id == currentMatchId);
    if (index != -1 && _scrollController.hasClients) {
      final targetOffset = index * _rowHeight;
      // Clamp target offset to scroll limits
      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(0.0, maxScroll);
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final treeState = ref.watch(jsonTreeViewProvider);
    final notifier = ref.read(jsonTreeViewProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String? currentMatchId =
        treeState.searchResults.isNotEmpty &&
            treeState.currentSearchResultIndex != -1
        ? treeState.searchResults[treeState.currentSearchResultIndex]
        : null;

    // Listen to changes in search match index to scroll to it
    ref.listen(jsonTreeViewProvider.select((s) => s.currentSearchResultIndex), (
      prev,
      next,
    ) {
      if (next != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentMatch(treeState.flatVisibleNodes, currentMatchId);
        });
      }
    });

    final toolbarColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightPrimaryContainer.withValues(alpha: 0.5);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final rowStyle = GoogleFonts.getFont(
      settings.fontFamily,
      fontSize: settings.fontSize,
    );

    return Column(
      children: [
        // Action toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: toolbarColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Text(
                'Tree View',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.unfold_more, size: 16),
                label: const Text('Expand All', style: TextStyle(fontSize: 12)),
                onPressed: () => notifier.expandAll(),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.unfold_less, size: 16),
                label: const Text(
                  'Collapse All',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => notifier.collapseAll(),
              ),
            ],
          ),
        ),

        // Search Panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D31) : const Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search keys or values...',
                      hintStyle: GoogleFonts.inter(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 16),
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
              if (treeState.searchResults.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '${treeState.currentSearchResultIndex + 1} of ${treeState.searchResults.length}',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  onPressed: () => notifier.prevSearchMatch(),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: () => notifier.nextSearchMatch(),
                ),
              ],
            ],
          ),
        ),

        // Virtualized Tree List
        Expanded(
          child: treeState.rootNode == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_tree_outlined,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Empty or Invalid JSON for Tree View',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  child: SelectionArea(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemExtent: _rowHeight,
                      itemCount: treeState.flatVisibleNodes.length,
                      itemBuilder: (context, index) {
                        final node = treeState.flatVisibleNodes[index];
                        final isSelected = node.id == currentMatchId;
                        final isExpanded =
                            treeState.expansionStates[node.id] ?? false;

                        return GestureDetector(
                          onTap: () {
                            if (node.type == JsonNodeType.objectStart ||
                                node.type == JsonNodeType.arrayStart) {
                              notifier.toggleExpand(node.id);
                            }
                          },
                          child: Container(
                            height: _rowHeight,
                            color: isSelected
                                ? (isDark
                                      ? AppColors.darkPrimary.withValues(
                                          alpha: 0.25,
                                        )
                                      : AppColors.lightPrimary.withValues(
                                          alpha: 0.2,
                                        ))
                                : Colors.transparent,
                            padding: EdgeInsets.only(
                              left: 12.0 + (node.depth * 20.0),
                            ),
                            child: Row(
                              children: [
                                _buildLeadingIcon(node, isExpanded, isDark),
                                Expanded(
                                  child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: rowStyle,
                                      children: _buildRowSpans(node, isDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLeadingIcon(JsonTreeNode node, bool isExpanded, bool isDark) {
    if (node.type == JsonNodeType.objectStart ||
        node.type == JsonNodeType.arrayStart) {
      return Container(
        margin: const EdgeInsets.only(right: 4),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
          size: 16,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      );
    }
    // Indent indent-only nodes (end brackets, primitive nodes without icons) to align correctly
    return const SizedBox(width: 20);
  }

  List<TextSpan> _buildRowSpans(JsonTreeNode node, bool isDark) {
    final spans = <TextSpan>[];

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

    // Render key if it exists
    if (node.key != null) {
      spans.add(
        TextSpan(
          text: '"${node.key}"',
          style: TextStyle(color: keyColor, fontWeight: FontWeight.bold),
        ),
      );
      spans.add(
        TextSpan(
          text: ': ',
          style: TextStyle(color: bracketColor),
        ),
      );
    }

    // Render body based on type
    switch (node.type) {
      case JsonNodeType.objectStart:
        spans.add(
          TextSpan(
            text: '{',
            style: TextStyle(color: bracketColor),
          ),
        );
        // Show item count for collapsed collections
        final isExpanded =
            ref.read(jsonTreeViewProvider).expansionStates[node.id] ?? false;
        if (!isExpanded) {
          spans.add(
            TextSpan(
              text: ' ... }',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        break;
      case JsonNodeType.objectEnd:
        spans.add(
          TextSpan(
            text: '}',
            style: TextStyle(color: bracketColor),
          ),
        );
        break;
      case JsonNodeType.arrayStart:
        spans.add(
          TextSpan(
            text: '[',
            style: TextStyle(color: bracketColor),
          ),
        );
        final isExpanded =
            ref.read(jsonTreeViewProvider).expansionStates[node.id] ?? false;
        if (!isExpanded) {
          spans.add(
            TextSpan(
              text: ' ... ]',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        break;
      case JsonNodeType.arrayEnd:
        spans.add(
          TextSpan(
            text: ']',
            style: TextStyle(color: bracketColor),
          ),
        );
        break;
      case JsonNodeType.primitive:
        final val = node.value;
        if (val == null) {
          spans.add(
            TextSpan(
              text: 'null',
              style: TextStyle(color: nullColor, fontStyle: FontStyle.italic),
            ),
          );
        } else if (val is String) {
          spans.add(
            TextSpan(
              text: '"$val"',
              style: TextStyle(color: stringColor),
            ),
          );
        } else if (val is num) {
          spans.add(
            TextSpan(
              text: '$val',
              style: TextStyle(color: numberColor),
            ),
          );
        } else if (val is bool) {
          spans.add(
            TextSpan(
              text: '$val',
              style: TextStyle(color: boolColor, fontWeight: FontWeight.bold),
            ),
          );
        } else {
          spans.add(TextSpan(text: '$val'));
        }
        break;
    }

    return spans;
  }
}
