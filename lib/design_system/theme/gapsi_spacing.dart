/// Escala de espaciado de GAPSI, en múltiplos de 4.
///
/// Cubre el ritmo vertical y los paddings de la app. No pretende reemplazar
/// cada número del layout: las medidas que responden a una restricción concreta
/// (alto de una fila del header, inset del sistema) siguen viviendo donde se
/// calculan.
abstract final class GapsiSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}
