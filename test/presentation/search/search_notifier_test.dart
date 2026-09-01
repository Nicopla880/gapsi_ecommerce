import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/core/errors/exceptions.dart';
import 'package:gapsi_ecommerce/core/utils/debouncer.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/domain/usecases/get_search_history.dart';
import 'package:gapsi_ecommerce/domain/usecases/save_search_term.dart';
import 'package:gapsi_ecommerce/domain/usecases/search_products.dart';
import 'package:gapsi_ecommerce/presentation/search/search_dependencies.dart';
import 'package:gapsi_ecommerce/presentation/search/search_notifier.dart';
import 'package:gapsi_ecommerce/presentation/search/search_providers.dart';
import 'package:gapsi_ecommerce/presentation/search/search_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchProducts extends Mock implements SearchProducts {}

class _MockSaveSearchTerm extends Mock implements SaveSearchTerm {}

class _MockGetSearchHistory extends Mock implements GetSearchHistory {}

const Product _sony = Product(id: 'sony-1', title: 'Sony TV');
const Product _nintendo = Product(id: 'nin-1', title: 'Nintendo Switch');

void main() {
  late _MockSearchProducts searchProducts;
  late _MockSaveSearchTerm saveSearchTerm;
  late _MockGetSearchHistory getSearchHistory;

  setUp(() {
    searchProducts = _MockSearchProducts();
    saveSearchTerm = _MockSaveSearchTerm();
    getSearchHistory = _MockGetSearchHistory();

    when(() => saveSearchTerm(any())).thenAnswer((_) async {});
    when(() => getSearchHistory()).thenAnswer((_) async => const <String>[]);
  });

  ProviderContainer createContainer() {
    final Debouncer debouncer = Debouncer(delay: Duration.zero);
    addTearDown(debouncer.dispose);
    return ProviderContainer.test(
      overrides: [
        searchProductsUseCaseProvider.overrideWithValue(searchProducts),
        saveSearchTermUseCaseProvider.overrideWithValue(saveSearchTerm),
        getSearchHistoryUseCaseProvider.overrideWithValue(getSearchHistory),
        searchDebouncerProvider.overrideWithValue(debouncer),
      ],
    );
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  SearchNotifier notifierOf(ProviderContainer container) {
    return container.read(searchNotifierProvider.notifier);
  }

  group('SearchNotifier', () {
    test('empieza en SearchInitial sin buscar automáticamente', () {
      final ProviderContainer container = createContainer();

      expect(container.read(searchNotifierProvider), const SearchInitial());
      verifyNever(
        () => searchProducts(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
        ),
      );
    });

    test('búsqueda exitosa emite loading y guarda página 1', () async {
      when(
        () => searchProducts(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => const <Product>[_nintendo]);
      final ProviderContainer container = createContainer();
      final List<SearchState> states = <SearchState>[];
      final ProviderSubscription<SearchState> subscription = container.listen(
        searchNotifierProvider,
        (SearchState? previous, SearchState next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      notifierOf(container).onSearchChanged('  nintendo  ');
      await settle();

      expect(states, <Object>[
        const SearchInitial(),
        const SearchLoading(),
        isA<SearchLoaded>(),
      ]);
      final SearchLoaded loaded =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(loaded.products, const <Product>[_nintendo]);
      expect(loaded.currentPage, 1);
      expect(loaded.hasReachedMax, isFalse);
      verify(() => searchProducts(keyword: 'nintendo', page: 1)).called(1);
    });

    test('error inicial tipado se convierte en SearchError legible', () async {
      when(
        () => searchProducts(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
        ),
      ).thenThrow(const NetworkException('Sin conexión'));
      final ProviderContainer container = createContainer();

      notifierOf(container).onSearchChanged('sony');
      await settle();

      expect(
        container.read(searchNotifierProvider),
        const SearchError('Sin conexión'),
      );
    });

    test('retry repite inmediatamente la última búsqueda efectiva', () async {
      var attempts = 0;
      when(() => searchProducts(keyword: 'sony', page: 1)).thenAnswer((
        _,
      ) async {
        attempts++;
        if (attempts == 1) {
          throw const NetworkException('Sin conexión');
        }
        return const <Product>[_sony];
      });
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('sony');
      await settle();
      expect(container.read(searchNotifierProvider), isA<SearchError>());

      await notifier.retry();

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products, const <Product>[_sony]);
      verify(() => searchProducts(keyword: 'sony', page: 1)).called(2);
    });

    test('resultado vacío es SearchLoaded y alcanza el máximo', () async {
      when(
        () => searchProducts(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => const <Product>[]);
      final ProviderContainer container = createContainer();

      notifierOf(container).onSearchChanged('inexistente');
      await settle();

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products, isEmpty);
      expect(state.currentPage, 1);
      expect(state.hasReachedMax, isTrue);
    });

    test('debounce ejecuta solo la última consulta de una ráfaga', () async {
      when(
        () => searchProducts(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => const <Product>[_nintendo]);
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('n');
      notifier.onSearchChanged('ni');
      notifier.onSearchChanged('nin');
      notifier.onSearchChanged('nintendo');
      await settle();

      verify(() => searchProducts(keyword: 'nintendo', page: 1)).called(1);
      verifyNoMoreInteractions(searchProducts);
    });

    test('consulta vacía cancela el debounce y vuelve a initial', () async {
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('nintendo');
      notifier.onSearchChanged('   ');
      await settle();

      expect(container.read(searchNotifierProvider), const SearchInitial());
      verifyNever(
        () => searchProducts(
          keyword: any(named: 'keyword'),
          page: any(named: 'page'),
        ),
      );
    });

    test(
      'paginación agrega productos y solicita la página siguiente',
      () async {
        when(
          () => searchProducts(keyword: 'sony', page: 1),
        ).thenAnswer((_) async => const <Product>[_sony]);
        when(() => searchProducts(keyword: 'sony', page: 2)).thenAnswer(
          (_) async => const <Product>[
            Product(id: 'sony-2', title: 'Sony Headphones'),
          ],
        );
        final ProviderContainer container = createContainer();
        final SearchNotifier notifier = notifierOf(container);

        notifier.onSearchChanged('sony');
        await settle();
        await notifier.loadNextPage();

        final SearchLoaded state =
            container.read(searchNotifierProvider) as SearchLoaded;
        expect(state.products.map((Product product) => product.id), <String>[
          'sony-1',
          'sony-2',
        ]);
        expect(state.currentPage, 2);
        expect(state.isLoadingNextPage, isFalse);
        verify(() => searchProducts(keyword: 'sony', page: 2)).called(1);
      },
    );

    test('impide solicitudes de paginación duplicadas', () async {
      final Completer<List<Product>> secondPage = Completer<List<Product>>();
      when(
        () => searchProducts(keyword: 'sony', page: 1),
      ).thenAnswer((_) async => const <Product>[_sony]);
      when(
        () => searchProducts(keyword: 'sony', page: 2),
      ).thenAnswer((_) => secondPage.future);
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('sony');
      await settle();
      final Future<void> first = notifier.loadNextPage();
      final Future<void> duplicate = notifier.loadNextPage();

      verify(() => searchProducts(keyword: 'sony', page: 2)).called(1);
      secondPage.complete(const <Product>[
        Product(id: 'sony-2', title: 'Sony Headphones'),
      ]);
      await Future.wait(<Future<void>>[first, duplicate]);
    });

    test('error de paginación conserva resultados y página actuales', () async {
      when(
        () => searchProducts(keyword: 'sony', page: 1),
      ).thenAnswer((_) async => const <Product>[_sony]);
      when(
        () => searchProducts(keyword: 'sony', page: 2),
      ).thenThrow(const ServerException('Página no disponible'));
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('sony');
      await settle();
      await notifier.loadNextPage();

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products, const <Product>[_sony]);
      expect(state.currentPage, 1);
      expect(state.hasReachedMax, isFalse);
      expect(state.isLoadingNextPage, isFalse);
      expect(state.nextPageError, 'Página no disponible');
    });

    test('hasReachedMax evita nuevas llamadas', () async {
      when(
        () => searchProducts(keyword: 'vacío', page: 1),
      ).thenAnswer((_) async => const <Product>[]);
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('vacío');
      await settle();
      await notifier.loadNextPage();

      verify(() => searchProducts(keyword: 'vacío', page: 1)).called(1);
      verifyNever(() => searchProducts(keyword: 'vacío', page: 2));
    });

    test('deduplica por Product.id preservando el orden', () async {
      when(() => searchProducts(keyword: 'sony', page: 1)).thenAnswer(
        (_) async => const <Product>[
          Product(id: 'a', title: 'A'),
          Product(id: 'b', title: 'B'),
          Product(id: 'c', title: 'C'),
        ],
      );
      when(() => searchProducts(keyword: 'sony', page: 2)).thenAnswer(
        (_) async => const <Product>[
          Product(id: 'c', title: 'C repetido'),
          Product(id: 'd', title: 'D'),
          Product(id: 'e', title: 'E'),
        ],
      );
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('sony');
      await settle();
      await notifier.loadNextPage();

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products.map((Product product) => product.id), <String>[
        'a',
        'b',
        'c',
        'd',
        'e',
      ]);
    });

    test('respuesta inicial obsoleta no reemplaza la consulta nueva', () async {
      final Completer<List<Product>> sonyResult = Completer<List<Product>>();
      final Completer<List<Product>> nintendoResult =
          Completer<List<Product>>();
      when(
        () => searchProducts(keyword: 'sony', page: 1),
      ).thenAnswer((_) => sonyResult.future);
      when(
        () => searchProducts(keyword: 'nintendo', page: 1),
      ).thenAnswer((_) => nintendoResult.future);
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('sony');
      await settle();
      notifier.onSearchChanged('nintendo');
      await settle();

      nintendoResult.complete(const <Product>[_nintendo]);
      await settle();
      sonyResult.complete(const <Product>[_sony]);
      await settle();

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products, const <Product>[_nintendo]);
      verify(() => saveSearchTerm('nintendo')).called(1);
      verifyNever(() => saveSearchTerm('sony'));
    });

    test('paginación obsoleta no contamina una búsqueda nueva', () async {
      final Completer<List<Product>> sonyPageTwo = Completer<List<Product>>();
      when(
        () => searchProducts(keyword: 'sony', page: 1),
      ).thenAnswer((_) async => const <Product>[_sony]);
      when(
        () => searchProducts(keyword: 'sony', page: 2),
      ).thenAnswer((_) => sonyPageTwo.future);
      when(
        () => searchProducts(keyword: 'nintendo', page: 1),
      ).thenAnswer((_) async => const <Product>[_nintendo]);
      final ProviderContainer container = createContainer();
      final SearchNotifier notifier = notifierOf(container);

      notifier.onSearchChanged('sony');
      await settle();
      final Future<void> oldPagination = notifier.loadNextPage();
      notifier.onSearchChanged('nintendo');
      await settle();

      sonyPageTwo.complete(const <Product>[
        Product(id: 'sony-2', title: 'Sony Headphones'),
      ]);
      await oldPagination;

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products, const <Product>[_nintendo]);
      expect(state.currentPage, 1);
    });

    test('historial se refresca después de guardar una búsqueda', () async {
      List<String> history = <String>['sony'];
      when(
        () => getSearchHistory(),
      ).thenAnswer((_) async => List<String>.unmodifiable(history));
      when(() => saveSearchTerm(any())).thenAnswer((
        Invocation invocation,
      ) async {
        final String term = invocation.positionalArguments.single as String;
        history = <String>[
          term,
          ...history.where((String item) => item != term),
        ];
      });
      when(
        () => searchProducts(keyword: 'nintendo', page: 1),
      ).thenAnswer((_) async => const <Product>[_nintendo]);
      final ProviderContainer container = createContainer();

      expect(await container.read(searchHistoryProvider.future), <String>[
        'sony',
      ]);
      notifierOf(container).onSearchChanged('nintendo');
      await settle();

      expect(await container.read(searchHistoryProvider.future), <String>[
        'nintendo',
        'sony',
      ]);
      verify(() => getSearchHistory()).called(2);
    });

    test('fallo al guardar historial no invalida resultados', () async {
      when(
        () => saveSearchTerm(any()),
      ).thenThrow(const CacheException('No se pudo guardar'));
      when(
        () => searchProducts(keyword: 'nintendo', page: 1),
      ).thenAnswer((_) async => const <Product>[_nintendo]);
      final ProviderContainer container = createContainer();

      notifierOf(container).onSearchChanged('nintendo');
      await settle();

      final SearchLoaded state =
          container.read(searchNotifierProvider) as SearchLoaded;
      expect(state.products, const <Product>[_nintendo]);
    });
  });
}
