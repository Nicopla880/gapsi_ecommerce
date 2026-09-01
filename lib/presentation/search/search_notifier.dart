import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/debouncer.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/save_search_term.dart';
import '../../domain/usecases/search_products.dart';
import 'search_dependencies.dart';
import 'search_state.dart';

class SearchNotifier extends Notifier<SearchState> {
  late SearchProducts _searchProducts;
  late SaveSearchTerm _saveSearchTerm;
  late Debouncer _debouncer;

  String _latestQuery = '';
  String _activeQuery = '';
  int _searchGeneration = 0;

  @override
  SearchState build() {
    _searchProducts = ref.watch(searchProductsUseCaseProvider);
    _saveSearchTerm = ref.watch(saveSearchTermUseCaseProvider);
    _debouncer = ref.watch(searchDebouncerProvider);
    return const SearchInitial();
  }

  void onSearchChanged(String query) {
    final String normalizedQuery = query.trim();
    _latestQuery = normalizedQuery;

    // Invalida de inmediato tanto búsquedas como paginaciones en curso. Así un
    // resultado anterior no se muestra durante la ventana del debounce.
    final int generation = ++_searchGeneration;

    if (normalizedQuery.isEmpty) {
      _debouncer.cancel();
      _activeQuery = '';
      state = const SearchInitial();
      return;
    }

    _debouncer.run(() {
      unawaited(_search(normalizedQuery, generation));
    });
  }

  Future<void> _search(String query, int generation) async {
    if (!_isCurrentIntent(query, generation)) return;

    _activeQuery = query;
    state = const SearchLoading();

    try {
      final List<Product> products = await _searchProducts(
        keyword: query,
        page: 1,
      );

      if (!ref.mounted ||
          !_isCurrentIntent(query, generation) ||
          query != _activeQuery) {
        return;
      }

      state = SearchLoaded(
        products: products,
        currentPage: 1,
        // El contrato actual solo expone List<Product>, sin total ni pageSize.
        // Una página vacía es la única señal confiable de fin de resultados.
        hasReachedMax: products.isEmpty,
      );

      // La persistencia no bloquea la visualización ni convierte su propio
      // fallo en un error de búsqueda.
      unawaited(_saveTermAndRefreshHistory(query));
    } on Object catch (error) {
      if (!ref.mounted ||
          !_isCurrentIntent(query, generation) ||
          query != _activeQuery) {
        return;
      }
      state = SearchError(_readableMessage(error));
    }
  }

  Future<void> loadNextPage() async {
    final SearchState currentState = state;
    if (currentState is! SearchLoaded ||
        currentState.hasReachedMax ||
        currentState.isLoadingNextPage ||
        _activeQuery.isEmpty ||
        _latestQuery != _activeQuery) {
      return;
    }

    final SearchLoaded current = currentState;
    final String query = _activeQuery;
    final int generation = _searchGeneration;
    final int nextPage = current.currentPage + 1;

    state = current.copyWith(isLoadingNextPage: true, nextPageError: null);

    try {
      final List<Product> newProducts = await _searchProducts(
        keyword: query,
        page: nextPage,
      );

      if (!ref.mounted ||
          !_isCurrentIntent(query, generation) ||
          query != _activeQuery) {
        return;
      }

      state = SearchLoaded(
        products: _mergeProducts(current.products, newProducts),
        currentPage: nextPage,
        // No hay metadata ni un pageSize validado en el contrato actual.
        hasReachedMax: newProducts.isEmpty,
      );
    } on Object catch (error) {
      if (!ref.mounted ||
          !_isCurrentIntent(query, generation) ||
          query != _activeQuery) {
        return;
      }

      state = current.copyWith(
        isLoadingNextPage: false,
        nextPageError: _readableMessage(error),
      );
    }
  }

  /// Reintenta inmediatamente la última búsqueda inicial efectiva.
  Future<void> retry() {
    final String query = _activeQuery;
    if (query.isEmpty) return Future<void>.value();

    _debouncer.cancel();
    _latestQuery = query;
    final int generation = ++_searchGeneration;
    return _search(query, generation);
  }

  Future<void> retryNextPage() => loadNextPage();

  bool _isCurrentIntent(String query, int generation) {
    return generation == _searchGeneration && query == _latestQuery;
  }

  List<Product> _mergeProducts(List<Product> existing, List<Product> incoming) {
    final Set<String> ids = existing
        .map((Product product) => product.id)
        .toSet();
    return <Product>[
      ...existing,
      ...incoming.where((Product product) => ids.add(product.id)),
    ];
  }

  Future<void> _saveTermAndRefreshHistory(String query) async {
    try {
      await _saveSearchTerm(query);
    } on Object {
      // El historial es secundario: su fallo no altera resultados válidos ni
      // queda como Future sin manejar.
      return;
    }

    if (ref.mounted) ref.invalidate(searchHistoryProvider);
  }

  /// Traduce un error a una frase accionable para quien está buscando un
  /// producto.
  ///
  /// El mensaje interno de la excepción **no se propaga a propósito**: describe
  /// la falla en términos de transporte —un código de estado, el texto crudo
  /// que devuelva el API, el nombre de un timeout— y eso no le dice nada al
  /// usuario ni le indica qué hacer. Ese detalle es para los logs; acá solo
  /// importa el tipo de falla y si tiene sentido reintentar.
  String _readableMessage(Object error) {
    return switch (error) {
      NetworkException() ||
      NetworkFailure() => 'Check your connection and try again.',
      ServerException() || ServerFailure() =>
        "The store isn't responding right now. Please try again.",
      CacheException() || CacheFailure() => "We couldn't read your saved data.",
      _ => 'Something went wrong. Please try again.',
    };
  }
}
