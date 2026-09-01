import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/data/datasources/remote/walmart_remote_datasource.dart';
import 'package:gapsi_ecommerce/data/models/product_model.dart';
import 'package:gapsi_ecommerce/data/repositories/product_repository_impl.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock implements WalmartRemoteDataSource {}

void main() {
  late _MockRemoteDataSource remote;
  late ProductRepositoryImpl repository;

  setUp(() {
    remote = _MockRemoteDataSource();
    repository = ProductRepositoryImpl(remote);
  });

  test('descarta los productos sin id', () async {
    when(
      () => remote.searchProducts(
        keyword: any(named: 'keyword'),
        page: any(named: 'page'),
      ),
    ).thenAnswer(
      (_) async => const <ProductModel>[
        ProductModel(id: '', title: 'Sin id'),
        ProductModel(id: '123', title: 'Con id'),
      ],
    );

    final List<Product> result = await repository.searchProducts(
      keyword: 'tv',
      page: 1,
    );

    expect(result.map((Product p) => p.id), <String>['123']);
  });
}
