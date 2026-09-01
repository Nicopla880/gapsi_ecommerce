import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/data/datasources/local/favorites_local_datasource.dart';
import 'package:gapsi_ecommerce/data/repositories/favorites_repository_impl.dart';
import 'package:gapsi_ecommerce/domain/entities/favorites_collection.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:hive/hive.dart';

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

  late Directory tempDir;
  late Box<dynamic> box;
  late FavoritesLocalDataSourceImpl localDataSource;
  late FavoritesRepositoryImpl repository;

  setUpAll(() async {
    // Hive escribe en disco: cada corrida usa su propio directorio temporal.
    tempDir = await Directory.systemTemp.createTemp('gapsi_favorites_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    box = await Hive.openBox<dynamic>(FavoritesLocalDataSourceImpl.boxName);
    await box.clear();
    localDataSource = FavoritesLocalDataSourceImpl(box);
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

    // Reabrir el box desde disco prueba que el snapshot sobrevive al proceso.
    await box.close();
    final Box<dynamic> reopened = await Hive.openBox<dynamic>(
      FavoritesLocalDataSourceImpl.boxName,
    );
    final FavoritesRepositoryImpl recreatedRepository = FavoritesRepositoryImpl(
      FavoritesLocalDataSourceImpl(reopened),
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
    await box.put('favorite_product_ids', <String>['item-1', 'item-1']);

    final FavoritesCollection restored = await repository.getFavorites();

    expect(restored.legacyIds, <String>{'item-1'});
    expect(restored.favoriteIds, <String>{'item-1'});
    expect(restored.products, isEmpty);
  });

  test('hidratar un ID legacy migra a snapshot renderizable', () async {
    await box.put('favorite_product_ids', <String>['item-1']);

    await repository.setFavoriteStatus(_console, isFavorite: true);
    final FavoritesCollection migrated = await repository.getFavorites();

    expect(migrated.legacyIds, isEmpty);
    expect(migrated.products, <Product>[_console]);
  });
}
