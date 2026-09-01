import 'package:equatable/equatable.dart';

/// Producto tal como lo entiende la app, ya independiente del formato del API.
///
/// La respuesta de Walmart no siempre pobla todos los campos, así que los que
/// pueden faltar son nullable a propósito: es preferible que la UI decida qué
/// mostrar ante un dato ausente a inventar un default engañoso (un precio 0.0
/// se leería como "gratis", una descripción vacía como "sin descripción").
class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    this.price,
    this.thumbnailUrl,
    this.description,
  });

  final String id;
  final String title;

  /// Precio en la moneda que devuelve el API. `null` si no vino informado.
  final double? price;

  final String? thumbnailUrl;
  final String? description;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    price,
    thumbnailUrl,
    description,
  ];
}
