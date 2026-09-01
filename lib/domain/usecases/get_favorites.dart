import '../entities/favorites_collection.dart';
import '../repositories/favorites_repository.dart';

class GetFavorites {
  const GetFavorites(this._repository);

  final FavoritesRepository _repository;

  Future<FavoritesCollection> call() => _repository.getFavorites();
}
