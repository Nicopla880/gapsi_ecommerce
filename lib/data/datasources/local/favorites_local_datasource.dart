import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/favorites_collection.dart';
import '../../../domain/entities/product.dart';

abstract class FavoritesLocalDataSource {
  Future<FavoritesCollection> getFavorites();
  Future<void> saveFavorites(FavoritesCollection favorites);
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  const FavoritesLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'favorite_products_v2';
  static const String _legacyStorageKey = 'favorite_product_ids';

  @override
  Future<FavoritesCollection> getFavorites() async {
    final String? raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return _readLegacyFavorites();

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const CacheException(
          'Favoritos almacenados con formato inválido.',
        );
      }
      final Object? rawProducts = decoded['products'];
      final Object? rawLegacyIds = decoded['legacyIds'];
      if (rawProducts is! List || rawLegacyIds is! List) {
        throw const CacheException(
          'Favoritos almacenados con formato incompleto.',
        );
      }
      return FavoritesCollection(
        products: rawProducts
            .whereType<Map>()
            .map(
              (Map<dynamic, dynamic> json) =>
                  _productFromJson(Map<String, dynamic>.from(json)),
            )
            .whereType<Product>(),
        legacyIds: rawLegacyIds.whereType<String>(),
      );
    } on FormatException catch (error) {
      throw CacheException('Favoritos ilegibles: ${error.message}');
    }
  }

  @override
  Future<void> saveFavorites(FavoritesCollection favorites) async {
    final bool saved = await _prefs.setString(
      _storageKey,
      jsonEncode(<String, Object>{
        'version': 2,
        'products': favorites.products.map(_productToJson).toList(),
        'legacyIds': favorites.legacyIds.toList()..sort(),
      }),
    );
    if (!saved) {
      throw const CacheException('No se pudieron guardar los favoritos.');
    }
    await _prefs.remove(_legacyStorageKey);
  }

  FavoritesCollection _readLegacyFavorites() {
    final String? raw = _prefs.getString(_legacyStorageKey);
    if (raw == null || raw.isEmpty) return FavoritesCollection();
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return FavoritesCollection();
      return FavoritesCollection(legacyIds: decoded.whereType<String>());
    } on FormatException catch (error) {
      throw CacheException('Favoritos legacy ilegibles: ${error.message}');
    }
  }
}

Map<String, Object?> _productToJson(Product product) => <String, Object?>{
  'id': product.id,
  'title': product.title,
  'price': product.price,
  'thumbnailUrl': product.thumbnailUrl,
  'description': product.description,
};

Product? _productFromJson(Map<String, dynamic> json) {
  final Object? rawId = json['id'];
  if (rawId is! String || rawId.trim().isEmpty) return null;
  final Object? rawPrice = json['price'];
  return Product(
    id: rawId.trim(),
    title: json['title'] is String ? json['title'] as String : '',
    price: rawPrice is num ? rawPrice.toDouble() : null,
    thumbnailUrl: json['thumbnailUrl'] is String
        ? json['thumbnailUrl'] as String
        : null,
    description: json['description'] is String
        ? json['description'] as String
        : null,
  );
}
