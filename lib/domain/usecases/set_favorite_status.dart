import '../repositories/favorites_repository.dart';

class SetFavoriteStatus {
  const SetFavoriteStatus(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(String productId, {required bool isFavorite}) {
    return _repository.setFavoriteStatus(productId, isFavorite: isFavorite);
  }
}
