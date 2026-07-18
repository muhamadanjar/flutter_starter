import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/article.dart';

/// A news/article card with a feature image, title, excerpt and meta.
class ArticleCard extends StatelessWidget {
  const ArticleCard({required this.article, super.key});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/news/${article.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureImage(url: article.featureImageUrl),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.category != null && article.category!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _CategoryChip(category: article.category!),
                    ),
                  Text(
                    article.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (article.excerpt != null &&
                      article.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.excerpt!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _MetaRow(article: article),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureImage extends StatelessWidget {
  const _FeatureImage({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const height = 160.0;
    if (url == null || url!.isEmpty) {
      return Container(
        height: height,
        color: context.colors.primaryContainer,
        child: Center(
          child: Icon(
            Icons.article_outlined,
            size: 40,
            color: context.colors.primary,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: height,
        color: context.colors.primaryContainer,
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: context.colors.primaryContainer,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: AppTypography.labelSmall.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        if (article.authorName != null)
          Expanded(
            child: Text(
              article.authorName!,
              style: AppTypography.labelSmall.copyWith(color: colors.textHint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (article.publishedAt != null)
          Text(
            DateFormatter.formatRelative(article.publishedAt!),
            style: AppTypography.labelSmall.copyWith(color: colors.textHint),
          ),
        if (article.readTimeMinutes > 0) ...[
          const SizedBox(width: 6),
          Text(
            '· ${article.readTimeMinutes} min',
            style: AppTypography.labelSmall.copyWith(color: colors.textHint),
          ),
        ],
      ],
    );
  }
}
