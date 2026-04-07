import '../../core/services/api_service.dart';
import '../models/query_model.dart';

class QueryRepository {
  Future<List<QueryModel>> getQueries() async {
    final response = await ApiService.get('/queries');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(QueryModel.fromJson)
        .toList();
  }

  Future<QueryModel> createQuery({
    required String cropId,
    required String description,
  }) async {
    final response = await ApiService.post('/queries', {
      'cropId': cropId,
      'description': description,
    });

    return QueryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<QueryModel> resolveQuery(
    String queryId, {
    String? resolutionNote,
  }) async {
    final response = await ApiService.patch('/queries/$queryId/resolve', {
      'resolutionNote': resolutionNote,
    });

    return QueryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
