abstract class FavoritesRepository {
  Future<Set<String>> getFavoriteIds();

  Future<void> setFavoriteStatus(String productId, {required bool isFavorite});
}
