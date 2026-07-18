import '../../domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.id,
    required super.title,
    super.slug,
    super.excerpt,
    super.content,
    super.featureImageUrl,
    super.authorName,
    super.category,
    super.publishedAt,
    super.readTimeMinutes,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: (json['id'] ?? json['slug'] ?? '').toString(),
      title: json['title'] as String? ?? 'Untitled',
      slug: json['slug'] as String?,
      excerpt: json['excerpt'] as String? ?? json['summary'] as String?,
      content: json['content'] as String? ?? json['body'] as String?,
      featureImageUrl: json['feature_image'] as String? ??
          json['feature_image_url'] as String? ??
          json['thumbnail'] as String? ??
          json['image'] as String?,
      authorName: json['author'] as String? ?? json['author_name'] as String?,
      category: json['category'] as String?,
      publishedAt: _parseDate(
        json['published_at'] ?? json['created_at'] ?? json['date'],
      ),
      readTimeMinutes: json['read_time'] as int? ??
          json['reading_time'] as int? ??
          json['read_time_minutes'] as int? ??
          0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'excerpt': excerpt,
        'content': content,
        'feature_image': featureImageUrl,
        'author': authorName,
        'category': category,
        'published_at': publishedAt?.toIso8601String(),
        'read_time': readTimeMinutes,
      };
}

class ArticlePageModel extends ArticlePage {
  const ArticlePageModel({
    required super.items,
    required super.page,
    required super.total,
    required super.hasMore,
  });

  /// Parses the API envelope: {data: [...], metas: {page, total, has_more}}.
  factory ArticlePageModel.fromResponse(Map<String, dynamic> json) {
    final items = (json['data'] as List<dynamic>? ?? [])
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final metas = json['metas'] as Map<String, dynamic>? ?? {};
    return ArticlePageModel(
      items: items,
      page: metas['page'] as int? ?? 1,
      total: metas['total'] as int? ?? items.length,
      hasMore: metas['has_more'] as bool? ?? false,
    );
  }

  /// Cache envelope: {items: [...], page, total, has_more}.
  Map<String, dynamic> toCache() => {
        'items': items.map((e) => (e as ArticleModel).toJson()).toList(),
        'page': page,
        'total': total,
        'has_more': hasMore,
      };

  factory ArticlePageModel.fromCache(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ArticlePageModel(
      items: items,
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? items.length,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
