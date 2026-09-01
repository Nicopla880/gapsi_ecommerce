import '../entities/product.dart';
import '../repositories/favorites_repository.dart';

class SetFavoriteStatus {
  const SetFavoriteStatus(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(Product product, {required bool isFavorite}) {
    return _repository.setFavoriteStatus(product, isFavorite: isFavorite);
  }
}
