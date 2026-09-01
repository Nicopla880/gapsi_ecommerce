import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/presentation/search/search_notifier.dart';
import 'package:gapsi_ecommerce/presentation/search/search_providers.dart';
import 'package:gapsi_ecommerce/presentation/search/search_screen.dart';
import 'package:gapsi_ecommerce/presentation/search/search_state.dart';
import 'package:gapsi_ecommerce/presentation/search/widgets/search_headers.dart';

class _FakeSearchNotifier extends SearchNotifier {
  _FakeSearchNotifier(this.initialState);

  final SearchState initialState;
  final List<String> searchIntents = <String>[];
  int retryCalls = 0;
  int loadNextPageCalls = 0;

  @override
  SearchState build() => initialState;

  @override
  void onSearchChanged(String query) => searchIntents.add(query);

  @override
  Future<void> retry() async {
    retryCalls++;
  }

  @override
  Future<void> loadNextPage() async {
    loadNextPageCalls++;
  }

  void emit(SearchState next) => state = next;
}

const Product _console = Product(
  id: 'console-1',
  title: 'Nintendo Switch OLED Console',
  price: 349.99,
);

Future<_FakeSearchNotifier> _pumpSearchScreen(
  WidgetTester tester, {
  SearchState initialState = const SearchInitial(),
  List<String> history = const <String>[],
  ValueChanged<Product>? onProductTap,
  TextScaler? textScaler,
}) async {
  late _FakeSearchNotifier notifier;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        searchNotifierProvider.overrideWith(() {
          notifier = _FakeSearchNotifier(initialState);
          return notifier;
        }),
        searchHistoryProvider.overrideWith(
          (Ref ref) async => List<String>.unmodifiable(history),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B1E4D)),
          useMaterial3: true,
        ),
        builder: (BuildContext context, Widget? child) {
          if (textScaler == null) return child!;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          );
        },
        home: SearchScreen(onProductTap: onProductTap),
      ),
    ),
  );
  // Dos frames resuelven el FutureProvider sin esperar que los indicadores
  // indeterminados terminen una animación que, por diseño, es continua.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return notifier;
}

TextEditingController _searchController(WidgetTester tester) {
  return tester
      .widget<TextField>(find.byKey(const Key('searchField')))
      .controller!;
}

void main() {
  testWidgets('muestra el logo GASPI y el campo de búsqueda', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(tester);

    expect(find.byKey(const Key('gapsiLogo')), findsOneWidget);
    expect(find.byKey(const Key('searchField')), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);
  });

  testWidgets('sin historial muestra All seleccionado y ningún recent vacío', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(tester);

    expect(find.text('Discover products'), findsNothing);
    expect(find.text('Loading recent searches…'), findsNothing);
    expect(find.byKey(const Key('recentSearchRow')), findsNothing);
    expect(find.text('All'), findsOneWidget);
    expect(
      find.byKey(const Key('quickSearch-All')).hitTestable(),
      findsOneWidget,
    );

    final Semantics all = tester.widget<Semantics>(
      find.byKey(const Key('quickSearchSemantics-All')),
    );
    expect(all.properties.selected, isTrue);
    expect(
      tester.getSize(find.byKey(const Key('quickSearchIndicator-All'))).width,
      greaterThan(0),
    );

    final SliverAppBar appBar = tester.widget<SliverAppBar>(
      find.byKey(const Key('searchSliverAppBar')),
    );
    expect(
      appBar.expandedHeight! - appBar.collapsedHeight!,
      SearchHeaderLayout.discoveryQuickOnlyExtent,
    );
  });

  testWidgets('cada cambio de texto delega la intención al notifier', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(tester);

    await tester.enterText(find.byKey(const Key('searchField')), 'sony tv');
    await tester.pump();

    expect(notifier.searchIntents, <String>['sony tv']);
  });

  testWidgets('Gaming completa el campo y ejecuta keyword gaming', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(tester);

    await tester.tap(find.byKey(const Key('quickSearch-Gaming')));
    await tester.pump();

    expect(_searchController(tester).text, 'gaming');
    expect(_searchController(tester).selection.baseOffset, 'gaming'.length);
    expect(notifier.searchIntents.last, 'gaming');
  });

  testWidgets('All limpia el campo y envía intención vacía', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(tester);
    await tester.enterText(find.byKey(const Key('searchField')), 'laptop');
    await tester.pump();

    await tester.tap(find.byKey(const Key('quickSearch-All')));
    await tester.pump();

    expect(_searchController(tester).text, isEmpty);
    expect(notifier.searchIntents.last, isEmpty);
  });

  testWidgets('acción clear limpia el campo y notifica intención vacía', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(tester);
    await tester.enterText(find.byKey(const Key('searchField')), 'console');
    await tester.pump();

    await tester.tap(find.byKey(const Key('clearSearchButton')));
    await tester.pump();

    expect(_searchController(tester).text, isEmpty);
    expect(notifier.searchIntents.last, isEmpty);
  });

  testWidgets('recent shortcut completa y ejecuta la búsqueda persistida', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      history: const <String>['Nintendo'],
    );

    expect(find.text('Recent: Nintendo'), findsOneWidget);
    expect(find.byKey(const Key('recentSearchRow')), findsOneWidget);
    expect(find.text('Discover products'), findsNothing);

    final SliverAppBar appBar = tester.widget<SliverAppBar>(
      find.byKey(const Key('searchSliverAppBar')),
    );
    expect(
      appBar.expandedHeight! - appBar.collapsedHeight!,
      SearchHeaderLayout.discoveryWithRecentExtent,
    );

    await tester.tap(find.byKey(const Key('recentSearchShortcut')));
    await tester.pump();

    expect(_searchController(tester).text, 'Nintendo');
    expect(notifier.searchIntents.last, 'Nintendo');
  });

  testWidgets('discovery tolera escala de texto alta sin overflow', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      ),
      history: const <String>['Nintendo'],
      textScaler: const TextScaler.linear(2),
    );

    expect(find.text('Recent: Nintendo'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);
    expect(find.byKey(const Key('searchField')), findsOneWidget);
    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.text(r'$349.99'), findsOneWidget);
    final SliverAppBar appBar = tester.widget<SliverAppBar>(
      find.byKey(const Key('searchSliverAppBar')),
    );
    expect(
      appBar.expandedHeight! - appBar.collapsedHeight!,
      greaterThan(SearchHeaderLayout.discoveryWithRecentExtent),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('escala reducida conserva el tamaño visual mínimo', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      history: const <String>['Nintendo'],
      textScaler: const TextScaler.linear(0.8),
    );

    final SliverAppBar appBar = tester.widget<SliverAppBar>(
      find.byKey(const Key('searchSliverAppBar')),
    );
    expect(
      appBar.expandedHeight! - appBar.collapsedHeight!,
      SearchHeaderLayout.discoveryWithRecentExtent,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('estado inicial presenta todo el historial real', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      history: const <String>['Nintendo', 'Sony', 'Laptop'],
    );

    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.byKey(const Key('history-Nintendo')), findsOneWidget);
    expect(find.byKey(const Key('history-Sony')), findsOneWidget);
    expect(find.byKey(const Key('history-Laptop')), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-Sony')));
    await tester.pump();
    expect(_searchController(tester).text, 'Sony');
    expect(notifier.searchIntents.last, 'Sony');
  });

  testWidgets('loading conserva el header primario', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(tester, initialState: const SearchLoading());

    expect(find.byKey(const Key('searchField')), findsOneWidget);
    expect(find.byKey(const Key('initialSearchLoader')), findsOneWidget);
  });

  testWidgets('grid muestra título, precio y placeholder de imagen', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[
          _console,
          Product(id: 'unknown', title: 'Mystery product'),
        ],
        currentPage: 1,
        hasReachedMax: false,
      ),
    );

    expect(find.byKey(const Key('productGrid')), findsOneWidget);
    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.text(r'$349.99'), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.byKey(const Key('productImagePlaceholder')), findsNWidgets(2));
  });

  testWidgets('ProductCard propaga el tap preparado para detalle', (
    WidgetTester tester,
  ) async {
    Product? selected;
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      ),
      onProductTap: (Product product) => selected = product,
    );

    await tester.tap(find.byKey(const ValueKey<String>('product-console-1')));
    await tester.pump();

    expect(selected, _console);
  });

  testWidgets('resultado vacío presenta mensaje y mantiene búsqueda', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[],
        currentPage: 1,
        hasReachedMax: true,
      ),
    );

    expect(find.text('No products found'), findsOneWidget);
    expect(find.byKey(const Key('searchField')), findsOneWidget);
  });

  testWidgets('error inicial presenta mensaje y retry del notifier', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      initialState: const SearchError('No connection'),
    );

    expect(find.text('No connection'), findsOneWidget);
    await tester.tap(find.byKey(const Key('initialRetryButton')));
    await tester.pump();

    expect(notifier.retryCalls, 1);
    expect(find.byKey(const Key('searchField')), findsOneWidget);
  });

  testWidgets('loader de paginación conserva productos visibles', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: false,
        isLoadingNextPage: true,
      ),
    );

    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.byKey(const Key('paginationLoader')), findsOneWidget);
  });

  testWidgets('error de paginación conserva grid y permite retry', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: false,
        nextPageError: 'Could not load more products',
      ),
    );

    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.text('Could not load more products'), findsOneWidget);
    await tester.tap(find.byKey(const Key('paginationRetryButton')));
    await tester.pump();

    expect(notifier.loadNextPageCalls, 1);
  });

  testWidgets('scroll cercano al final delega paginación al notifier', (
    WidgetTester tester,
  ) async {
    final List<Product> products = List<Product>.generate(
      30,
      (int index) => Product(id: '$index', title: 'Product $index'),
    );
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: products,
        currentPage: 1,
        hasReachedMax: false,
      ),
    );

    await tester.fling(
      find.byKey(const Key('searchScrollView')),
      const Offset(0, -6000),
      5000,
    );
    await tester.pumpAndSettle();

    expect(notifier.loadNextPageCalls, greaterThan(0));
  });

  testWidgets('discovery reaparece al invertir el scroll lejos del inicio', (
    WidgetTester tester,
  ) async {
    final List<Product> products = List<Product>.generate(
      30,
      (int index) => Product(id: '$index', title: 'Product $index'),
    );
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: products,
        currentPage: 1,
        hasReachedMax: true,
      ),
      history: const <String>['Nintendo'],
    );

    final SliverAppBar appBar = tester.widget<SliverAppBar>(
      find.byKey(const Key('searchSliverAppBar')),
    );
    expect(appBar.pinned, isTrue);
    expect(appBar.floating, isTrue);
    expect(appBar.snap, isTrue);
    expect(
      find.byKey(const Key('recentSearchRow')).hitTestable(),
      findsOneWidget,
    );

    final CustomScrollView scrollView = tester.widget<CustomScrollView>(
      find.byKey(const Key('searchScrollView')),
    );
    await tester.drag(
      find.byKey(const Key('searchScrollView')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    final double deepOffset = scrollView.controller!.offset;
    expect(deepOffset, greaterThan(0));
    expect(find.byKey(const Key('searchField')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('quickSearch-Gaming')).hitTestable(),
      findsNothing,
    );
    expect(
      find.byKey(const Key('recentSearchRow')).hitTestable(),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const Key('searchScrollView')),
      const Offset(0, 140),
    );
    await tester.pumpAndSettle();

    expect(scrollView.controller!.offset, greaterThan(0));
    expect(scrollView.controller!.offset, lessThan(deepOffset));
    expect(find.byKey(const Key('searchField')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('quickSearch-Gaming')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('recentSearchRow')).hitTestable(),
      findsOneWidget,
    );
    expect(notifier.loadNextPageCalls, 0);

    await tester.drag(
      find.byKey(const Key('searchScrollView')),
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('searchField')).hitTestable(), findsOneWidget);
    expect(
      find.byKey(const Key('quickSearch-Gaming')).hitTestable(),
      findsNothing,
    );
  });
}
