import '../repositories/search_history_repository.dart';

/// Registra un término como la búsqueda más reciente.
class SaveSearchTerm {
  const SaveSearchTerm(this._repository);

  final SearchHistoryRepository _repository;

  /// Ver `SearchHistoryRepository.saveSearchTerm`: los repetidos se mueven al
  /// principio, no se duplican.
  Future<void> call(String term) => _repository.saveSearchTerm(term);
}
