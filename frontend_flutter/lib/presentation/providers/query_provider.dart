import 'package:flutter/material.dart';

import '../../data/models/query_model.dart';
import '../../data/repositories/query_repository.dart';

class QueryProvider with ChangeNotifier {
  final QueryRepository _repository = QueryRepository();
  List<QueryModel> _queries = [];
  bool _isLoading = false;

  List<QueryModel> get queries => _queries;
  bool get isLoading => _isLoading;

  Future<void> loadQueries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _queries = await _repository.getQueries();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createQuery({
    required String cropId,
    required String description,
  }) async {
    final createdQuery = await _repository.createQuery(
      cropId: cropId,
      description: description,
    );
    _queries = [createdQuery, ..._queries];
    notifyListeners();
  }

  Future<void> resolveQuery(
    String queryId, {
    String? resolutionNote,
  }) async {
    final resolvedQuery = await _repository.resolveQuery(
      queryId,
      resolutionNote: resolutionNote,
    );

    _queries = _queries
        .map((query) => query.id == queryId ? resolvedQuery : query)
        .toList();
    notifyListeners();
  }
}
