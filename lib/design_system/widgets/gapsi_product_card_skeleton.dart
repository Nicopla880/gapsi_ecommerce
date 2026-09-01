import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/gapsi_colors.dart';
import '../theme/gapsi_radius.dart';
import '../theme/gapsi_spacing.dart';

/// Placeholder de una tarjeta de producto durante la carga inicial.
///
/// Reproduce la caja de la tarjeta real —panel de imagen arriba, dos líneas de
/// título y el precio abajo— para que la llegada de resultados no mueva el
/// layout. El marco queda fuera del shimmer: solo laten los bloques de
/// contenido, así la tarjeta se lee como una tarjeta y no como una mancha.
class GapsiProductCardSkeleton extends StatelessWidget {
  const GapsiProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: GapsiRadius.lgAll,
        border: Border.all(color: GapsiColors.border),
      ),
      child: Shimmer.fromColors(
        baseColor: GapsiColors.surfaceVariant,
        highlightColor: GapsiColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(GapsiSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const <Widget>[
              Expanded(child: _SkeletonBox()),
              SizedBox(height: GapsiSpacing.md),
              _SkeletonBox(height: 12),
              SizedBox(height: GapsiSpacing.sm),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.65,
                child: _SkeletonBox(height: 12),
              ),
              SizedBox(height: GapsiSpacing.lg),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.42,
                child: _SkeletonBox(height: 18),
              ),
              SizedBox(height: GapsiSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: GapsiColors.surfaceVariant,
        borderRadius: GapsiRadius.smAll,
      ),
    );
  }
}
