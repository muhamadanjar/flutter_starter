import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/article_model.dart';

abstract class ArticleRemoteDataSource {
  Future<ArticlePageModel> getArticles({
    int page = 1,
    int perPage = 10,
    String? category,
  });

  Future<ArticleModel> getArticleDetail(String id);
}

class ArticleRemoteDataSourceImpl implements ArticleRemoteDataSource {
  ArticleRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<ArticlePageModel> getArticles({
    int page = 1,
    int perPage = 10,
    String? category,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final response = await _dioClient.get(
      ApiConstants.news,
      queryParameters: queryParameters,
    );
    return ArticlePageModel.fromResponse(response.data as Map<String, dynamic>);
  }

  @override
  Future<ArticleModel> getArticleDetail(String id) async {
    final response = await _dioClient.get('${ApiConstants.news}/$id');
    final data = response.data;
    final payload = data is Map<String, dynamic>
        ? data
        : (data is Map && data['data'] is Map
            ? data['data'] as Map<String, dynamic>
            : <String, dynamic>{});
    return ArticleModel.fromJson(payload);
  }
}
