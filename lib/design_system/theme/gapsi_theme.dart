import 'package:flutter/material.dart';

import 'gapsi_colors.dart';
import 'gapsi_radius.dart';
import 'gapsi_spacing.dart';
import 'gapsi_typography.dart';

/// Tema único de GAPSI.
///
/// La app es deliberadamente de un solo tema claro: es preferible un tema bien
/// resuelto a dos a medio terminar. Los tokens ya están centralizados, así que
/// sumar un `dark()` más adelante es agregar un `ColorScheme` y no reescribir
/// widgets.
abstract final class GapsiTheme {
  static ThemeData light() {
    const ColorScheme scheme = GapsiColors.lightScheme;
    final TextTheme textTheme = GapsiTypography.textTheme.apply(
      fontFamily: GapsiTypography.fontFamily,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: GapsiTypography.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: GapsiColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      dividerTheme: const DividerThemeData(
        color: GapsiColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: GapsiColors.blue,
        circularTrackColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GapsiColors.surfaceVariant,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: GapsiColors.textSecondary,
        ),
        prefixIconColor: GapsiColors.textSecondary,
        suffixIconColor: GapsiColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          vertical: GapsiSpacing.md,
          horizontal: GapsiSpacing.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: GapsiRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: GapsiRadius.mdAll,
          borderSide: BorderSide(color: GapsiColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: GapsiRadius.mdAll,
          borderSide: BorderSide(color: GapsiColors.blue, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: GapsiRadius.lgAll,
          side: BorderSide(color: GapsiColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: GapsiSpacing.xl,
            vertical: GapsiSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: GapsiRadius.smAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GapsiColors.blue,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: GapsiRadius.smAll),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GapsiColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(borderRadius: GapsiRadius.smAll),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: GapsiColors.textSecondary,
        titleTextStyle: textTheme.bodyLarge,
        shape: const RoundedRectangleBorder(borderRadius: GapsiRadius.smAll),
      ),
    );
  }
}
