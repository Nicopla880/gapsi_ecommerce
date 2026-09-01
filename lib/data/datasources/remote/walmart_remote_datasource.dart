import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/dio_client.dart';
import '../../models/product_model.dart';

/// Acceso al endpoint de búsqueda de Axesso Walmart Data Service.
abstract class WalmartRemoteDataSource {
  Future<List<ProductModel>> searchProducts({
    required String keyword,
    required int page,
  });
}

class WalmartRemoteDataSourceImpl implements WalmartRemoteDataSource {
  const WalmartRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  /// Nombres candidatos del array de productos, en orden de preferencia.
  /// Pendiente de confirmar contra la respuesta real del API.
  static const List<String> _listKeys = <String>['items', 'products', 'results'];

  @override
  Future<List<ProductModel>> searchProducts({
    required String keyword,
    required int page,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        ApiConstants.searchEndpoint,
        queryParameters: <String, dynamic>{
          'keyword': keyword,
          'page': page,
          'sortBy': ApiConstants.defaultSortBy,
        },
      );
    } on DioException catch (error) {
      throw DioClient.mapDioError(error);
    }
    return _parseProducts(response.data);
  }

  List<ProductModel> _parseProducts(Object? data) {
    // Algunos endpoints devuelven el array pelado en la raíz.
    if (data is List) return _toModels(data);

    if (data is! Map) {
      throw ServerException(
        'Se esperaba un objeto JSON y llegó ${data.runtimeType}.',
      );
    }

    for (final String key in _listKeys) {
      final Object? value = data[key];
      if (value is List) return _toModels(value);
    }

    // Mensaje pensado para debug rápido cuando el shape real no coincida.
    throw ServerException(
      'No se encontró el array de productos. Se probaron: '
      '${_listKeys.join(", ")}. Keys top-level recibidas: '
      '${data.keys.join(", ")}.',
    );
  }

  /// Descarta los items que no sean objetos JSON en vez de romper la lista.
  List<ProductModel> _toModels(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(ProductModel.fromJson)
      .toList(growable: false);
}
