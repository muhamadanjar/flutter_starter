import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/article_provider.dart';

class ArticleDetailPage extends ConsumerWidget {
  const ArticleDetailPage({required this.articleId, super.key});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncArticle = ref.watch(articleDetailProvider(articleId));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: asyncArticle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 56, color: colors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load article',
                  style: AppTypography.bodyLarge
                      .copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.refresh(articleDetailProvider(articleId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (article) {
          if (article == null) {
            return const Center(child: Text('Article not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                elevation: 0,
                actions: [
                  Consumer(
                    builder: (context, ref, _) {
                      final savedIds = ref
                          .watch(savedArticlesProvider)
                          .map((a) => a.id)
                          .toSet();
                      final isSaved = savedIds.contains(article.id);
                      return IconButton(
                        icon: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: colors.textPrimary,
                        ),
                        tooltip: isSaved ? 'Remove from saved' : 'Save for offline',
                        onPressed: () =>
                            ref.read(savedArticlesProvider.notifier).toggleSave(article),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: article.featureImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: article.featureImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: colors.primaryContainer),
                          errorWidget: (_, __, ___) =>
                              Container(color: colors.primaryContainer),
                        )
                      : Container(color: colors.primaryContainer),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.category != null &&
                          article.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category!,
                            style: AppTypography.labelSmall.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        article.title,
                        style: AppTypography.headlineSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (article.authorName != null)
                            Expanded(
                              child: Text(
                                article.authorName!,
                                style: AppTypography.labelMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          if (article.publishedAt != null)
                            Text(
                              DateFormatter.formatRelative(
                                  article.publishedAt!),
                              style: AppTypography.labelSmall
                                  .copyWith(color: colors.textHint),
                            ),
                          if (article.readTimeMinutes > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· ${article.readTimeMinutes} min read',
                              style: AppTypography.labelSmall
                                  .copyWith(color: colors.textHint),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        article.content ?? article.excerpt ?? '',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: FilledButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to news'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
