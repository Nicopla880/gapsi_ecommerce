import '../../core/errors/exceptions.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/local/favorites_local_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._localDataSource);

  final FavoritesLocalDataSource _localDataSource;

  @override
  Future<Set<String>> getFavoriteIds() async {
    try {
      return await _localDataSource.getFavoriteIds();
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException('No se pudieron leer los favoritos: $error');
    }
  }

  @override
  Future<void> setFavoriteStatus(
    String productId, {
    required bool isFavorite,
  }) async {
    final String normalizedId = productId.trim();
    if (normalizedId.isEmpty) return;

    try {
      final Set<String> current = await _localDataSource.getFavoriteIds();
      final Set<String> updated = Set<String>.of(current);
      final bool changed = isFavorite
          ? updated.add(normalizedId)
          : updated.remove(normalizedId);
      if (changed) await _localDataSource.saveFavoriteIds(updated);
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException('No se pudo actualizar el favorito: $error');
    }
  }
}
