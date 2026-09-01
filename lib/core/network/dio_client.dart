import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

/// Envoltorio delgado sobre [Dio]: centraliza baseUrl, headers, timeouts y la
/// traducción de [DioException] a las excepciones propias del proyecto, para
/// que los datasources no tengan que conocer nada de Dio.
class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      responseType: ResponseType.json,
      headers: <String, String>{
        ApiConstants.apiKeyHeader: ApiConstants.apiKey,
        ApiConstants.apiHostHeader: ApiConstants.apiHost,
      },
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false,
          compact: true,
        ),
      );
    }
  }

  final Dio _dio;

  /// Acceso directo al [Dio] subyacente, útil en tests y para casos puntuales.
  Dio get dio => _dio;

  /// GET tipado. Lanza [NetworkException] o [ServerException]; nunca [DioException].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  /// Traduce un [DioException] a las excepciones de `core/errors`.
  ///
  /// Es estático y público a propósito: los datasources que reciben un [Dio]
  /// crudo lo reutilizan en vez de duplicar el mapeo.
  static Exception mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('Se agotó el tiempo de espera.');
      case DioExceptionType.connectionError:
        return const NetworkException('No hay conexión con el servidor.');
      case DioExceptionType.badCertificate:
        return const NetworkException('Certificado del servidor inválido.');
      case DioExceptionType.cancel:
        return const NetworkException('La petición fue cancelada.');
      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        return ServerException(
          'El servidor respondió ${statusCode ?? 'un error desconocido'}.',
        );
      case DioExceptionType.unknown:
        return ServerException(error.message ?? 'Error inesperado de red.');
    }
  }
}
