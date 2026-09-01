import '../entities/product.dart';

/// Acceso a productos. La implementación vive en `data/repositories/`.
abstract class ProductRepository {
  /// Busca productos que coincidan con [keyword], paginando por [page]
  /// (la primera página es la 1).
  ///
  /// Devuelve una lista vacía cuando la búsqueda no arroja resultados: eso es
  /// un caso de éxito, no un error.
  ///
  /// Lanza:
  /// - `ServerException` si el API responde con un estado o cuerpo inesperado.
  /// - `NetworkException` si no hay conectividad o se agota el timeout.
  ///
  /// Ambas están definidas en `core/errors/exceptions.dart`. La capa de
  /// presentación las traduce a los `Failure` de `core/errors/failures.dart`.
  Future<List<Product>> searchProducts({
    required String keyword,
    required int page,
  });
}
