import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/design_system/gapsi_design_system.dart';
import 'package:gapsi_ecommerce/domain/entities/favorites_collection.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/presentation/detail/product_detail_screen.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_notifier.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_providers.dart';
import 'package:gapsi_ecommerce/presentation/search/search_notifier.dart';
import 'package:gapsi_ecommerce/presentation/search/search_providers.dart';
import 'package:gapsi_ecommerce/presentation/search/search_screen.dart';
import 'package:gapsi_ecommerce/presentation/search/search_state.dart';
import 'package:gapsi_ecommerce/presentation/search/widgets/search_feedback.dart';
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

class _FakeFavoritesNotifier extends FavoritesNotifier {
  _FakeFavoritesNotifier(this.initialFavorites);

  final FavoritesCollection initialFavorites;
  int toggleCalls = 0;

  @override
  Future<FavoritesCollection> build() async => initialFavorites;

  @override
  Future<bool> toggleFavorite(Product product) async {
    toggleCalls++;
    final FavoritesCollection current = state.requireValue;
    state = AsyncData<FavoritesCollection>(
      current.setFavorite(product, value: !current.contains(product.id)),
    );
    return true;
  }
}

const Product _console = Product(
  id: 'console-1',
  title: 'Nintendo Switch OLED Console',
  price: 349.99,
  description: 'OLED gaming system with detachable controllers.',
);

Future<_FakeSearchNotifier> _pumpSearchScreen(
  WidgetTester tester, {
  SearchState initialState = const SearchInitial(),
  List<String> history = const <String>[],
  ValueChanged<Product>? onProductTap,
  TextScaler? textScaler,
  List<Product> favoriteProducts = const <Product>[],
  _FakeFavoritesNotifier? favoritesNotifier,
}) async {
  late _FakeSearchNotifier notifier;
  final _FakeFavoritesNotifier resolvedFavoritesNotifier =
      favoritesNotifier ??
      _FakeFavoritesNotifier(FavoritesCollection(products: favoriteProducts));
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
        favoritesProvider.overrideWith(() => resolvedFavoritesNotifier),
      ],
      child: MaterialApp(
        theme: GapsiTheme.light(),
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

double _entranceOpacity(WidgetTester tester, String productId) {
  return tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(ValueKey<String>('product-$productId')),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;
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

  testWidgets(
    'discovery muestra Favorites y elimina All y Recent persistente',
    (WidgetTester tester) async {
      await _pumpSearchScreen(tester, history: const <String>['Nintendo']);

      expect(find.text('Favorites'), findsOneWidget);
      expect(
        find.byKey(const Key('quickSearch-Favorites')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('All'), findsNothing);
      expect(find.text('Recent: Nintendo'), findsNothing);
      expect(find.byKey(const Key('recentSearchRow')), findsNothing);

      final SliverAppBar appBar = tester.widget<SliverAppBar>(
        find.byKey(const Key('searchSliverAppBar')),
      );
      expect(
        appBar.expandedHeight! - appBar.collapsedHeight!,
        SearchHeaderLayout.discoveryQuickOnlyExtent,
      );
    },
  );

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
    final Semantics gaming = tester.widget<Semantics>(
      find.byKey(const Key('quickSearchSemantics-Gaming')),
    );
    expect(gaming.properties.selected, isTrue);
  });

  testWidgets('query arbitraria no selecciona ningún quick search', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(tester);

    await tester.enterText(find.byKey(const Key('searchField')), 'Nintendo');
    await tester.pump();

    for (final String label in <String>[
      'Gaming',
      'Electronics',
      'Laptops',
      'Home',
      'Fashion',
    ]) {
      final Semantics item = tester.widget<Semantics>(
        find.byKey(ValueKey<String>('quickSearchSemantics-$label')),
      );
      expect(item.properties.selected, isFalse);
    }
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

  testWidgets('foco muestra historial y tap ejecuta búsqueda persistida', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      history: const <String>['Nintendo'],
    );

    expect(find.byKey(const Key('focusedRecentSearches')), findsNothing);
    await tester.tap(find.byKey(const Key('searchField')));
    await tester.pump();

    expect(find.byKey(const Key('focusedRecentSearches')), findsOneWidget);
    expect(find.byKey(const Key('history-Nintendo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-Nintendo')));
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

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);
    expect(find.byKey(const Key('searchField')), findsOneWidget);
    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.text(r'$349.99'), findsOneWidget);
    final SliverAppBar appBar = tester.widget<SliverAppBar>(
      find.byKey(const Key('searchSliverAppBar')),
    );
    expect(
      appBar.expandedHeight! - appBar.collapsedHeight!,
      greaterThan(SearchHeaderLayout.discoveryQuickOnlyExtent),
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
      SearchHeaderLayout.discoveryQuickOnlyExtent,
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

  testWidgets(
    'foco preserva SearchLoaded y al salir restaura grid sin request',
    (WidgetTester tester) async {
      final SearchLoaded loaded = SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      );
      final _FakeSearchNotifier notifier = await _pumpSearchScreen(
        tester,
        initialState: loaded,
        history: const <String>['Nintendo'],
      );

      await tester.tap(find.byKey(const Key('searchField')));
      await tester.pump();
      expect(find.byKey(const Key('focusedRecentSearches')), findsOneWidget);
      expect(find.byKey(const Key('productGrid')), findsNothing);
      expect(notifier.state, same(loaded));

      tester
          .widget<TextField>(find.byKey(const Key('searchField')))
          .focusNode!
          .unfocus();
      await tester.pump();

      expect(find.byKey(const Key('productGrid')), findsOneWidget);
      expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
      expect(notifier.state, same(loaded));
      expect(notifier.searchIntents, isEmpty);
    },
  );

  testWidgets('Favorites vacío no busca remotamente y muestra empty state', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(tester);

    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();

    expect(_searchController(tester).text, isEmpty);
    expect(notifier.searchIntents, isEmpty);
    expect(find.byKey(const Key('emptyFavorites')), findsOneWidget);
    // Anclado arriba, como el estado inicial, y no centrado en la pantalla.
    expect(
      tester
          .widget<SearchMessage>(find.byKey(const Key('emptyFavorites')))
          .alignment,
      Alignment.topCenter,
    );
    final Semantics favorites = tester.widget<Semantics>(
      find.byKey(const Key('quickSearchSemantics-Favorites')),
    );
    expect(favorites.properties.selected, isTrue);
  });

  testWidgets('Favorites muestra snapshots persistidos sin request remoto', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      favoriteProducts: const <Product>[_console],
    );

    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();

    expect(find.byKey(const Key('favoritesGrid')), findsOneWidget);
    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.text(r'$349.99'), findsOneWidget);
    expect(notifier.searchIntents, isEmpty);
  });

  testWidgets('scroll en Favorites no dispara paginación remota', (
    WidgetTester tester,
  ) async {
    final List<Product> favorites = List<Product>.generate(
      30,
      (int index) => Product(id: 'fav-$index', title: 'Favorite $index'),
    );
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: favorites,
        currentPage: 1,
        hasReachedMax: false,
      ),
      favoriteProducts: favorites,
    );

    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();

    await tester.fling(
      find.byKey(const Key('searchScrollView')),
      const Offset(0, -6000),
      5000,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('favoritesGrid')), findsOneWidget);
    expect(notifier.loadNextPageCalls, isZero);
    expect(notifier.searchIntents, isEmpty);
  });

  testWidgets(
    'quitar favorito desde colección elimina la card inmediatamente',
    (WidgetTester tester) async {
      final _FakeFavoritesNotifier favoritesNotifier = _FakeFavoritesNotifier(
        FavoritesCollection(products: const <Product>[_console]),
      );
      await _pumpSearchScreen(tester, favoritesNotifier: favoritesNotifier);
      await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('favoriteButton-console-1')),
      );
      await tester.pump();

      expect(find.text('Nintendo Switch OLED Console'), findsNothing);
      expect(find.byKey(const Key('emptyFavorites')), findsOneWidget);
      expect(favoritesNotifier.toggleCalls, 1);
    },
  );

  testWidgets('foco desde Favorites restaura colección al cancelar', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      history: const <String>['Nintendo'],
      favoriteProducts: const <Product>[_console],
    );
    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('searchField')));
    await tester.pump();
    expect(find.byKey(const Key('focusedRecentSearches')), findsOneWidget);
    expect(find.byKey(const Key('favoritesGrid')), findsNothing);

    tester
        .widget<TextField>(find.byKey(const Key('searchField')))
        .focusNode!
        .unfocus();
    await tester.pump();

    expect(find.byKey(const Key('favoritesGrid')), findsOneWidget);
    expect(notifier.searchIntents, isEmpty);
  });

  testWidgets('recent y escritura salen de Favorites', (
    WidgetTester tester,
  ) async {
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      history: const <String>['Nintendo'],
      favoriteProducts: const <Product>[_console],
    );
    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('searchField')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('history-Nintendo')));
    await tester.pump();

    expect(notifier.searchIntents.last, 'Nintendo');
    expect(find.byKey(const Key('favoritesGrid')), findsNothing);

    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('searchField')));
    await tester.enterText(find.byKey(const Key('searchField')), 'Sony');
    await tester.pump();

    expect(notifier.searchIntents.last, 'Sony');
    final Semantics favorites = tester.widget<Semantics>(
      find.byKey(const Key('quickSearchSemantics-Favorites')),
    );
    expect(favorites.properties.selected, isFalse);
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
    expect(
      find.byKey(const ValueKey<String>('favoriteOutline-console-1')),
      findsOneWidget,
    );
  });

  testWidgets('favorito persistido se renderiza al inicializar provider', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      ),
      favoriteProducts: const <Product>[_console],
    );

    expect(
      find.byKey(const ValueKey<String>('favoriteFilled-console-1')),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  });

  testWidgets('tap en corazón agrega favorito sin abrir la tarjeta', (
    WidgetTester tester,
  ) async {
    Product? selected;
    final _FakeFavoritesNotifier favoritesNotifier = _FakeFavoritesNotifier(
      FavoritesCollection(),
    );
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      ),
      onProductTap: (Product product) => selected = product,
      favoritesNotifier: favoritesNotifier,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('favoriteButton-console-1')),
    );
    await tester.pump();

    expect(selected, isNull);
    expect(favoritesNotifier.toggleCalls, 1);
    expect(
      find.byKey(const ValueKey<String>('favoriteFilled-console-1')),
      findsOneWidget,
    );
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

  testWidgets(
    'tap abre detalle y volver conserva resultados sin nueva búsqueda',
    (WidgetTester tester) async {
      final SearchLoaded loadedState = SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      );
      final _FakeFavoritesNotifier favoritesNotifier = _FakeFavoritesNotifier(
        FavoritesCollection(products: const <Product>[_console]),
      );
      final _FakeSearchNotifier notifier = await _pumpSearchScreen(
        tester,
        initialState: loadedState,
        favoritesNotifier: favoritesNotifier,
      );

      await tester.tap(find.byKey(const ValueKey<String>('product-console-1')));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(
        find.byKey(const Key('productDetailFavoriteFilled')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('productDetailFavoriteButton')));
      await tester.pump();
      expect(
        find.byKey(const Key('productDetailFavoriteOutline')),
        findsOneWidget,
      );

      final Finder detailScrollable = find.descendant(
        of: find.byKey(const Key('productDetailScrollView')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('productDetailTitle')),
        300,
        scrollable: detailScrollable,
      );
      await tester.pump();

      expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
      expect(find.text(r'$349.99'), findsOneWidget);
      expect(
        find.text('OLED gaming system with detachable controllers.'),
        findsOneWidget,
      );
      expect(notifier.searchIntents, isEmpty);

      await tester.tap(find.byKey(const Key('productDetailBackButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ProductDetailScreen), findsNothing);
      expect(find.byKey(const Key('productGrid')), findsOneWidget);
      expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('favoriteOutline-console-1')),
        findsOneWidget,
      );
      expect(favoritesNotifier.toggleCalls, 1);
      expect(notifier.state, same(loadedState));
      expect(notifier.searchIntents, isEmpty);
      expect(notifier.loadNextPageCalls, 0);
    },
  );

  testWidgets('card favorita abre detalle y al quitarla desaparece al volver', (
    WidgetTester tester,
  ) async {
    final _FakeFavoritesNotifier favoritesNotifier = _FakeFavoritesNotifier(
      FavoritesCollection(products: const <Product>[_console]),
    );
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      favoritesNotifier: favoritesNotifier,
    );
    await tester.tap(find.byKey(const Key('quickSearch-Favorites')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('product-console-1')));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('productDetailFavoriteButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('productDetailBackButton')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(find.byKey(const Key('emptyFavorites')), findsOneWidget);
    expect(find.text('Nintendo Switch OLED Console'), findsNothing);
    expect(notifier.searchIntents, isEmpty);
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
      find.byKey(const Key('quickSearch-Favorites')).hitTestable(),
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
      find.byKey(const Key('quickSearch-Favorites')).hitTestable(),
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
      find.byKey(const Key('quickSearch-Favorites')).hitTestable(),
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

  testWidgets('el precio se pinta con la tipografía y el azul de marca', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: const <Product>[_console],
        currentPage: 1,
        hasReachedMax: true,
      ),
    );

    final RenderParagraph price =
        tester.renderObject(find.text(r'$349.99')) as RenderParagraph;

    expect(price.text.style?.fontFamily, GapsiTypography.fontFamily);
    expect(price.text.style?.fontWeight, GapsiTypography.extraBold);
    expect(price.text.style?.color, GapsiColors.blue);
  });

  testWidgets('cada imagen de producto expone un Hero con tag único', (
    WidgetTester tester,
  ) async {
    final List<Product> products = List<Product>.generate(
      6,
      (int index) => Product(id: 'p$index', title: 'Product $index'),
    );
    await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: products,
        currentPage: 1,
        hasReachedMax: true,
      ),
    );

    final List<Object> tags = tester
        .widgetList<Hero>(find.byType(Hero))
        .map((Hero hero) => hero.tag)
        .toList(growable: false);

    expect(tags, isNotEmpty);
    expect(tags.toSet().length, tags.length);
    expect(tags, contains('productImage-p0'));
  });

  testWidgets('paginar no repite la entrada de las tarjetas ya visibles', (
    WidgetTester tester,
  ) async {
    final List<Product> firstPage = List<Product>.generate(
      4,
      (int index) => Product(id: 'p$index', title: 'Product $index'),
    );
    final _FakeSearchNotifier notifier = await _pumpSearchScreen(
      tester,
      initialState: SearchLoaded(
        products: firstPage,
        currentPage: 1,
        hasReachedMax: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(_entranceOpacity(tester, 'p0'), 1);

    notifier.emit(
      SearchLoaded(
        products: <Product>[
          ...firstPage,
          const Product(id: 'p4', title: 'Product 4'),
        ],
        currentPage: 2,
        hasReachedMax: true,
      ),
    );
    await tester.pump();

    // La tarjeta ya montada conserva su estado; solo la nueva entra animando.
    expect(_entranceOpacity(tester, 'p0'), 1);
    expect(_entranceOpacity(tester, 'p4'), 0);

    await tester.pump(const Duration(milliseconds: 600));
    expect(_entranceOpacity(tester, 'p4'), 1);
  });

  testWidgets('la carga inicial muestra la grilla de esqueletos', (
    WidgetTester tester,
  ) async {
    await _pumpSearchScreen(tester, initialState: const SearchLoading());

    expect(find.byKey(const Key('initialSearchLoader')), findsOneWidget);
    expect(find.byType(GapsiProductCardSkeleton), findsWidgets);
    expect(find.byKey(const Key('productGrid')), findsNothing);
  });
}
