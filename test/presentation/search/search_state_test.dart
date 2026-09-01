import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/presentation/search/search_state.dart';

void main() {
  test('SearchLoaded protege su lista de mutaciones externas', () {
    final List<Product> source = <Product>[
      const Product(id: '1', title: 'Uno'),
    ];
    final SearchLoaded state = SearchLoaded(
      products: source,
      currentPage: 1,
      hasReachedMax: false,
    );

    source.add(const Product(id: '2', title: 'Dos'));

    expect(state.products.map((Product product) => product.id), <String>['1']);
    expect(
      () => state.products.add(const Product(id: '3', title: 'Tres')),
      throwsUnsupportedError,
    );
  });

  test('copyWith permite conservar o limpiar nextPageError explícitamente', () {
    final SearchLoaded withError = SearchLoaded(
      products: const <Product>[],
      currentPage: 2,
      hasReachedMax: false,
      nextPageError: 'Falló la página',
    );

    expect(withError.copyWith().nextPageError, 'Falló la página');
    expect(withError.copyWith(nextPageError: null).nextPageError, isNull);
  });
}
