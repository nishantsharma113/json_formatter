import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/json_tree_node.dart';
import '../../../formatter/presentation/providers/json_formatter_provider.dart';

class JsonTreeViewState {
  final JsonTreeNode? rootNode;
  final Map<String, bool> expansionStates;
  final String searchQuery;
  final List<String> searchResults;
  final int currentSearchResultIndex;
  final List<JsonTreeNode> flatVisibleNodes;

  JsonTreeViewState({
    this.rootNode,
    required this.expansionStates,
    required this.searchQuery,
    required this.searchResults,
    required this.currentSearchResultIndex,
    required this.flatVisibleNodes,
  });

  factory JsonTreeViewState.initial() {
    return JsonTreeViewState(
      rootNode: null,
      expansionStates: const {},
      searchQuery: '',
      searchResults: const [],
      currentSearchResultIndex: -1,
      flatVisibleNodes: const [],
    );
  }

  JsonTreeViewState copyWith({
    JsonTreeNode? rootNode,
    Map<String, bool>? expansionStates,
    String? searchQuery,
    List<String>? searchResults,
    int? currentSearchResultIndex,
    List<JsonTreeNode>? flatVisibleNodes,
  }) {
    return JsonTreeViewState(
      rootNode: rootNode ?? this.rootNode,
      expansionStates: expansionStates ?? this.expansionStates,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      currentSearchResultIndex:
          currentSearchResultIndex ?? this.currentSearchResultIndex,
      flatVisibleNodes: flatVisibleNodes ?? this.flatVisibleNodes,
    );
  }
}

class JsonTreeViewNotifier extends Notifier<JsonTreeViewState> {
  @override
  JsonTreeViewState build() {
    final parsedJson = ref.watch(
      jsonFormatterProvider.select((s) => s.parsedJson),
    );
    if (parsedJson == null) {
      return JsonTreeViewState.initial();
    }

    final root = _buildTree(parsedJson, 'root', '', 0, null);

    // Default expansion: Expand the root node
    final expansionStates = <String, bool>{root.id: true};

    final flatVisible = _flattenVisible(root, expansionStates);

    return JsonTreeViewState(
      rootNode: root,
      expansionStates: expansionStates,
      searchQuery: '',
      searchResults: const [],
      currentSearchResultIndex: -1,
      flatVisibleNodes: flatVisible,
    );
  }

  JsonTreeNode _buildTree(
    dynamic json,
    String key,
    String path,
    int depth,
    String? parentId,
  ) {
    final String id = parentId == null ? 'root' : '$parentId/$key';

    if (json is Map) {
      final children = <JsonTreeNode>[];
      json.forEach((k, v) {
        final subPath = path.isEmpty ? k : '$path.$k';
        children.add(_buildTree(v, k, subPath, depth + 1, id));
      });
      return JsonTreeNode(
        id: id,
        key: key == 'root' ? null : key,
        type: JsonNodeType.objectStart,
        depth: depth,
        path: path,
        children: children,
        parentId: parentId,
      );
    } else if (json is List) {
      final children = <JsonTreeNode>[];
      for (int i = 0; i < json.length; i++) {
        final subPath = '$path[$i]';
        children.add(_buildTree(json[i], '[$i]', subPath, depth + 1, id));
      }
      return JsonTreeNode(
        id: id,
        key: key == 'root' ? null : key,
        type: JsonNodeType.arrayStart,
        depth: depth,
        path: path,
        children: children,
        parentId: parentId,
      );
    } else {
      return JsonTreeNode(
        id: id,
        key: key == 'root' ? null : key,
        value: json,
        type: JsonNodeType.primitive,
        depth: depth,
        path: path,
        parentId: parentId,
      );
    }
  }

  List<JsonTreeNode> _flattenVisible(
    JsonTreeNode node,
    Map<String, bool> expansionStates,
  ) {
    final list = <JsonTreeNode>[];
    final isExpanded = expansionStates[node.id] ?? false;

    list.add(node);

    if (node.type == JsonNodeType.primitive) {
      return list;
    }

    if (isExpanded) {
      for (var child in node.children) {
        list.addAll(_flattenVisible(child, expansionStates));
      }
      list.add(
        JsonTreeNode(
          id: '${node.id}_end',
          key: null,
          type: node.type == JsonNodeType.objectStart
              ? JsonNodeType.objectEnd
              : JsonNodeType.arrayEnd,
          depth: node.depth,
          path: node.path,
          parentId: node.id,
        ),
      );
    }

    return list;
  }

  void toggleExpand(String nodeId) {
    if (state.rootNode == null) return;
    final current = state.expansionStates[nodeId] ?? false;
    final updatedStates = Map<String, bool>.from(state.expansionStates);
    updatedStates[nodeId] = !current;

    final flatVisible = _flattenVisible(state.rootNode!, updatedStates);
    state = state.copyWith(
      expansionStates: updatedStates,
      flatVisibleNodes: flatVisible,
    );
  }

  void expandAll() {
    if (state.rootNode == null) return;
    final updatedStates = <String, bool>{};
    _setAllExpanded(state.rootNode!, updatedStates, true);

    final flatVisible = _flattenVisible(state.rootNode!, updatedStates);
    state = state.copyWith(
      expansionStates: updatedStates,
      flatVisibleNodes: flatVisible,
    );
  }

  void _setAllExpanded(
    JsonTreeNode node,
    Map<String, bool> states,
    bool expand,
  ) {
    if (node.type != JsonNodeType.primitive) {
      states[node.id] = expand;
      for (var child in node.children) {
        _setAllExpanded(child, states, expand);
      }
    }
  }

  void collapseAll() {
    if (state.rootNode == null) return;
    final updatedStates = <String, bool>{
      state.rootNode!.id: true, // Keep root expanded
    };

    final flatVisible = _flattenVisible(state.rootNode!, updatedStates);
    state = state.copyWith(
      expansionStates: updatedStates,
      flatVisibleNodes: flatVisible,
    );
  }

  void setSearchQuery(String query) {
    if (state.rootNode == null) return;
    if (query.trim().isEmpty) {
      state = state.copyWith(
        searchQuery: '',
        searchResults: const [],
        currentSearchResultIndex: -1,
      );
      return;
    }

    final searchResults = <String>[];
    _findMatches(state.rootNode!, query.toLowerCase(), searchResults);

    if (searchResults.isEmpty) {
      state = state.copyWith(
        searchQuery: query,
        searchResults: const [],
        currentSearchResultIndex: -1,
      );
      return;
    }

    // Auto expand parent nodes of all matches
    final updatedStates = Map<String, bool>.from(state.expansionStates);
    for (var id in searchResults) {
      _expandParentPaths(id, updatedStates);
    }

    final flatVisible = _flattenVisible(state.rootNode!, updatedStates);

    state = state.copyWith(
      searchQuery: query,
      searchResults: searchResults,
      currentSearchResultIndex: 0,
      expansionStates: updatedStates,
      flatVisibleNodes: flatVisible,
    );
  }

  void _findMatches(JsonTreeNode node, String query, List<String> results) {
    final keyMatch = node.key?.toLowerCase().contains(query) ?? false;
    final valueMatch =
        node.value?.toString().toLowerCase().contains(query) ?? false;
    if (keyMatch || valueMatch) {
      results.add(node.id);
    }
    for (var child in node.children) {
      _findMatches(child, query, results);
    }
  }

  void _expandParentPaths(String id, Map<String, bool> states) {
    final parts = id.split('/');
    if (parts.length <= 1) return;
    String currentPath = parts.first;
    for (int i = 1; i < parts.length; i++) {
      states[currentPath] = true;
      currentPath += '/${parts[i]}';
    }
  }

  void nextSearchMatch() {
    if (state.searchResults.isEmpty) return;
    final nextIndex =
        (state.currentSearchResultIndex + 1) % state.searchResults.length;
    state = state.copyWith(currentSearchResultIndex: nextIndex);
  }

  void prevSearchMatch() {
    if (state.searchResults.isEmpty) return;
    final prevIndex =
        (state.currentSearchResultIndex - 1 + state.searchResults.length) %
        state.searchResults.length;
    state = state.copyWith(currentSearchResultIndex: prevIndex);
  }
}

final jsonTreeViewProvider =
    NotifierProvider<JsonTreeViewNotifier, JsonTreeViewState>(() {
      return JsonTreeViewNotifier();
    });
