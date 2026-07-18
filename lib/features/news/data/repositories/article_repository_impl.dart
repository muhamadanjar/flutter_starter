import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/article_local_datasource.dart';
import '../datasources/article_remote_datasource.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ArticleRemoteDataSource remoteDataSource;
  final ArticleLocalDataSource localDataSource;

  @override
  Future<Either<Failure, ArticlePage>> getArticles({
    int page = 1,
    int perPage = 10,
    String? category,
  }) async {
    try {
      final result = await remoteDataSource.getArticles(
        page: page,
        perPage: perPage,
        category: category,
      );
      await localDataSource.cacheArticles(result);
      return right(result);
    } on NetworkException catch (_) {
      // Offline: serve cached page if available.
      final cached = localDataSource.getCachedArticles(page);
      if (cached != null) return right(cached);
      return left(const NetworkFailure(message: 'No internet connection'));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      final cached = localDataSource.getCachedArticles(page);
      if (cached != null) return right(cached);
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Article>> getArticleDetail(String id) async {
    try {
      final result = await remoteDataSource.getArticleDetail(id);
      await localDataSource.cacheArticle(result);
      return right(result);
    } on NetworkException catch (_) {
      final cached = localDataSource.getCachedArticle(id);
      if (cached != null) return right(cached);
      return left(const NetworkFailure(message: 'No internet connection'));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      final cached = localDataSource.getCachedArticle(id);
      if (cached != null) return right(cached);
      return left(ServerFailure(message: e.toString()));
    }
  }
}
