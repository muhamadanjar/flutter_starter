import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/article_local_datasource.dart';
import '../../data/datasources/article_remote_datasource.dart';
import '../../data/repositories/article_repository_impl.dart';
import '../../domain/repositories/article_repository.dart';

final articleRemoteDataSourceProvider =
    Provider<ArticleRemoteDataSource>((ref) {
  return ArticleRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final articleLocalDataSourceProvider =
    Provider<ArticleLocalDataSource>((ref) {
  final box = Hive.box(AppConstants.cacheBox);
  return ArticleLocalDataSourceImpl(box);
});

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  return ArticleRepositoryImpl(
    remoteDataSource: ref.watch(articleRemoteDataSourceProvider),
    localDataSource: ref.watch(articleLocalDataSourceProvider),
  );
});
