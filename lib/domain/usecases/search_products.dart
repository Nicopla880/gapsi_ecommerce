import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Busca productos por palabra clave.
class SearchProducts {
  const SearchProducts(this._repository);

  final ProductRepository _repository;

  /// Ver `ProductRepository.searchProducts` para el contrato y los errores.
  Future<List<Product>> call({required String keyword, required int page}) {
    return _repository.searchProducts(keyword: keyword, page: page);
  }
}
