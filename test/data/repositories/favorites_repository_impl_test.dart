import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/data/datasources/local/favorites_local_datasource.dart';
import 'package:gapsi_ecommerce/data/repositories/favorites_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;
  late FavoritesLocalDataSourceImpl localDataSource;
  late FavoritesRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = await SharedPreferences.getInstance();
    localDataSource = FavoritesLocalDataSourceImpl(preferences);
    repository = FavoritesRepositoryImpl(localDataSource);
  });

  test('agrega y elimina un favorito por Product.id', () async {
    await repository.setFavoriteStatus('item-1', isFavorite: true);
    expect(await repository.getFavoriteIds(), <String>{'item-1'});

    await repository.setFavoriteStatus('item-1', isFavorite: false);
    expect(await repository.getFavoriteIds(), isEmpty);
  });

  test('persistencia sobrevive la recreación del datasource', () async {
    await repository.setFavoriteStatus('item-1', isFavorite: true);
    await repository.setFavoriteStatus('item-2', isFavorite: true);

    final FavoritesRepositoryImpl recreatedRepository = FavoritesRepositoryImpl(
      FavoritesLocalDataSourceImpl(preferences),
    );

    expect(await recreatedRepository.getFavoriteIds(), <String>{
      'item-1',
      'item-2',
    });
  });

  test('agregar el mismo ID repetidamente no crea duplicados', () async {
    await repository.setFavoriteStatus('item-1', isFavorite: true);
    await repository.setFavoriteStatus('item-1', isFavorite: true);

    final Set<String> favoriteIds = await repository.getFavoriteIds();
    expect(favoriteIds, <String>{'item-1'});
    expect(favoriteIds.length, 1);
  });
}
