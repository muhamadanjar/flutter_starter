import '../../domain/entities/notification_item.dart';

class NotificationModel extends NotificationItem {
  const NotificationModel({
    required super.id,
    super.data,
    super.isRead,
    super.readAt,
    super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      data: json['data'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class NotificationPageModel extends NotificationPage {
  const NotificationPageModel({
    required super.items,
    required super.page,
    required super.total,
    required super.unread,
    required super.hasMore,
  });

  /// Parses the full API envelope: {code, message, data: [...], metas: {...}}
  factory NotificationPageModel.fromResponse(Map<String, dynamic> json) {
    final items = (json['data'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final metas = json['metas'] as Map<String, dynamic>? ?? {};
    return NotificationPageModel(
      items: items,
      page: metas['page'] as int? ?? 1,
      total: metas['total'] as int? ?? items.length,
      unread: metas['unread'] as int? ?? 0,
      hasMore: metas['has_more'] as bool? ?? false,
    );
  }
}
