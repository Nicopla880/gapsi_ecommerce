import 'package:flutter/material.dart';

import '../theme/gapsi_colors.dart';
import '../theme/gapsi_motion.dart';

/// Botón de favorito de GAPSI.
///
/// Al cambiar el estado el corazón da un pulso corto de escala (1.0 → 1.16 →
/// 1.0). Se anima ante el cambio de estado y no ante el tap, así que si una
/// escritura falla y el notifier revierte el favorito, el pulso acompaña la
/// reversión en lugar de mentir sobre el resultado.
class GapsiFavoriteButton extends StatefulWidget {
  const GapsiFavoriteButton({
    required this.isFavorite,
    required this.onPressed,
    this.filled = false,
    this.filledIconKey,
    this.outlineIconKey,
    super.key,
  });

  final bool isFavorite;

  /// `null` deshabilita el botón mientras los favoritos no están listos.
  final VoidCallback? onPressed;

  /// `true` dibuja el botón sobre un fondo de marca, para usarlo encima de la
  /// imagen del producto. `false` lo deja plano, para barras de aplicación.
  final bool filled;

  final Key? filledIconKey;
  final Key? outlineIconKey;

  @override
  State<GapsiFavoriteButton> createState() => _GapsiFavoriteButtonState();
}

class _GapsiFavoriteButtonState extends State<GapsiFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GapsiMotion.favorite,
  );

  late final Animation<double> _scale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 1.16,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 45,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1.16,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 55,
        ),
      ]).animate(_controller);

  @override
  void didUpdateWidget(GapsiFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite &&
        !GapsiMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = widget.isFavorite
        ? GapsiColors.navy
        : theme.colorScheme.onSurfaceVariant;

    final Widget icon = ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.isFavorite ? Icons.favorite : Icons.favorite_border,
        key: widget.isFavorite ? widget.filledIconKey : widget.outlineIconKey,
        color: widget.onPressed == null ? null : foreground,
      ),
    );

    final String tooltip = widget.isFavorite
        ? 'Remove from favorites'
        : 'Add to favorites';

    if (!widget.filled) {
      return IconButton(
        tooltip: tooltip,
        onPressed: widget.onPressed,
        icon: icon,
      );
    }

    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: widget.onPressed,
      style: IconButton.styleFrom(
        backgroundColor: widget.isFavorite
            ? GapsiColors.blueSoft
            : GapsiColors.surface.withValues(alpha: 0.92),
        highlightColor: GapsiColors.blueSoft,
      ),
      icon: icon,
    );
  }
}
