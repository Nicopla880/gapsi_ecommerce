import '../../core/errors/exceptions.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/remote/walmart_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remoteDataSource);

  final WalmartRemoteDataSource _remoteDataSource;

  @override
  Future<List<Product>> searchProducts({
    required String keyword,
    required int page,
  }) async {
    try {
      final List<Product> products = await _remoteDataSource.searchProducts(
        keyword: keyword,
        page: page,
      );
      // Un id vacío significa que el API no lo trajo (ver ProductModel.fromJson).
      // No sirve como key de lista, así que ese producto no llega a la UI.
      return products
          .where((Product product) => product.id.isNotEmpty)
          .toList(growable: false);
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (error) {
      // Nada que no sea del vocabulario de core/errors cruza hacia el domain.
      throw ServerException('Error inesperado al buscar productos: $error');
    }
  }
}
