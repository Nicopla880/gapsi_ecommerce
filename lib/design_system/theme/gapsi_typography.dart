import 'package:flutter/material.dart';

import 'gapsi_colors.dart';

/// Tipografía de GAPSI.
///
/// Manrope va empaquetada en `assets/fonts` en cuatro pesos estáticos (400,
/// 600, 700 y 800), que son exactamente los que usa el tema. No se agregan más
/// variantes ni cursivas porque la interfaz no las utiliza.
///
/// Los roles de Material se asignan a un uso concreto de la app para que los
/// widgets tomen el estilo del tema en lugar de recalcular pesos a mano:
///
/// - `headlineMedium`: precio en el detalle.
/// - `headlineSmall`: título del producto en el detalle.
/// - `titleLarge`: títulos de sección, app bar y estados vacíos.
/// - `titleMedium`: precio en la tarjeta.
/// - `titleSmall`: título del producto en la tarjeta.
/// - `bodyLarge`: descripción.
/// - `bodyMedium`: texto corriente.
/// - `bodySmall`: metadatos secundarios.
/// - `labelLarge`: botones y navegación de descubrimiento.
abstract final class GapsiTypography {
  static const String fontFamily = 'Manrope';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  static const TextTheme textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontSize: 26,
      height: 1.2,
      fontWeight: extraBold,
      letterSpacing: -0.6,
      color: GapsiColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      height: 1.25,
      fontWeight: bold,
      letterSpacing: -0.4,
      color: GapsiColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      height: 1.3,
      fontWeight: bold,
      letterSpacing: -0.2,
      color: GapsiColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      height: 1.25,
      fontWeight: extraBold,
      letterSpacing: -0.3,
      color: GapsiColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: bold,
      letterSpacing: -0.1,
      color: GapsiColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      height: 1.55,
      fontWeight: regular,
      color: GapsiColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.45,
      fontWeight: regular,
      color: GapsiColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      height: 1.4,
      fontWeight: regular,
      color: GapsiColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: semiBold,
      letterSpacing: 0.1,
      color: GapsiColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      height: 1.2,
      fontWeight: semiBold,
      color: GapsiColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: semiBold,
      color: GapsiColors.textSecondary,
    ),
  );
}
