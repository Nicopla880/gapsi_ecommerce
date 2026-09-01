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

  /// Compatibilidad con shapes históricos distintos del contrato validado.
  static const List<String> _listKeys = <String>[
    'items',
    'products',
    'results',
  ];

  static const String _validatedCollectionPath =
      'item.props.pageProps.initialData.searchResult.itemStacks';

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
    // Compatibilidad con respuestas históricas que devolvían el array raíz.
    if (data is List) return _toModels(data);

    if (data is! Map) {
      throw ServerException(
        'Se esperaba un objeto JSON y llegó ${data.runtimeType}.',
      );
    }

    if (data.containsKey('item')) {
      return _parseValidatedResponse(data['item']);
    }

    for (final String key in _listKeys) {
      final Object? value = data[key];
      if (value is List) return _toModels(value);
    }

    // Mensaje pensado para debug rápido cuando el shape real no coincida.
    throw ServerException(
      'No se encontró la colección validada $_validatedCollectionPath ni los '
      'fallbacks ${_listKeys.join(", ")}. Keys top-level recibidas: '
      '${data.keys.join(", ")}.',
    );
  }

  List<ProductModel> _parseValidatedResponse(Object? item) {
    final Map<dynamic, dynamic>? itemMap = _asMap(item);
    final Map<dynamic, dynamic>? props = _asMap(itemMap?['props']);
    final Map<dynamic, dynamic>? pageProps = _asMap(props?['pageProps']);
    final Map<dynamic, dynamic>? initialData = _asMap(
      pageProps?['initialData'],
    );
    final Map<dynamic, dynamic>? searchResult = _asMap(
      initialData?['searchResult'],
    );
    final Object? rawStacks = searchResult?['itemStacks'];

    if (rawStacks is! List) {
      throw ServerException(
        'La respuesta de búsqueda no contiene una lista en '
        '$_validatedCollectionPath.',
      );
    }

    final List<dynamic> rawProducts = <dynamic>[];
    for (final dynamic rawStack in rawStacks) {
      final Map<dynamic, dynamic>? stack = _asMap(rawStack);
      if (stack == null || stack['layoutEnum'] != 'GRID') continue;

      final Object? rawItems = stack['items'];
      if (rawItems is! List) {
        throw const ServerException(
          'Un stack GRID válido no contiene una lista de items.',
        );
      }
      rawProducts.addAll(rawItems);
    }

    return rawProducts
        .whereType<Map<String, dynamic>>()
        .where((Map<String, dynamic> item) => item['__typename'] == 'Product')
        .map(ProductModel.fromJson)
        .toList(growable: false);
  }

  /// Descarta los items que no sean objetos JSON en vez de romper la lista.
  List<ProductModel> _toModels(List<dynamic> raw) => raw
      .whereType<Map<String, dynamic>>()
      .map(ProductModel.fromJson)
      .toList(growable: false);
}

Map<dynamic, dynamic>? _asMap(Object? value) =>
    value is Map<dynamic, dynamic> ? value : null;
