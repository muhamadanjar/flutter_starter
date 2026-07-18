import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/article.dart';

abstract class ArticleRepository {
  Future<Either<Failure, ArticlePage>> getArticles({
    int page = 1,
    int perPage = 10,
    String? category,
  });

  Future<Either<Failure, Article>> getArticleDetail(String id);
}
