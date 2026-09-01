import '../../core/errors/exceptions.dart';
import '../../domain/entities/favorites_collection.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/local/favorites_local_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._localDataSource);

  final FavoritesLocalDataSource _localDataSource;

  @override
  Future<FavoritesCollection> getFavorites() async {
    try {
      return await _localDataSource.getFavorites();
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException('No se pudieron leer los favoritos: $error');
    }
  }

  @override
  Future<void> setFavoriteStatus(
    Product product, {
    required bool isFavorite,
  }) async {
    if (product.id.trim().isEmpty) return;

    try {
      final FavoritesCollection current = await _localDataSource.getFavorites();
      final FavoritesCollection updated = current.setFavorite(
        product,
        value: isFavorite,
      );
      await _localDataSource.saveFavorites(updated);
    } on CacheException {
      rethrow;
    } catch (error) {
      throw CacheException('No se pudo actualizar el favorito: $error');
    }
  }
}
