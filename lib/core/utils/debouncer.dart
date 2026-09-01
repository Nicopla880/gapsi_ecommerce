import 'dart:async';

import 'package:flutter/foundation.dart';

/// Agrupa ráfagas de llamadas en una sola: cada [run] reinicia la cuenta y solo
/// se ejecuta la última acción tras [delay] de silencio.
///
/// Pensado para el campo de búsqueda, así no se dispara un request por tecla.
/// Quien lo crea es responsable de llamar a [dispose].
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;
  Timer? _timer;

  /// `true` si hay una acción esperando ejecutarse.
  bool get isPending => _timer?.isActive ?? false;

  /// Programa [action], descartando la acción pendiente anterior si la hubiera.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Descarta la acción pendiente sin ejecutarla.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Libera el timer. Después de llamarlo, el debouncer no debe reutilizarse.
  void dispose() => cancel();
}
