import '../../core/errors/exceptions.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../datasources/local/search_history_local_datasource.dart';

class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  const SearchHistoryRepositoryImpl(this._localDataSource);

  final SearchHistoryLocalDataSource _localDataSource;

  @override
  Future<List<String>> getSearchHistory() async {
    try {
      return await _localDataSource.getSearchHistory();
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException('No se pudo leer el historial: $error');
    }
  }

  @override
  Future<void> saveSearchTerm(String term) async {
    try {
      await _localDataSource.saveSearchTerm(term);
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException('No se pudo guardar el término: $error');
    }
  }
}
