import 'package:hive/hive.dart';

import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/favorites_collection.dart';
import '../../../domain/entities/product.dart';

abstract class FavoritesLocalDataSource {
  Future<FavoritesCollection> getFavorites();
  Future<void> saveFavorites(FavoritesCollection favorites);
}

/// Implementación sobre Hive.
///
/// Los favoritos se guardan como snapshots mínimos de producto y no como IDs
/// sueltos, para que la colección se pueda renderizar sin volver a la red.
/// Hive almacena mapas y listas de primitivos de forma nativa, así que el
/// snapshot no necesita adaptador generado.
class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  const FavoritesLocalDataSourceImpl(this._box);

  final Box<dynamic> _box;

  static const String boxName = 'favorites';
  static const String _storageKey = 'products_v2';

  /// Clave del formato anterior, que solo guardaba IDs. Se sigue leyendo hasta
  /// poder completar el snapshot sin inventar datos.
  static const String _legacyStorageKey = 'favorite_product_ids';

  @override
  Future<FavoritesCollection> getFavorites() async {
    final Object? stored = _box.get(_storageKey);
    if (stored == null) return _readLegacyFavorites();

    if (stored is! Map) {
      throw const CacheException('Favoritos almacenados con formato inválido.');
    }
    final Object? rawProducts = stored['products'];
    final Object? rawLegacyIds = stored['legacyIds'];
    if (rawProducts is! List || rawLegacyIds is! List) {
      throw const CacheException(
        'Favoritos almacenados con formato incompleto.',
      );
    }

    return FavoritesCollection(
      products: rawProducts
          .whereType<Map<dynamic, dynamic>>()
          .map(_productFromStored)
          .whereType<Product>(),
      legacyIds: rawLegacyIds.whereType<String>(),
    );
  }

  @override
  Future<void> saveFavorites(FavoritesCollection favorites) async {
    try {
      await _box.put(_storageKey, <String, Object>{
        'version': 2,
        'products': favorites.products.map(_productToStored).toList(),
        'legacyIds': favorites.legacyIds.toList()..sort(),
      });
      await _box.delete(_legacyStorageKey);
    } on HiveError catch (error) {
      throw CacheException(
        'No se pudieron guardar los favoritos: ${error.message}',
      );
    }
  }

  FavoritesCollection _readLegacyFavorites() {
    final Object? stored = _box.get(_legacyStorageKey);
    if (stored == null) return FavoritesCollection();
    if (stored is! List) return FavoritesCollection();
    return FavoritesCollection(legacyIds: stored.whereType<String>());
  }
}

Map<String, Object?> _productToStored(Product product) => <String, Object?>{
  'id': product.id,
  'title': product.title,
  'price': product.price,
  'thumbnailUrl': product.thumbnailUrl,
  'description': product.description,
};

Product? _productFromStored(Map<dynamic, dynamic> stored) {
  final Object? rawId = stored['id'];
  if (rawId is! String || rawId.trim().isEmpty) return null;
  final Object? rawPrice = stored['price'];
  return Product(
    id: rawId.trim(),
    title: stored['title'] is String ? stored['title'] as String : '',
    price: rawPrice is num ? rawPrice.toDouble() : null,
    thumbnailUrl: stored['thumbnailUrl'] is String
        ? stored['thumbnailUrl'] as String
        : null,
    description: stored['description'] is String
        ? stored['description'] as String
        : null,
  );
}
