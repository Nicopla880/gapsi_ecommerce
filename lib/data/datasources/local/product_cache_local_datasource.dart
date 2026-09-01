import 'package:hive/hive.dart';

import '../../../core/errors/exceptions.dart';
import '../../../domain/entities/product.dart';
import '../../models/product_snapshot.dart';

/// Una página de resultados guardada localmente, con el momento en que se
/// escribió. La política de vencimiento no vive acá: el datasource solo informa
/// la antigüedad y el repositorio decide qué hacer con ella.
class CachedProductPage {
  const CachedProductPage({required this.products, required this.savedAt});

  final List<Product> products;
  final DateTime savedAt;

  Duration ageAt(DateTime now) => now.difference(savedAt);
}

/// Caché local de páginas de resultados de búsqueda.
abstract class ProductCacheLocalDataSource {
  Future<CachedProductPage?> readPage({
    required String keyword,
    required int page,
  });

  Future<void> writePage({
    required String keyword,
    required int page,
    required List<Product> products,
  });
}

/// Implementación sobre Hive.
///
/// Cada entrada es una página `(keyword, page)`. Se usa Hive y no
/// `shared_preferences` por la misma razón que los favoritos: esto es una
/// colección de registros con vencimiento, no una preferencia.
class ProductCacheLocalDataSourceImpl implements ProductCacheLocalDataSource {
  const ProductCacheLocalDataSourceImpl(this._box);

  final Box<dynamic> _box;

  static const String boxName = 'product_cache';

  /// Tope de páginas guardadas. La caché es una comodidad, no un espejo del
  /// catálogo: al pasarse se descartan las entradas más viejas.
  static const int maxEntries = 60;

  static String entryKey({required String keyword, required int page}) =>
      '${keyword.trim().toLowerCase()}|$page';

  @override
  Future<CachedProductPage?> readPage({
    required String keyword,
    required int page,
  }) async {
    final Object? stored = _box.get(entryKey(keyword: keyword, page: page));
    if (stored == null) return null;
    if (stored is! Map) return null;

    final Object? rawSavedAt = stored['savedAt'];
    final Object? rawProducts = stored['products'];
    if (rawSavedAt is! int || rawProducts is! List) return null;

    return CachedProductPage(
      products: rawProducts
          .whereType<Map<dynamic, dynamic>>()
          .map(productFromStored)
          .whereType<Product>()
          .toList(growable: false),
      savedAt: DateTime.fromMillisecondsSinceEpoch(rawSavedAt),
    );
  }

  @override
  Future<void> writePage({
    required String keyword,
    required int page,
    required List<Product> products,
  }) async {
    try {
      await _box.put(entryKey(keyword: keyword, page: page), <String, Object>{
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'products': products.map(productToStored).toList(),
      });
      await _evictOldest();
    } on HiveError catch (error) {
      throw CacheException(
        'No se pudo guardar la página en caché: ${error.message}',
      );
    }
  }

  /// Mantiene el box acotado descartando lo más viejo primero.
  Future<void> _evictOldest() async {
    if (_box.length <= maxEntries) return;

    final List<(Object key, int savedAt)> entries = <(Object, int)>[];
    for (final Object key in _box.keys) {
      final Object? stored = _box.get(key);
      final Object? savedAt = stored is Map ? stored['savedAt'] : null;
      entries.add((key, savedAt is int ? savedAt : 0));
    }
    entries.sort(((Object, int) a, (Object, int) b) => a.$2.compareTo(b.$2));

    await _box.deleteAll(
      entries.take(_box.length - maxEntries).map(((Object, int) e) => e.$1),
    );
  }
}
