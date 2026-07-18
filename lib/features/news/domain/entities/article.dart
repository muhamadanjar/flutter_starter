import 'package:equatable/equatable.dart';

/// Domain entity for a news/article item.
class Article extends Equatable {
  const Article({
    required this.id,
    required this.title,
    this.slug,
    this.excerpt,
    this.content,
    this.featureImageUrl,
    this.authorName,
    this.category,
    this.publishedAt,
    this.readTimeMinutes = 0,
  });

  final String id;
  final String title;
  final String? slug;
  final String? excerpt;
  final String? content;
  final String? featureImageUrl;
  final String? authorName;
  final String? category;
  final DateTime? publishedAt;
  final int readTimeMinutes;

  @override
  List<Object?> get props => [
        id,
        title,
        slug,
        excerpt,
        content,
        featureImageUrl,
        authorName,
        category,
        publishedAt,
        readTimeMinutes,
      ];
}

/// Paginated result for the article list endpoint.
class ArticlePage extends Equatable {
  const ArticlePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<Article> items;
  final int page;
  final int total;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, total, hasMore];
}
