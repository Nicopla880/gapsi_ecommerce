import 'package:flutter/widgets.dart';

/// Duraciones y curvas de las animaciones propias de GAPSI.
///
/// Todas son cortas a propósito: la interfaz debe sentirse inmediata y ninguna
/// animación debe retrasar la lectura de resultados.
abstract final class GapsiMotion {
  /// Cambio de estado del corazón de favoritos.
  static const Duration favorite = Duration(milliseconds: 200);

  /// Entrada de una tarjeta de producto.
  static const Duration entrance = Duration(milliseconds: 260);

  /// Retardo entre tarjetas consecutivas del primer tramo visible.
  static const Duration entranceStagger = Duration(milliseconds: 30);

  /// Cuántas tarjetas escalonan su entrada. Más allá de este índice la tarjeta
  /// aparece sin retardo, para que paginar no se sienta lento.
  static const int entranceStaggerCount = 8;

  /// Transición entre estados de contenido (loading, resultados, vacío, error).
  static const Duration stateChange = Duration(milliseconds: 220);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;

  /// Desplazamiento vertical inicial de la entrada de contenido.
  static const double entranceOffset = 12;

  /// `true` si el sistema pide reducir movimiento. Las animaciones no
  /// esenciales deben resolverse en su estado final de inmediato.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
