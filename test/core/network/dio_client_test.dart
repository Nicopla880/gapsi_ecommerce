import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/network/dio_client.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

void main() {
  PrettyDioLogger loggerFrom(Dio dio) {
    return dio.interceptors.whereType<PrettyDioLogger>().single;
  }

  test('el logger de red deshabilita request y response headers', () {
    final Dio dio = Dio();
    DioClient(dio: dio);

    final PrettyDioLogger logger = loggerFrom(dio);

    expect(logger.requestHeader, isFalse);
    expect(logger.responseHeader, isFalse);
    expect(logger.request, isTrue);
    expect(logger.error, isTrue);
  });

  test('el log conserva metadata útil sin valores sensibles', () {
    final Dio dio = Dio();
    DioClient(dio: dio);
    final PrettyDioLogger logger = loggerFrom(dio);
    final List<String> logs = <String>[];
    final RequestOptions request = RequestOptions(
      baseUrl: 'https://example.test',
      path: '/search',
      method: 'GET',
      queryParameters: const <String, String>{'keyword': 'gaming'},
      headers: const <String, String>{
        'x-rapidapi-key': 'test-api-secret',
        'authorization': 'test-authorization-secret',
        'cookie': 'test-cookie-secret',
      },
    );

    runZoned(
      () {
        logger.onRequest(request, RequestInterceptorHandler());
        logger.onResponse(
          Response<void>(
            requestOptions: request,
            statusCode: 200,
            headers: Headers.fromMap(<String, List<String>>{
              'set-cookie': <String>['test-set-cookie-secret'],
            }),
          ),
          ResponseInterceptorHandler(),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          logs.add(line);
        },
      ),
    );

    final String output = logs.join('\n').toLowerCase();
    expect(output, contains('request ║ get'));
    expect(output, contains('/search?keyword=gaming'));
    expect(output, contains('status: 200'));
    expect(output, isNot(contains('test-api-secret')));
    expect(output, isNot(contains('test-authorization-secret')));
    expect(output, isNot(contains('test-cookie-secret')));
    expect(output, isNot(contains('test-set-cookie-secret')));
  });
}
