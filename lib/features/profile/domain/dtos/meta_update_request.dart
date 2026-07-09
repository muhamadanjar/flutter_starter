sealed class MetaUpdateRequest {
  const MetaUpdateRequest();

  /// Single returns a Map, bulk returns a List — the API accepts both shapes.
  dynamic toJson();
}

/// Single metadata update
final class SingleMetaUpdate extends MetaUpdateRequest {
  final String key;
  final String value;

  const SingleMetaUpdate({
    required this.key,
    required this.value,
  });

  @override
  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };
}

/// Bulk metadata updates
final class BulkMetaUpdate extends MetaUpdateRequest {
  final List<MetaItem> items;

  const BulkMetaUpdate({required this.items});

  @override
  List<Map<String, dynamic>> toJson() => items.map((item) => item.toJson()).toList();
}

class MetaItem {
  final String key;
  final String value;

  const MetaItem({
    required this.key,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };

  factory MetaItem.fromJson(Map<String, dynamic> json) => MetaItem(
    key: json['key'] as String,
    value: json['value'] as String,
  );
}
