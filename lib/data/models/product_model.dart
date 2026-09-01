import '../../domain/entities/product.dart';

/// Traduce un item de la respuesta de búsqueda a un [Product].
///
/// ⚠️ El shape del endpoint de búsqueda **todavía no está validado contra la
/// API real**. Lo de acá abajo es la mejor estimación a partir del shape
/// confirmado del producto individual de Walmart (`name`,
/// `priceInfo.currentPrice.price`, `imageInfo.thumbnailUrl`).
///
/// Por eso el parseo es defensivo: cada campo prueba varios nombres y varios
/// niveles de anidamiento, y ante la duda devuelve `null` en vez de lanzar. Un
/// producto con un campo faltante se muestra incompleto, pero no rompe la
/// búsqueda entera. Cuando se confirme la respuesta real, alcanza con podar los
/// alias sobrantes de las listas de rutas.
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
      // caen a string vacío: la UI puede filtrarlos, pero el parseo no rompe.
      id: _pickString(json, const <String>[
        'itemId',
        'productId',
        'usItemId',
        'id',
      ]),
      title: _pickString(json, const <String>[
        'name',
        'title',
        'productName',
      ]),
      price: _pickDouble(json, const <String>[
        'price',
        'priceInfo.currentPrice.price',
        'currentPrice.price',
        'priceInfo.currentPrice',
        'salePrice',
      ]),
      thumbnailUrl: _pickStringOrNull(json, const <String>[
        'thumbnailImage',
        'thumbnailUrl',
        'imageInfo.thumbnailUrl',
        'imageInfo.allImages.0.url',
        'image',
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

/// Primer valor de [paths] convertible a double. Tolera números como string
/// ("12.99", "$12.99") porque no está confirmado cómo los serializa el API.
double? _pickDouble(Map<String, dynamic> json, List<String> paths) {
  for (final String path in paths) {
    final Object? value = _read(json, path);
    if (value is num) return value.toDouble();
    if (value is String) {
      final double? parsed = double.tryParse(
        value.replaceAll(RegExp(r'[^0-9.\-]'), ''),
      );
      if (parsed != null) return parsed;
    }
  }
  return null;
}
