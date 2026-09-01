import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/errors/exceptions.dart';
import 'package:gapsi_ecommerce/domain/repositories/favorites_repository.dart';
import 'package:gapsi_ecommerce/domain/usecases/get_favorite_ids.dart';
import 'package:gapsi_ecommerce/domain/usecases/set_favorite_status.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_dependencies.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

ProviderContainer _containerFor(_MockFavoritesRepository repository) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      getFavoriteIdsUseCaseProvider.overrideWithValue(
        GetFavoriteIds(repository),
      ),
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

  test('carga inicialmente los IDs persistidos', () async {
    when(
      () => repository.getFavoriteIds(),
    ).thenAnswer((_) async => <String>{'item-1'});
    final ProviderContainer container = _containerFor(repository);

    expect(await container.read(favoritesProvider.future), <String>{'item-1'});
    expect(container.read(favoritesProvider).requireValue, <String>{'item-1'});
  });

  test('toggle agrega y luego elimina con actualización inmediata', () async {
    when(() => repository.getFavoriteIds()).thenAnswer((_) async => <String>{});
    when(
      () => repository.setFavoriteStatus(
        any(),
        isFavorite: any(named: 'isFavorite'),
      ),
    ).thenAnswer((_) async {});
    final ProviderContainer container = _containerFor(repository);
    await container.read(favoritesProvider.future);
    final notifier = container.read(favoritesProvider.notifier);

    final Future<bool> add = notifier.toggleFavorite('item-1');
    expect(container.read(favoritesProvider).requireValue, <String>{'item-1'});
    expect(await add, isTrue);

    final Future<bool> remove = notifier.toggleFavorite('item-1');
    expect(container.read(favoritesProvider).requireValue, isEmpty);
    expect(await remove, isTrue);

    verify(
      () => repository.setFavoriteStatus('item-1', isFavorite: true),
    ).called(1);
    verify(
      () => repository.setFavoriteStatus('item-1', isFavorite: false),
    ).called(1);
  });

  test('si persiste con error revierte el cambio optimista', () async {
    when(() => repository.getFavoriteIds()).thenAnswer((_) async => <String>{});
    when(
      () => repository.setFavoriteStatus(
        any(),
        isFavorite: any(named: 'isFavorite'),
      ),
    ).thenThrow(const CacheException('write failed'));
    final ProviderContainer container = _containerFor(repository);
    await container.read(favoritesProvider.future);
    final notifier = container.read(favoritesProvider.notifier);

    final Future<bool> operation = notifier.toggleFavorite('item-1');
    expect(container.read(favoritesProvider).requireValue, <String>{'item-1'});

    expect(await operation, isFalse);
    expect(container.read(favoritesProvider).requireValue, isEmpty);
  });
}
