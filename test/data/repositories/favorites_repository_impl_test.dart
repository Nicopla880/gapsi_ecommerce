import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/data/datasources/local/favorites_local_datasource.dart';
import 'package:gapsi_ecommerce/data/repositories/favorites_repository_impl.dart';
import 'package:gapsi_ecommerce/domain/entities/favorites_collection.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Product _console = Product(
  id: 'item-1',
  title: 'Nintendo Switch',
  price: 299.99,
  thumbnailUrl: 'https://example.com/switch.jpg',
  description: 'Portable console',
);

const Product _controller = Product(
  id: 'item-2',
  title: 'Nintendo Controller',
  price: 59.99,
);

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
    await repository.setFavoriteStatus(_console, isFavorite: true);
    expect((await repository.getFavorites()).favoriteIds, <String>{'item-1'});

    await repository.setFavoriteStatus(_console, isFavorite: false);
    expect((await repository.getFavorites()).favoriteIds, isEmpty);
  });

  test('snapshots completos sobreviven la recreación del datasource', () async {
    await repository.setFavoriteStatus(_console, isFavorite: true);
    await repository.setFavoriteStatus(_controller, isFavorite: true);

    final FavoritesRepositoryImpl recreatedRepository = FavoritesRepositoryImpl(
      FavoritesLocalDataSourceImpl(preferences),
    );

    final FavoritesCollection restored = await recreatedRepository
        .getFavorites();
    expect(restored.favoriteIds, <String>{'item-1', 'item-2'});
    expect(restored.products.first, _console);
    expect(restored.products.last, _controller);
  });

  test('agregar el mismo ID repetidamente no crea duplicados', () async {
    await repository.setFavoriteStatus(_console, isFavorite: true);
    await repository.setFavoriteStatus(_console, isFavorite: true);

    final FavoritesCollection favorites = await repository.getFavorites();
    expect(favorites.favoriteIds, <String>{'item-1'});
    expect(favorites.products.length, 1);
  });

  test('lee formato legacy de IDs sin fallar ni inventar Products', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'favorite_product_ids': jsonEncode(<String>['item-1', 'item-1']),
    });
    preferences = await SharedPreferences.getInstance();
    repository = FavoritesRepositoryImpl(
      FavoritesLocalDataSourceImpl(preferences),
    );

    final FavoritesCollection restored = await repository.getFavorites();

    expect(restored.legacyIds, <String>{'item-1'});
    expect(restored.favoriteIds, <String>{'item-1'});
    expect(restored.products, isEmpty);
  });

  test('hidratar un ID legacy migra a snapshot renderizable', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'favorite_product_ids': jsonEncode(<String>['item-1']),
    });
    preferences = await SharedPreferences.getInstance();
    repository = FavoritesRepositoryImpl(
      FavoritesLocalDataSourceImpl(preferences),
    );

    await repository.setFavoriteStatus(_console, isFavorite: true);
    final FavoritesCollection migrated = await repository.getFavorites();

    expect(migrated.legacyIds, isEmpty);
    expect(migrated.products, <Product>[_console]);
  });
}
