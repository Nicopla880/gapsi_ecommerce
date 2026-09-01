import 'package:flutter/widgets.dart';

/// Radios de esquina de GAPSI.
///
/// Cuatro pasos alcanzan para que las pantallas se lean como un sistema: el
/// contenido interno usa radios menores que la superficie que lo contiene.
abstract final class GapsiRadius {
  /// Chips, botones y el marco de imagen dentro de una tarjeta.
  static const double sm = 12;

  /// Campo de búsqueda y logo.
  static const double md = 16;

  /// Tarjetas de producto y superficies de feedback.
  static const double lg = 20;

  /// Superficies grandes, como la imagen del detalle.
  static const double xl = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}
