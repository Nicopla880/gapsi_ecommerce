import 'package:flutter/material.dart';

/// Paleta de marca de GAPSI.
///
/// Los valores nacen del icono de la app (`assets/branding/app_icon.png`): el
/// azul marino profundo domina el fondo del logo y el azul claro viene del
/// trazo del isotipo. El resto son neutros azulados derivados de esos dos para
/// que toda la interfaz se lea como una sola familia.
abstract final class GapsiColors {
  /// Azul GAPSI profundo. Ancla de marca: logo, textos jerárquicos y estados
  /// seleccionados sobre superficies claras de marca.
  static const Color navy = Color(0xFF08185D);

  /// Azul de marca más brillante. Es el color interactivo: foco, indicadores,
  /// botones rellenos y el precio.
  static const Color blue = Color(0xFF2456D6);

  /// Azul claro del isotipo. Contenedores de marca y fondo del botón favorito.
  static const Color blueSoft = Color(0xFFC3DAFA);

  /// Fondo de la app: gris azulado muy claro para que las tarjetas blancas
  /// recorten sin necesidad de sombras pesadas.
  static const Color background = Color(0xFFF4F6FC);

  static const Color surface = Color(0xFFFFFFFF);

  /// Superficie secundaria: campo de búsqueda, marcos de imagen, skeletons.
  static const Color surfaceVariant = Color(0xFFEDF1F8);

  /// Texto principal: casi negro con tinte navy, no gris puro.
  static const Color textPrimary = Color(0xFF101A33);

  /// Texto secundario. Contraste 5.4:1 sobre blanco, apto para cuerpo de texto.
  static const Color textSecondary = Color(0xFF5C6780);

  static const Color border = Color(0xFFE1E7F3);

  static const Color error = Color(0xFFBA1A1A);

  /// [ColorScheme] claro de GAPSI.
  ///
  /// Se define a mano en lugar de `fromSeed` porque el armonizador de Material
  /// desplaza el azul del logo hacia tonos que ya no son los de la marca.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: blue,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: blueSoft,
    onPrimaryContainer: navy,
    secondary: navy,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: blueSoft,
    onSecondaryContainer: navy,
    tertiary: navy,
    onTertiary: Color(0xFFFFFFFF),
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    surfaceContainerLowest: background,
    surfaceContainerLow: Color(0xFFF7F9FD),
    surfaceContainer: surfaceVariant,
    surfaceContainerHigh: surfaceVariant,
    surfaceContainerHighest: surfaceVariant,
    outline: Color(0xFF9AA5BD),
    outlineVariant: border,
  );
}
