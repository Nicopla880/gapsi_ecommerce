import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/exceptions.dart';

abstract class FavoritesLocalDataSource {
  Future<Set<String>> getFavoriteIds();
  Future<void> saveFavoriteIds(Set<String> favoriteIds);
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  const FavoritesLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'favorite_product_ids';

  @override
  Future<Set<String>> getFavoriteIds() async {
    final String? raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const <String>{};

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const CacheException(
          'Favoritos almacenados con formato inválido.',
        );
      }
      return Set<String>.unmodifiable(
        decoded
            .whereType<String>()
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty),
      );
    } on FormatException catch (error) {
      throw CacheException('Favoritos ilegibles: ${error.message}');
    }
  }

  @override
  Future<void> saveFavoriteIds(Set<String> favoriteIds) async {
    final List<String> sortedIds =
        favoriteIds
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    final bool saved = await _prefs.setString(
      _storageKey,
      jsonEncode(sortedIds),
    );
    if (!saved) {
      throw const CacheException('No se pudieron guardar los favoritos.');
    }
  }
}
