import 'package:equatable/equatable.dart';

/// Error de dominio. Es lo que los repositorios devuelven hacia arriba,
/// ya libre de detalles de transporte o de almacenamiento.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// El servidor respondió con un error.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// No hubo conectividad con el servidor.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Falló el acceso a la caché local.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
