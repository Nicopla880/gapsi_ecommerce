import '../../domain/entities/product.dart';

/// Traduce un item de la respuesta de búsqueda a un [Product].
///
/// El contrato de búsqueda de Axesso validado expone `usItemId`, `name`,
/// `priceInfo.linePrice`, `image` y `description`. Los aliases posteriores se
/// conservan solo como compatibilidad defensiva con otros shapes de Walmart.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    super.price,
    super.thumbnailUrl,
    super.description,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      // `id` y `title` no son nullable en la entity. Si el API no los trae,
      // caen a string vacío y el repositorio descarta el item sin identidad.
      id: _pickString(json, const <String>[
        'usItemId',
        'id',
        'itemId',
        'productId',
      ]),
      title: _pickString(json, const <String>['name', 'title', 'productName']),
      price: _pickPositiveDouble(json, const <String>[
        'priceInfo.linePrice',
        'priceInfo.minPrice',
        'price',
        'priceInfo.currentPrice.price',
        'currentPrice.price',
        'priceInfo.currentPrice',
        'salePrice',
      ]),
      thumbnailUrl: _pickStringOrNull(json, const <String>[
        'image',
        'imageInfo.thumbnailUrl',
        'thumbnailImage',
        'thumbnailUrl',
        'imageInfo.allImages.0.url',
        'imageUrl',
      ]),
      description: _pickStringOrNull(json, const <String>[
        'description',
        'shortDescription',
        'longDescription',
      ]),
    );
  }
}

/// Recorre [path] (con puntos para anidar, e índices numéricos para listas:
/// `imageInfo.allImages.0.url`) y devuelve el valor, o `null` si el camino se
/// corta en cualquier punto.
Object? _read(Map<String, dynamic> json, String path) {
  Object? current = json;
  for (final String segment in path.split('.')) {
    if (current is Map && current.containsKey(segment)) {
      current = current[segment];
    } else if (current is List) {
      final int? index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) return null;
      current = current[index];
    } else {
      return null;
    }
  }
  return current;
}

/// Primer valor de [paths] convertible a un string no vacío.
String? _pickStringOrNull(Map<String, dynamic> json, List<String> paths) {
  for (final String path in paths) {
    final Object? value = _read(json, path);
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num || value is bool) return value.toString();
  }
  return null;
}

/// Igual que [_pickStringOrNull] pero para los campos no nullable de la entity.
String _pickString(Map<String, dynamic> json, List<String> paths) =>
    _pickStringOrNull(json, paths) ?? '';

/// Primer precio positivo de [paths]. Axesso usa strings con símbolo para el
/// precio visible y devuelve ceros junto con strings vacíos cuando no dispone
/// de precio; en ese caso la entity recibe `null`, no un engañoso "$0.00".
double? _pickPositiveDouble(Map<String, dynamic> json, List<String> paths) {
  for (final String path in paths) {
    final Object? value = _read(json, path);
    if (value is num && value > 0) return value.toDouble();
    if (value is String) {
      final double? parsed = double.tryParse(
        value.replaceAll(RegExp(r'[^0-9.\-]'), ''),
      );
      if (parsed != null && parsed > 0) return parsed;
    }
  }
  return null;
}
