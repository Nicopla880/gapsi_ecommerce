import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/favorites_collection.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/set_favorite_status.dart';
import 'favorites_dependencies.dart';

class FavoritesNotifier extends AsyncNotifier<FavoritesCollection> {
  late GetFavorites _getFavorites;
  late SetFavoriteStatus _setFavoriteStatus;

  final Set<String> _pendingIds = <String>{};
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<FavoritesCollection> build() async {
    _getFavorites = ref.watch(getFavoritesUseCaseProvider);
    _setFavoriteStatus = ref.watch(setFavoriteStatusUseCaseProvider);
    return _getFavorites();
  }

  Future<bool> toggleFavorite(Product product) async {
    final String normalizedId = product.id.trim();
    final FavoritesCollection? current = switch (state) {
      AsyncData<FavoritesCollection>(:final value) => value,
      _ => null,
    };
    if (normalizedId.isEmpty || current == null) return false;
    if (!_pendingIds.add(normalizedId)) return true;

    final bool wasFavorite = current.contains(normalizedId);
    state = AsyncData<FavoritesCollection>(
      current.setFavorite(product, value: !wasFavorite),
    );

    final Future<bool> operation = _writeQueue.then<bool>((_) async {
      try {
        await _setFavoriteStatus(product, isFavorite: !wasFavorite);
        return true;
      } catch (_) {
        final FavoritesCollection? latest = switch (state) {
          AsyncData<FavoritesCollection>(:final value) => value,
          _ => null,
        };
        if (latest != null) {
          state = AsyncData<FavoritesCollection>(
            latest.setFavorite(product, value: wasFavorite),
          );
        }
        return false;
      } finally {
        _pendingIds.remove(normalizedId);
      }
    });
    _writeQueue = operation.then<void>((bool _) {});
    return operation;
  }

  Future<void> hydrateKnownProducts(Iterable<Product> products) async {
    final FavoritesCollection? current = switch (state) {
      AsyncData<FavoritesCollection>(:final value) => value,
      _ => null,
    };
    if (current == null || current.legacyIds.isEmpty) return;

    for (final Product product in products) {
      if (current.legacyIds.contains(product.id)) {
        await _hydrateLegacyProduct(product);
      }
    }
  }

  Future<void> _hydrateLegacyProduct(Product product) async {
    final FavoritesCollection? current = switch (state) {
      AsyncData<FavoritesCollection>(:final value) => value,
      _ => null,
    };
    if (current == null || !current.legacyIds.contains(product.id)) return;

    state = AsyncData<FavoritesCollection>(
      current.setFavorite(product, value: true),
    );
    try {
      await _setFavoriteStatus(product, isFavorite: true);
    } catch (_) {
      state = AsyncData<FavoritesCollection>(current);
    }
  }
}
