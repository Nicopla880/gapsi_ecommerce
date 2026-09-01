/// Excepciones de bajo nivel lanzadas por los datasources.
///
/// Nunca cruzan hacia la capa de presentación: los repositorios de
/// `data/repositories/` las traducen a los `Failure` de `failures.dart`.
library;

/// El servidor respondió, pero con un estado o cuerpo inesperado.
class ServerException implements Exception {
  const ServerException([this.message]);

  final String? message;

  @override
  String toString() => 'ServerException(${message ?? 'sin detalle'})';
}

/// No se pudo alcanzar al servidor: sin conexión, timeout o DNS caído.
class NetworkException implements Exception {
  const NetworkException([this.message]);

  final String? message;

  @override
  String toString() => 'NetworkException(${message ?? 'sin detalle'})';
}

/// Falló la lectura o escritura del almacenamiento local.
class CacheException implements Exception {
  const CacheException([this.message]);

  final String? message;

  @override
  String toString() => 'CacheException(${message ?? 'sin detalle'})';
}
