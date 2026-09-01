import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/errors/exceptions.dart';
import 'package:gapsi_ecommerce/data/datasources/remote/walmart_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  group('WalmartRemoteDataSourceImpl', () {
    late _MockDio dio;
    late WalmartRemoteDataSourceImpl ds;
    setUp(() {
      dio = _MockDio();
      ds = WalmartRemoteDataSourceImpl(dio);
    });
    Future<void> stub(Object? data) async {
      when(() => dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response<dynamic>(
              data: data, requestOptions: RequestOptions(path: '/x')));
    }

    for (final key in <String>['items', 'products', 'results']) {
      test('encuentra el array bajo "$key"', () async {
        await stub(<String, dynamic>{key: <dynamic>[<String, dynamic>{'name': 'X'}]});
        final r = await ds.searchProducts(keyword: 'tv', page: 1);
        expect(r.single.title, 'X');
      });
    }
    test('array pelado en la raíz', () async {
      await stub(<dynamic>[<String, dynamic>{'name': 'Y'}]);
      expect((await ds.searchProducts(keyword: 'tv', page: 1)).single.title, 'Y');
    });
    test('sin key conocida: ServerException listando las keys recibidas', () async {
      await stub(<String, dynamic>{'data': 1, 'meta': 2});
      await expectLater(
        ds.searchProducts(keyword: 'tv', page: 1),
        throwsA(isA<ServerException>().having((e) => e.message, 'message',
            allOf(contains('items, products, results'), contains('data, meta')))),
      );
    });
    test('DioException de red se traduce a NetworkException', () async {
      when(() => dio.get<dynamic>(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/x'),
              type: DioExceptionType.connectionError));
      await expectLater(ds.searchProducts(keyword: 'tv', page: 1),
          throwsA(isA<NetworkException>()));
    });
  });
}
