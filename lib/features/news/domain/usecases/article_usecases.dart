import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';

class GetArticlesUseCase {
  GetArticlesUseCase(this._repository);
  final ArticleRepository _repository;

  Future<Either<Failure, ArticlePage>> call({
    int page = 1,
    int perPage = 10,
    String? category,
  }) {
    return _repository.getArticles(
      page: page,
      perPage: perPage,
      category: category,
    );
  }
}

class GetArticleDetailUseCase {
  GetArticleDetailUseCase(this._repository);
  final ArticleRepository _repository;

  Future<Either<Failure, Article>> call(String id) {
    return _repository.getArticleDetail(id);
  }
}
