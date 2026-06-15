enum JsonNodeType {
  objectStart,
  objectEnd,
  arrayStart,
  arrayEnd,
  primitive,
}

class JsonTreeNode {
  final String id;
  final String? key;
  final dynamic value;
  final JsonNodeType type;
  final int depth;
  final bool isExpanded;
  final String path;
  final List<JsonTreeNode> children;
  final String? parentId;

  JsonTreeNode({
    required this.id,
    this.key,
    this.value,
    required this.type,
    required this.depth,
    this.isExpanded = false,
    required this.path,
    this.children = const [],
    this.parentId,
  });

  JsonTreeNode copyWith({
    bool? isExpanded,
    List<JsonTreeNode>? children,
  }) {
    return JsonTreeNode(
      id: id,
      key: key,
      value: value,
      type: type,
      depth: depth,
      isExpanded: isExpanded ?? this.isExpanded,
      path: path,
      children: children ?? this.children,
      parentId: parentId,
    );
  }
}
