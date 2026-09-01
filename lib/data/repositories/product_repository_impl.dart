import '../../core/errors/exceptions.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_cache_local_datasource.dart';
import '../datasources/remote/walmart_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource, this._cache);

  final WalmartRemoteDataSource _remoteDataSource;
  final ProductCacheLocalDataSource _cache;

  /// Cuánto vale una página cacheada antes de volver a pedirla.
  ///
  /// Es un compromiso: el precio de un producto puede cambiar, así que la caché
  /// no puede durar horas; pero el API tarda varios segundos por request, así
  /// que repetir una búsqueda dentro de la misma sesión no debería costar otra
  /// espera.
  static const Duration cacheTtl = Duration(minutes: 10);

  @override
  Future<List<Product>> searchProducts({
    required String keyword,
    required int page,
  }) async {
    final CachedProductPage? cached = await _readCache(
      keyword: keyword,
      page: page,
    );
    if (cached != null && cached.ageAt(DateTime.now()) < cacheTtl) {
      return cached.products;
    }

    try {
      final List<Product> products = await _remoteDataSource.searchProducts(
        keyword: keyword,
        page: page,
      );
      // Un id vacío significa que el API no lo trajo (ver ProductModel.fromJson).
      // No sirve como key de lista, así que ese producto no llega a la UI.
      final List<Product> usable = products
          .where((Product product) => product.id.isNotEmpty)
          .toList(growable: false);

      await _writeCache(keyword: keyword, page: page, products: usable);
      return usable;
    } on ServerException {
      // Una caché vencida sigue siendo mejor que una pantalla de error: se
      // sirve como último recurso, nunca por delante de una respuesta fresca.
      final List<Product>? fallback = cached?.products;
      if (fallback != null) return fallback;
      rethrow;
    } on NetworkException {
      final List<Product>? fallback = cached?.products;
      if (fallback != null) return fallback;
      rethrow;
    } catch (error) {
      // Nada que no sea del vocabulario de core/errors cruza hacia el domain.
      throw ServerException('Error inesperado al buscar productos: $error');
    }
  }

  /// La caché es una optimización: si falla, la búsqueda sigue su curso contra
  /// el API en lugar de romper.
  Future<CachedProductPage?> _readCache({
    required String keyword,
    required int page,
  }) async {
    try {
      return await _cache.readPage(keyword: keyword, page: page);
    } on CacheException {
      return null;
    }
  }

  Future<void> _writeCache({
    required String keyword,
    required int page,
    required List<Product> products,
  }) async {
    try {
      await _cache.writePage(keyword: keyword, page: page, products: products);
    } on CacheException {
      // Sin caché la app funciona igual; no es motivo para fallar la búsqueda.
    }
  }
}
