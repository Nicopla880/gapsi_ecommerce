import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../detail/product_detail_screen.dart';
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
        (label: 'All', keyword: ''),
        (label: 'Gaming', keyword: 'gaming'),
        (label: 'Electronics', keyword: 'electronics'),
        (label: 'Laptops', keyword: 'laptop'),
        (label: 'Home', keyword: 'home'),
        (label: 'Fashion', keyword: 'fashion'),
      ];

  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < _paginationThreshold) {
      unawaited(ref.read(searchNotifierProvider.notifier).loadNextPage());
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    ref.read(searchNotifierProvider.notifier).onSearchChanged(value);
  }

  void _runSearch(String keyword) {
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    _searchFocusNode.unfocus();
    setState(() {});
    ref.read(searchNotifierProvider.notifier).onSearchChanged(keyword);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    ref.read(searchNotifierProvider.notifier).onSearchChanged('');
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

  @override
  Widget build(BuildContext context) {
    final SearchState searchState = ref.watch(searchNotifierProvider);
    final AsyncValue<List<String>> history = ref.watch(searchHistoryProvider);
    final ThemeData theme = Theme.of(context);
    final double topInset = MediaQuery.paddingOf(context).top;
    final String? recentSearch = switch (history) {
      AsyncData<List<String>>(:final value) when value.isNotEmpty =>
        value.first,
      _ => null,
    };
    final DiscoveryHeaderMetrics discoveryMetrics =
        SearchHeaderLayout.discoveryMetrics(
          context,
          hasRecent: recentSearch != null,
        );
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
                      recentSearch: recentSearch,
                      quickSearches: _quickSearches,
                      activeKeyword: _searchController.text
                          .trim()
                          .toLowerCase(),
                      onSearchSelected: _runSearch,
                      onAllSelected: _clearSearch,
                    ),
                  ),
                ),
              ),
            ),
            ..._contentSlivers(searchState, history),
          ],
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(
    SearchState searchState,
    AsyncValue<List<String>> history,
  ) {
    return switch (searchState) {
      SearchInitial() => <Widget>[_initialContent(history)],
      SearchLoading() => const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(key: Key('initialSearchLoader')),
          ),
        ),
      ],
      SearchError(:final String message) => <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
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
        const <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: SearchMessage(
              icon: Icons.search_off_outlined,
              title: 'No products found',
              message: 'Try another search or choose a quick search above.',
            ),
          ),
        ],
      SearchLoaded() => _loadedContent(searchState),
    };
  }

  Widget _initialContent(AsyncValue<List<String>> history) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      sliver: SliverToBoxAdapter(
        child: history.when(
          data: (List<String> searches) {
            if (searches.isEmpty) {
              return const SearchMessage(
                icon: Icons.manage_search_outlined,
                title: 'Find your next product',
                message: 'Search for a product to get started.',
              );
            }
            return RecentSearches(searches: searches, onSelected: _runSearch);
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

  List<Widget> _loadedContent(SearchLoaded state) {
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        sliver: SliverGrid(
          key: const Key('productGrid'),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: 286,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final Product product = state.products[index];
            return ProductCard(
              key: ValueKey<String>('product-${product.id}'),
              product: product,
              onTap: () => _onProductSelected(product),
            );
          }, childCount: state.products.length),
        ),
      ),
      if (state.isLoadingNextPage)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
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
      SliverToBoxAdapter(child: SizedBox(height: bottomSafeArea + 24)),
    ];
  }
}
