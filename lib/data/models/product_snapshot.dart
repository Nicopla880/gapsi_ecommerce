import '../../domain/entities/product.dart';

/// Serialización de un [Product] hacia y desde el almacenamiento local.
///
/// La usan tanto los favoritos como la caché de resultados, así que el formato
/// del snapshot se define una sola vez. Son estructuras nativas de Hive (mapas
/// y primitivos): no hacen falta adaptadores generados.
Map<String, Object?> productToStored(Product product) => <String, Object?>{
  'id': product.id,
  'title': product.title,
  'price': product.price,
  'thumbnailUrl': product.thumbnailUrl,
  'description': product.description,
};

/// Devuelve `null` si el registro no tiene un id usable: sin id no sirve como
/// key de lista ni para comparar favoritos, así que no llega a la UI.
Product? productFromStored(Map<dynamic, dynamic> stored) {
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
