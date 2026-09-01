import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/errors/exceptions.dart';
import 'package:gapsi_ecommerce/data/datasources/local/product_cache_local_datasource.dart';
import 'package:gapsi_ecommerce/data/datasources/remote/walmart_remote_datasource.dart';
import 'package:gapsi_ecommerce/data/models/product_model.dart';
import 'package:gapsi_ecommerce/data/repositories/product_repository_impl.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock implements WalmartRemoteDataSource {}

const List<ProductModel> _remoteResponse = <ProductModel>[
  ProductModel(id: '123', title: 'Nintendo Switch', price: 299.99),
];

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late _MockRemoteDataSource remote;
  late ProductRepositoryImpl repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('gapsi_cache_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    box = await Hive.openBox<dynamic>(ProductCacheLocalDataSourceImpl.boxName);
    await box.clear();
    remote = _MockRemoteDataSource();
    repository = ProductRepositoryImpl(
      remote,
      ProductCacheLocalDataSourceImpl(box),
    );
  });

  void stubRemote(List<ProductModel> products) {
    when(
      () => remote.searchProducts(
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => products);
  }

  void stubRemoteFailure(Object error) {
    when(
      () => remote.searchProducts(
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
      ),
    ).thenThrow(error);
  }

  /// Escribe una entrada de caché con una antigüedad concreta, para poder
  /// probar el vencimiento sin esperar en tiempo real.
  Future<void> seedCache({
    required String keyword,
    required int page,
    required Duration age,
    List<Map<String, Object?>> products = const <Map<String, Object?>>[
      <String, Object?>{'id': 'cached-1', 'title': 'Desde caché'},
    ],
  }) {
    return box.put(
      ProductCacheLocalDataSourceImpl.entryKey(keyword: keyword, page: page),
      <String, Object>{
        'savedAt': DateTime.now().subtract(age).millisecondsSinceEpoch,
        'products': products,
      },
    );
  }

  test('descarta los productos sin id', () async {
    stubRemote(const <ProductModel>[
      ProductModel(id: '', title: 'Sin id'),
      ProductModel(id: '123', title: 'Con id'),
    ]);

    final List<Product> result = await repository.searchProducts(
      keyword: 'tv',
      page: 1,
    );

    expect(result.map((Product p) => p.id), <String>['123']);
  });

  test('una respuesta exitosa queda cacheada por keyword y página', () async {
    stubRemote(_remoteResponse);

    await repository.searchProducts(keyword: 'Switch', page: 2);

    final Object? stored = box.get(
      ProductCacheLocalDataSourceImpl.entryKey(keyword: 'switch', page: 2),
    );
    expect(stored, isA<Map<dynamic, dynamic>>());
    expect((stored! as Map<dynamic, dynamic>)['products'], hasLength(1));
  });

  test('una página fresca se sirve de la caché sin llamar al API', () async {
    await seedCache(keyword: 'tv', page: 1, age: const Duration(minutes: 1));
    stubRemote(_remoteResponse);

    final List<Product> result = await repository.searchProducts(
      keyword: 'tv',
      page: 1,
    );

    expect(result.map((Product p) => p.id), <String>['cached-1']);
    verifyNever(
      () => remote.searchProducts(
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
      ),
    );
  });

  test('una página vencida se vuelve a pedir al API', () async {
    await seedCache(keyword: 'tv', page: 1, age: const Duration(hours: 2));
    stubRemote(_remoteResponse);

    final List<Product> result = await repository.searchProducts(
      keyword: 'tv',
      page: 1,
    );

    expect(result.map((Product p) => p.id), <String>['123']);
    verify(() => remote.searchProducts(keyword: 'tv', page: 1)).called(1);
  });

  test('si el API falla, una caché vencida es mejor que un error', () async {
    await seedCache(keyword: 'tv', page: 1, age: const Duration(hours: 2));
    stubRemoteFailure(const NetworkException('sin conexión'));

    final List<Product> result = await repository.searchProducts(
      keyword: 'tv',
      page: 1,
    );

    expect(result.map((Product p) => p.id), <String>['cached-1']);
  });

  test('sin caché, el error del API se propaga', () async {
    stubRemoteFailure(const NetworkException('sin conexión'));

    expect(
      () => repository.searchProducts(keyword: 'tv', page: 1),
      throwsA(isA<NetworkException>()),
    );
  });

  test('la caché no crece sin límite', () async {
    stubRemote(_remoteResponse);

    for (
      int page = 1;
      page <= ProductCacheLocalDataSourceImpl.maxEntries + 5;
      page++
    ) {
      await repository.searchProducts(keyword: 'tv', page: page);
    }

    expect(box.length, ProductCacheLocalDataSourceImpl.maxEntries);
    // Lo primero que entró es lo primero que se descarta.
    expect(
      box.get(ProductCacheLocalDataSourceImpl.entryKey(keyword: 'tv', page: 1)),
      isNull,
    );
  });
}
