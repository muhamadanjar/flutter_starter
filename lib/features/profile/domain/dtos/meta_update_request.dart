sealed class MetaUpdateRequest {
  const MetaUpdateRequest();

  /// Single returns a Map, bulk returns a List — the API accepts both shapes.
  dynamic toJson();
}

/// Single metadata update
final class SingleMetaUpdate extends MetaUpdateRequest {

  const SingleMetaUpdate({
    required this.key,
    required this.value,
  });
  final String key;
  final String value;

  @override
  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };
}

/// Bulk metadata updates
final class BulkMetaUpdate extends MetaUpdateRequest {

  const BulkMetaUpdate({required this.items});
  final List<MetaItem> items;

  @override
  List<Map<String, dynamic>> toJson() => items.map((item) => item.toJson()).toList();
}

class MetaItem {

  const MetaItem({
    required this.key,
    required this.value,
  });

  factory MetaItem.fromJson(Map<String, dynamic> json) => MetaItem(
    key: json['key'] as String,
    value: json['value'] as String,
  );
  final String key;
  final String value;

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
  };
}
