import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/gapsi_design_system.dart';
import '../../domain/entities/favorites_collection.dart';
import '../../domain/entities/product.dart';
import '../detail/product_detail_screen.dart';
import '../favorites/favorites_providers.dart';
import 'search_providers.dart';
import 'search_state.dart';
import 'widgets/product_card.dart';
import 'widgets/search_feedback.dart';
import 'widgets/search_headers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.onProductTap, super.key});

  /// Permite reemplazar la navegación en integraciones o pruebas específicas.
  final ValueChanged<Product>? onProductTap;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const double _paginationThreshold = 320;

  static const List<({String label, String keyword})> _quickSearches =
      <({String label, String keyword})>[
        (label: 'Gaming', keyword: 'gaming'),
        (label: 'Electronics', keyword: 'electronics'),
        (label: 'Laptops', keyword: 'laptop'),
        (label: 'Home', keyword: 'home'),
        (label: 'Fashion', keyword: 'fashion'),
      ];

  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final FocusNode _searchFocusNode;
  bool _favoritesMode = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchFocusNode = FocusNode()..addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_favoritesMode || _searchFocusNode.hasFocus) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < _paginationThreshold) {
      unawaited(ref.read(searchNotifierProvider.notifier).loadNextPage());
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _favoritesMode = false);
    ref.read(searchNotifierProvider.notifier).onSearchChanged(value);
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  void _runSearch(String keyword) {
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    _searchFocusNode.unfocus();
    setState(() => _favoritesMode = false);
    ref.read(searchNotifierProvider.notifier).onSearchChanged(keyword);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _favoritesMode = false);
    ref.read(searchNotifierProvider.notifier).onSearchChanged('');
  }

  void _showFavorites() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _favoritesMode = true);
  }

  void _onProductSelected(Product product) {
    final ValueChanged<Product>? callback = widget.onProductTap;
    if (callback != null) {
      callback(product);
      return;
    }

    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              ProductDetailScreen(product: product),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    final bool saved = await ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(product);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SearchState searchState = ref.watch(searchNotifierProvider);
    final AsyncValue<List<String>> history = ref.watch(searchHistoryProvider);
    final AsyncValue<FavoritesCollection> favorites = ref.watch(
      favoritesProvider,
    );
    final ThemeData theme = Theme.of(context);
    final double topInset = MediaQuery.paddingOf(context).top;
    final DiscoveryHeaderMetrics discoveryMetrics =
        SearchHeaderLayout.discoveryMetrics(context);
    final double discoveryHeaderExtent = discoveryMetrics.extent;
    final double collapsedHeaderExtent =
        SearchHeaderLayout.primaryContentExtent + topInset;
    final SystemUiOverlayStyle overlayStyle =
        theme.colorScheme.brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        body: CustomScrollView(
          key: const Key('searchScrollView'),
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            SliverAppBar(
              key: const Key('searchSliverAppBar'),
              pinned: true,
              floating: true,
              snap: true,
              primary: false,
              automaticallyImplyLeading: false,
              toolbarHeight: collapsedHeaderExtent,
              collapsedHeight: collapsedHeaderExtent,
              expandedHeight: collapsedHeaderExtent + discoveryHeaderExtent,
              titleSpacing: 0,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.hardEdge,
              title: PrimarySearchHeader(
                topInset: topInset,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
              flexibleSpace: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: discoveryHeaderExtent,
                  maxHeight: discoveryHeaderExtent,
                  child: SizedBox(
                    height: discoveryHeaderExtent,
                    child: DiscoveryHeader(
                      metrics: discoveryMetrics,
                      quickSearches: _quickSearches,
                      activeKeyword: _searchController.text
                          .trim()
                          .toLowerCase(),
                      favoritesSelected: _favoritesMode,
                      onFavoritesSelected: _showFavorites,
                      onSearchSelected: _runSearch,
                    ),
                  ),
                ),
              ),
            ),
            ..._visibleContent(searchState, history, favorites),
          ],
        ),
      ),
    );
  }

  List<Widget> _visibleContent(
    SearchState searchState,
    AsyncValue<List<String>> history,
    AsyncValue<FavoritesCollection> favorites,
  ) {
    if (_searchFocusNode.hasFocus) return <Widget>[_focusContent(history)];
    if (_favoritesMode) return _favoritesContent(favorites);

    if (searchState case SearchLoaded(:final products)) {
      if (favorites case AsyncData<FavoritesCollection>(
        :final value,
      ) when value.legacyIds.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(
              ref
                  .read(favoritesProvider.notifier)
                  .hydrateKnownProducts(products),
            );
          }
        });
      }
    }
    return _contentSlivers(searchState, history, favorites);
  }

  /// Estados sin grilla —loading, error, vacío, favoritos vacíos—. Comparten
  /// ranura dentro del `CustomScrollView`, así que el `AnimatedSwitcher` funde
  /// entre ellos sin tocar el scroll ni la posición del header.
  ///
  /// El historial queda fuera a propósito: el estado inicial y el de foco
  /// muestran la misma lista, y cruzarlos dejaría dos copias en pantalla
  /// durante la transición.
  Widget _messageSliver({required Key stateKey, required Widget child}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AnimatedSwitcher(
        duration: GapsiMotion.stateChange,
        child: KeyedSubtree(key: stateKey, child: child),
      ),
    );
  }

  List<Widget> _contentSlivers(
    SearchState searchState,
    AsyncValue<List<String>> history,
    AsyncValue<FavoritesCollection> favorites,
  ) {
    return switch (searchState) {
      SearchInitial() => <Widget>[_initialContent(history)],
      SearchLoading() => <Widget>[_skeletonGrid()],
      SearchError(:final String message) => <Widget>[
        _messageSliver(
          stateKey: const Key('searchErrorState'),
          child: SearchMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Search unavailable',
            message: message,
            actionLabel: 'Retry',
            actionKey: const Key('initialRetryButton'),
            onAction: () {
              unawaited(ref.read(searchNotifierProvider.notifier).retry());
            },
          ),
        ),
      ],
      SearchLoaded(:final List<Product> products) when products.isEmpty =>
        <Widget>[
          _messageSliver(
            stateKey: const Key('searchEmptyState'),
            child: const SearchMessage(
              icon: Icons.search_off_outlined,
              title: 'No products found',
              message: 'Try another search or choose a quick search above.',
            ),
          ),
        ],
      SearchLoaded() => _loadedContent(searchState, favorites),
    };
  }

  Widget _focusContent(AsyncValue<List<String>> history) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        GapsiSpacing.xl,
        GapsiSpacing.xl,
        GapsiSpacing.xl,
        GapsiSpacing.xxl,
      ),
      sliver: SliverToBoxAdapter(
        child: history.when(
          data: (List<String> searches) => searches.isEmpty
              ? const SearchMessage(
                  key: Key('emptyFocusedHistory'),
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Start typing to search products.',
                  message: '',
                )
              : RecentSearches(
                  key: const Key('focusedRecentSearches'),
                  searches: searches,
                  onSelected: _runSearch,
                ),
          loading: () => const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (Object error, StackTrace stackTrace) => const SearchMessage(
            icon: Icons.history_toggle_off_rounded,
            title: 'Start typing to search products.',
            message: '',
          ),
        ),
      ),
    );
  }

  List<Widget> _favoritesContent(AsyncValue<FavoritesCollection> favorites) {
    return switch (favorites) {
      AsyncLoading<FavoritesCollection>() => <Widget>[
        _messageSliver(
          stateKey: const Key('favoritesLoadingState'),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      AsyncError<FavoritesCollection>() => <Widget>[
        _messageSliver(
          stateKey: const Key('favoritesErrorState'),
          child: const SearchMessage(
            icon: Icons.favorite_border,
            title: 'Favorites unavailable',
            message: 'Could not load your saved products.',
          ),
        ),
      ],
      AsyncData<FavoritesCollection>(:final value)
          when value.products.isEmpty =>
        <Widget>[
          _messageSliver(
            stateKey: const Key('favoritesEmptyState'),
            child: const SearchMessage(
              key: Key('emptyFavorites'),
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message: 'Save products you like to find them here later.',
            ),
          ),
        ],
      AsyncData<FavoritesCollection>(:final value) => <Widget>[
        _productGrid(
          products: value.products,
          favorites: favorites,
          gridKey: const Key('favoritesGrid'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + GapsiSpacing.xl,
          ),
        ),
      ],
    };
  }

  Widget _initialContent(AsyncValue<List<String>> history) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        GapsiSpacing.xl,
        GapsiSpacing.xl,
        GapsiSpacing.xl,
        GapsiSpacing.xxl,
      ),
      sliver: SliverToBoxAdapter(
        child: history.when(
          data: (List<String> searches) {
            if (searches.isEmpty) {
              return const SearchMessage(
                key: Key('emptyInitialHistory'),
                icon: Icons.manage_search_outlined,
                title: 'Find your next product',
                message: 'Search for a product to get started.',
              );
            }
            return RecentSearches(
              key: const Key('initialRecentSearches'),
              searches: searches,
              onSelected: _runSearch,
            );
          },
          loading: () => const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (Object error, StackTrace stackTrace) => const SearchMessage(
            icon: Icons.manage_search_outlined,
            title: 'Find your next product',
            message: 'Search for a product to get started.',
          ),
        ),
      ),
    );
  }

  List<Widget> _loadedContent(
    SearchLoaded state,
    AsyncValue<FavoritesCollection> favorites,
  ) {
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    return <Widget>[
      _productGrid(
        products: state.products,
        favorites: favorites,
        gridKey: const Key('productGrid'),
      ),
      if (state.isLoadingNextPage)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: GapsiSpacing.xl),
            child: Center(
              child: SizedBox.square(
                key: Key('paginationLoader'),
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        )
      else if (state.nextPageError case final String error)
        SliverToBoxAdapter(
          child: PaginationError(
            message: error,
            onRetry: () {
              unawaited(
                ref.read(searchNotifierProvider.notifier).loadNextPage(),
              );
            },
          ),
        ),
      SliverToBoxAdapter(
        child: SizedBox(height: bottomSafeArea + GapsiSpacing.xl),
      ),
    ];
  }

  static const SliverGridDelegate _gridDelegate =
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 286,
        crossAxisSpacing: GapsiSpacing.md,
        mainAxisSpacing: GapsiSpacing.md,
      );

  static const EdgeInsets _gridPadding = EdgeInsets.fromLTRB(
    GapsiSpacing.md,
    GapsiSpacing.lg,
    GapsiSpacing.md,
    GapsiSpacing.sm,
  );

  /// Grilla de esqueletos de la búsqueda inicial. Reutiliza la caja de la
  /// tarjeta real para que la llegada de resultados no mueva el layout.
  Widget _skeletonGrid() {
    return SliverPadding(
      padding: _gridPadding,
      sliver: SliverGrid(
        key: const Key('initialSearchLoader'),
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) => const GapsiProductCardSkeleton(),
          childCount: 6,
        ),
      ),
    );
  }

  Widget _productGrid({
    required List<Product> products,
    required AsyncValue<FavoritesCollection> favorites,
    required Key gridKey,
  }) {
    final Set<String> favoriteIds = switch (favorites) {
      AsyncData<FavoritesCollection>(:final value) => value.favoriteIds,
      _ => const <String>{},
    };
    final bool favoritesReady = favorites is AsyncData<FavoritesCollection>;
    return SliverPadding(
      padding: _gridPadding,
      sliver: SliverGrid(
        key: gridKey,
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final Product product = products[index];
          // La clave va en el envoltorio de entrada: así la tarjeta conserva su
          // elemento cuando se agrega una página y no repite la animación.
          return GapsiEntrance(
            key: ValueKey<String>('product-${product.id}'),
            delay: GapsiEntrance.staggerFor(index),
            child: ProductCard(
              product: product,
              onTap: () => _onProductSelected(product),
              isFavorite: favoriteIds.contains(product.id),
              onFavoriteToggle: favoritesReady
                  ? () => unawaited(_toggleFavorite(product))
                  : null,
            ),
          );
        }, childCount: products.length),
      ),
    );
  }
}
