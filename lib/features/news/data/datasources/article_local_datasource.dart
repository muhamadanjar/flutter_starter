import 'package:hive/hive.dart';

import '../models/article_model.dart';

abstract class ArticleLocalDataSource {
  Future<void> cacheArticles(ArticlePageModel page);
  ArticlePageModel? getCachedArticles(int page);

  Future<void> cacheArticle(ArticleModel article);
  ArticleModel? getCachedArticle(String id);

  Future<void> saveArticle(ArticleModel article);
  Future<void> removeSaved(String id);
  List<ArticleModel> getSavedArticles();

  Future<void> clear();
}

class ArticleLocalDataSourceImpl implements ArticleLocalDataSource {
  ArticleLocalDataSourceImpl(this._box);
  final Box<dynamic> _box;

  static const _listPrefix = 'article_list_';
  static const _detailPrefix = 'article_detail_';
  static const _savedPrefix = 'article_saved_';

  String _listKey(int page) => '$_listPrefix$page';
  String _detailKey(String id) => '$_detailPrefix$id';
  String _savedKey(String id) => '$_savedPrefix$id';

  @override
  Future<void> cacheArticles(ArticlePageModel page) async {
    await _box.put(_listKey(page.page), page.toCache());
  }

  @override
  ArticlePageModel? getCachedArticles(int page) {
    final raw = _box.get(_listKey(page));
    if (raw is! Map) return null;
    return ArticlePageModel.fromCache(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> cacheArticle(ArticleModel article) async {
    await _box.put(_detailKey(article.id), article.toJson());
  }

  @override
  ArticleModel? getCachedArticle(String id) {
    final raw = _box.get(_detailKey(id));
    if (raw is! Map) return null;
    return ArticleModel.fromJson(Map<String, dynamic>.from(raw));
  }

  /// Persist an article the user explicitly saved for offline reading.
  Future<void> saveArticle(ArticleModel article) async {
    await _box.put(_savedKey(article.id), article.toJson());
  }

  Future<void> removeSaved(String id) async {
    await _box.delete(_savedKey(id));
  }

  List<ArticleModel> getSavedArticles() {
    return _box.keys
        .where((k) => k is String && k.startsWith(_savedPrefix))
        .map((k) => _box.get(k))
        .whereType<Map>()
        .map((m) => ArticleModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<void> clear() async {
    final keys = _box.keys
        .where((k) =>
            k is String &&
            (k.startsWith(_listPrefix) ||
                k.startsWith(_detailPrefix) ||
                k.startsWith(_savedPrefix)))
        .toList();
    await _box.deleteAll(keys);
  }
}
