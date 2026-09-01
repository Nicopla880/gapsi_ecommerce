import '../repositories/search_history_repository.dart';

/// Recupera el historial de búsquedas, del más reciente al más antiguo.
class GetSearchHistory {
  const GetSearchHistory(this._repository);

  final SearchHistoryRepository _repository;

  Future<List<String>> call() => _repository.getSearchHistory();
}
