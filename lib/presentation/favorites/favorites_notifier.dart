import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_favorite_ids.dart';
import '../../domain/usecases/set_favorite_status.dart';
import 'favorites_dependencies.dart';

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  late GetFavoriteIds _getFavoriteIds;
  late SetFavoriteStatus _setFavoriteStatus;

  final Set<String> _pendingIds = <String>{};
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<Set<String>> build() async {
    _getFavoriteIds = ref.watch(getFavoriteIdsUseCaseProvider);
    _setFavoriteStatus = ref.watch(setFavoriteStatusUseCaseProvider);
    return Set<String>.unmodifiable(await _getFavoriteIds());
  }

  Future<bool> toggleFavorite(String productId) async {
    final String normalizedId = productId.trim();
    final Set<String>? currentIds = switch (state) {
      AsyncData<Set<String>>(:final value) => value,
      _ => null,
    };
    if (normalizedId.isEmpty || currentIds == null) return false;
    if (!_pendingIds.add(normalizedId)) return true;

    final bool wasFavorite = currentIds.contains(normalizedId);
    state = AsyncData<Set<String>>(
      _updatedIds(currentIds, normalizedId, add: !wasFavorite),
    );

    final Future<bool> operation = _writeQueue.then<bool>((_) async {
      try {
        await _setFavoriteStatus(normalizedId, isFavorite: !wasFavorite);
        return true;
      } catch (_) {
        final Set<String>? latestIds = switch (state) {
          AsyncData<Set<String>>(:final value) => value,
          _ => null,
        };
        if (latestIds != null) {
          state = AsyncData<Set<String>>(
            _updatedIds(latestIds, normalizedId, add: wasFavorite),
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
}

Set<String> _updatedIds(Set<String> source, String id, {required bool add}) {
  final Set<String> updated = Set<String>.of(source);
  if (add) {
    updated.add(id);
  } else {
    updated.remove(id);
  }
  return Set<String>.unmodifiable(updated);
}
