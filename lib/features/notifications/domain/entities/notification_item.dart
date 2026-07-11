import 'dart:convert';

import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    this.data,
    this.isRead = false,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  /// `data` may be a plain string or a JSON payload like {"title": ..., "message": ...}.
  Map<String, dynamic>? get _payload {
    final raw = data;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String get title => _payload?['title'] as String? ?? 'Notification';

  String get message =>
      _payload?['message'] as String? ??
      _payload?['body'] as String? ??
      data ??
      '';

  NotificationItem copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationItem(
      id: id,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, data, isRead, readAt, createdAt];
}

class NotificationPage extends Equatable {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.total,
    required this.unread,
    required this.hasMore,
  });

  final List<NotificationItem> items;
  final int page;
  final int total;
  final int unread;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, total, unread, hasMore];
}
