import 'product.dart';

/// Snapshot local suficiente para identificar y renderizar favoritos.
class FavoritesCollection {
  FavoritesCollection({
    Iterable<Product> products = const <Product>[],
    Iterable<String> legacyIds = const <String>[],
  }) : products = List<Product>.unmodifiable(_deduplicateProducts(products)),
       legacyIds = Set<String>.unmodifiable(
         legacyIds
             .map((String id) => id.trim())
             .where((String id) => id.isNotEmpty),
       );

  final List<Product> products;

  /// IDs del formato P10. Se conservan hasta reencontrar el producto y poder
  /// completar su snapshot sin inventar datos.
  final Set<String> legacyIds;

  Set<String> get favoriteIds => Set<String>.unmodifiable(<String>{
    ...legacyIds,
    ...products.map((Product product) => product.id),
  });

  bool contains(String productId) => favoriteIds.contains(productId);

  FavoritesCollection setFavorite(Product product, {required bool value}) {
    final List<Product> updatedProducts = List<Product>.of(products);
    final Set<String> updatedLegacyIds = Set<String>.of(legacyIds)
      ..remove(product.id);
    final int existingIndex = updatedProducts.indexWhere(
      (Product current) => current.id == product.id,
    );

    if (value) {
      if (existingIndex >= 0) {
        updatedProducts[existingIndex] = product;
      } else {
        updatedProducts.add(product);
      }
    } else if (existingIndex >= 0) {
      updatedProducts.removeAt(existingIndex);
    }

    return FavoritesCollection(
      products: updatedProducts,
      legacyIds: updatedLegacyIds,
    );
  }
}

List<Product> _deduplicateProducts(Iterable<Product> products) {
  final Map<String, Product> byId = <String, Product>{};
  for (final Product product in products) {
    if (product.id.trim().isNotEmpty) byId[product.id] = product;
  }
  return byId.values.toList(growable: false);
}
