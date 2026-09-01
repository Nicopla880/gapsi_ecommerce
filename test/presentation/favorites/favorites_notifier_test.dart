import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/errors/exceptions.dart';
import 'package:gapsi_ecommerce/domain/entities/favorites_collection.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/domain/repositories/favorites_repository.dart';
import 'package:gapsi_ecommerce/domain/usecases/get_favorites.dart';
import 'package:gapsi_ecommerce/domain/usecases/set_favorite_status.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_dependencies.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

const Product _console = Product(id: 'item-1', title: 'Nintendo Switch');

ProviderContainer _containerFor(_MockFavoritesRepository repository) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      getFavoritesUseCaseProvider.overrideWithValue(GetFavorites(repository)),
      setFavoriteStatusUseCaseProvider.overrideWithValue(
        SetFavoriteStatus(repository),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockFavoritesRepository repository;

  setUp(() {
    repository = _MockFavoritesRepository();
  });

  setUpAll(() => registerFallbackValue(_console));

  test('carga inicialmente los IDs persistidos', () async {
    when(
      () => repository.getFavorites(),
    ).thenAnswer((_) async => FavoritesCollection(products: const [_console]));
    final ProviderContainer container = _containerFor(repository);

    expect(
      (await container.read(favoritesProvider.future)).favoriteIds,
      <String>{'item-1'},
    );
    expect(container.read(favoritesProvider).requireValue.products, <Product>[
      _console,
    ]);
  });

  test('toggle agrega y luego elimina con actualización inmediata', () async {
    when(
      () => repository.getFavorites(),
    ).thenAnswer((_) async => FavoritesCollection());
    when(
      () => repository.setFavoriteStatus(
        any(),
        isFavorite: any(named: 'isFavorite'),
      ),
    ).thenAnswer((_) async {});
    final ProviderContainer container = _containerFor(repository);
    await container.read(favoritesProvider.future);
    final notifier = container.read(favoritesProvider.notifier);

    final Future<bool> add = notifier.toggleFavorite(_console);
    expect(container.read(favoritesProvider).requireValue.favoriteIds, <String>{
      'item-1',
    });
    expect(await add, isTrue);

    final Future<bool> remove = notifier.toggleFavorite(_console);
    expect(container.read(favoritesProvider).requireValue.products, isEmpty);
    expect(await remove, isTrue);

    verify(
      () => repository.setFavoriteStatus(_console, isFavorite: true),
    ).called(1);
    verify(
      () => repository.setFavoriteStatus(_console, isFavorite: false),
    ).called(1);
  });

  test('si persiste con error revierte el cambio optimista', () async {
    when(
      () => repository.getFavorites(),
    ).thenAnswer((_) async => FavoritesCollection());
    when(
      () => repository.setFavoriteStatus(
        any(),
        isFavorite: any(named: 'isFavorite'),
      ),
    ).thenThrow(const CacheException('write failed'));
    final ProviderContainer container = _containerFor(repository);
    await container.read(favoritesProvider.future);
    final notifier = container.read(favoritesProvider.notifier);

    final Future<bool> operation = notifier.toggleFavorite(_console);
    expect(container.read(favoritesProvider).requireValue.favoriteIds, <String>{
      'item-1',
    });

    expect(await operation, isFalse);
    expect(container.read(favoritesProvider).requireValue.products, isEmpty);
  });

  test('hidrata un ID legacy al reencontrar su Product', () async {
    when(
      () => repository.getFavorites(),
    ).thenAnswer((_) async => FavoritesCollection(legacyIds: const ['item-1']));
    when(
      () => repository.setFavoriteStatus(
        any(),
        isFavorite: any(named: 'isFavorite'),
      ),
    ).thenAnswer((_) async {});
    final ProviderContainer container = _containerFor(repository);
    await container.read(favoritesProvider.future);

    await container.read(favoritesProvider.notifier).hydrateKnownProducts(
      const <Product>[_console],
    );

    final FavoritesCollection state = container
        .read(favoritesProvider)
        .requireValue;
    expect(state.legacyIds, isEmpty);
    expect(state.products, <Product>[_console]);
  });
}
