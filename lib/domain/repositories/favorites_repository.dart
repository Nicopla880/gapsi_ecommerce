import '../entities/favorites_collection.dart';
import '../entities/product.dart';

abstract class FavoritesRepository {
  Future<FavoritesCollection> getFavorites();

  Future<void> setFavoriteStatus(Product product, {required bool isFavorite});
}
