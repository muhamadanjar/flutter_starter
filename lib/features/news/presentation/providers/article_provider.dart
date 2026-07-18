import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/article.dart';
import '../../data/models/article_model.dart';
import '../../data/datasources/article_local_datasource.dart';
import '../../domain/usecases/article_usecases.dart';
import './article_repository_provider.dart';

// Use Cases
final getArticlesUseCaseProvider = Provider<GetArticlesUseCase>((ref) {
  return GetArticlesUseCase(ref.watch(articleRepositoryProvider));
});

final getArticleDetailUseCaseProvider = Provider<GetArticleDetailUseCase>((ref) {
  return GetArticleDetailUseCase(ref.watch(articleRepositoryProvider));
});

// List state (paginated, pull-to-refresh, infinite scroll)
class ArticleListState {
  const ArticleListState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.category,
  });

  final List<Article> items;
  final int page;
  final int total;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? category;

  ArticleListState copyWith({
    List<Article>? items,
    int? page,
    int? total,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    String? category,
  }) {
    return ArticleListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      category: category ?? this.category,
    );
  }
}

class ArticleListNotifier extends StateNotifier<ArticleListState> {
  ArticleListNotifier(this._getArticles) : super(const ArticleListState());

  final GetArticlesUseCase _getArticles;
  static const _perPage = 10;

  Future<void> loadInitial({String? category}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      category: category,
    );
    final result = await _getArticles(
      page: 1,
      perPage: _perPage,
      category: category,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoading: false,
        items: data.items,
        page: data.page,
        total: data.total,
        hasMore: data.hasMore,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    final result = await _getArticles(
      page: state.page + 1,
      perPage: _perPage,
      category: state.category,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...data.items],
        page: data.page,
        total: data.total,
        hasMore: data.hasMore,
      ),
    );
  }

  Future<void> refresh() async {
    state = const ArticleListState();
    await loadInitial(category: state.category);
  }
}

final articleListProvider =
    StateNotifierProvider<ArticleListNotifier, ArticleListState>((ref) {
  return ArticleListNotifier(ref.watch(getArticlesUseCaseProvider));
});

// Detail state
final articleDetailProvider =
    FutureProvider.family<Article?, String>((ref, id) async {
  final result = await ref.watch(getArticleDetailUseCaseProvider)(id);
  return result.fold((failure) => throw failure, (article) => article);
});

// Saved-for-offline (local only)
class SavedArticlesNotifier extends StateNotifier<List<Article>> {
  SavedArticlesNotifier(this._local) : super(const []) {
    state = _local.getSavedArticles();
  }

  final ArticleLocalDataSource _local;

  bool isSaved(String id) => state.any((a) => a.id == id);

  Future<void> toggleSave(Article article) async {
    if (isSaved(article.id)) {
      await _local.removeSaved(article.id);
    } else {
      final model = _local.getCachedArticle(article.id) ??
          ArticleModel(
            id: article.id,
            title: article.title,
            slug: article.slug,
            excerpt: article.excerpt,
            content: article.content,
            featureImageUrl: article.featureImageUrl,
            authorName: article.authorName,
            category: article.category,
            publishedAt: article.publishedAt,
            readTimeMinutes: article.readTimeMinutes,
          );
      await _local.saveArticle(model);
    }
    state = _local.getSavedArticles();
  }
}

final savedArticlesProvider =
    StateNotifierProvider<SavedArticlesNotifier, List<Article>>((ref) {
  return SavedArticlesNotifier(ref.watch(articleLocalDataSourceProvider));
});
