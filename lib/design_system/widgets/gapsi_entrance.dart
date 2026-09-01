import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/gapsi_motion.dart';

/// Entrada sutil de contenido: un fundido corto con un desplazamiento hacia
/// arriba de unos pocos píxeles.
///
/// Anima una sola vez, al montarse. Como las tarjetas ya montadas conservan su
/// elemento cuando se agrega una página nueva, paginar solo anima las tarjetas
/// recién agregadas y nunca repite la entrada de la grilla completa.
class GapsiEntrance extends StatefulWidget {
  const GapsiEntrance({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  /// Retardo escalonado para la posición [index] de una lista.
  ///
  /// Solo escalona el primer tramo visible; a partir de ahí el retardo es cero
  /// para que las páginas siguientes aparezcan de inmediato.
  static Duration staggerFor(int index) {
    if (index >= GapsiMotion.entranceStaggerCount) return Duration.zero;
    return GapsiMotion.entranceStagger * index;
  }

  @override
  State<GapsiEntrance> createState() => _GapsiEntranceState();
}

class _GapsiEntranceState extends State<GapsiEntrance> {
  bool _started = false;
  bool _visible = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (GapsiMotion.reduced(context)) {
      _visible = true;
      return;
    }
    if (widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    } else {
      _timer = Timer(widget.delay, _reveal);
    }
  }

  void _reveal() {
    if (mounted) setState(() => _visible = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: GapsiMotion.entrance,
      curve: GapsiMotion.standard,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: GapsiMotion.entrance,
        curve: GapsiMotion.standard,
        child: widget.child,
      ),
    );
  }
}
