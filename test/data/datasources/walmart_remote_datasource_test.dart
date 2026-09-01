import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/errors/exceptions.dart';
import 'package:gapsi_ecommerce/data/datasources/remote/walmart_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  Object? loadValidatedFixture() => jsonDecode(
    File('test/fixtures/walmart_search_response.json').readAsStringSync(),
  );

  group('WalmartRemoteDataSourceImpl', () {
    late _MockDio dio;
    late WalmartRemoteDataSourceImpl ds;
    setUp(() {
      dio = _MockDio();
      ds = WalmartRemoteDataSourceImpl(dio);
    });
    Future<void> stub(Object? data) async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: data,
          requestOptions: RequestOptions(path: '/x'),
        ),
      );
    }

    test('parsea el contrato real bajo item y solo toma el GRID', () async {
      await stub(loadValidatedFixture());

      final result = await ds.searchProducts(keyword: 'nintendo', page: 1);

      expect(result, hasLength(2));
      expect(result.first.id, '927771478');
      expect(result.first.title, 'Nintendo Switch Lite - Blue');
      expect(result.first.price, 132.30);
      expect(
        result.first.thumbnailUrl,
        'https://i5.walmartimages.com/asr/example-1.jpeg',
      );
      expect(result.first.description, 'Portable Nintendo console');
      expect(result.last.price, isNull);
      expect(result.last.thumbnailUrl, isNull);
      expect(result.last.description, isNull);
      expect(result.map((product) => product.id), isNot(contains('999999999')));
    });

    test('acepta itemStacks vacío como resultado válido vacío', () async {
      await stub(<String, dynamic>{
        'item': <String, dynamic>{
          'props': <String, dynamic>{
            'pageProps': <String, dynamic>{
              'initialData': <String, dynamic>{
                'searchResult': <String, dynamic>{'itemStacks': <dynamic>[]},
              },
            },
          },
        },
      });

      expect(await ds.searchProducts(keyword: 'no-results', page: 1), isEmpty);
    });

    test('item con contrato incompleto produce ServerException', () async {
      await stub(<String, dynamic>{'item': <String, dynamic>{}});

      await expectLater(
        ds.searchProducts(keyword: 'tv', page: 1),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            contains(
              'item.props.pageProps.initialData.searchResult.itemStacks',
            ),
          ),
        ),
      );
    });

    for (final key in <String>['items', 'products', 'results']) {
      test('encuentra el array bajo "$key"', () async {
        await stub(<String, dynamic>{
          key: <dynamic>[
            <String, dynamic>{'name': 'X'},
          ],
        });
        final r = await ds.searchProducts(keyword: 'tv', page: 1);
        expect(r.single.title, 'X');
      });
    }
    test('array pelado en la raíz', () async {
      await stub(<dynamic>[
        <String, dynamic>{'name': 'Y'},
      ]);
      expect(
        (await ds.searchProducts(keyword: 'tv', page: 1)).single.title,
        'Y',
      );
    });
    test(
      'sin key conocida: ServerException listando las keys recibidas',
      () async {
        await stub(<String, dynamic>{'data': 1, 'meta': 2});
        await expectLater(
          ds.searchProducts(keyword: 'tv', page: 1),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('items, products, results'),
                contains('data, meta'),
              ),
            ),
          ),
        );
      },
    );
    test('DioException de red se traduce a NetworkException', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        ds.searchProducts(keyword: 'tv', page: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
