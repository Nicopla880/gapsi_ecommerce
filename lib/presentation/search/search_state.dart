import 'package:equatable/equatable.dart';

import '../../domain/entities/product.dart';

/// Estado inmutable de la búsqueda de productos.
sealed class SearchState extends Equatable {
  const SearchState();
}

final class SearchInitial extends SearchState {
  const SearchInitial();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SearchLoading extends SearchState {
  const SearchLoading();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SearchLoaded extends SearchState {
  SearchLoaded({
    required List<Product> products,
    required this.currentPage,
    required this.hasReachedMax,
    this.isLoadingNextPage = false,
    this.nextPageError,
  }) : products = List<Product>.unmodifiable(products);

  /// Copia no modificable para que el estado no pueda mutar desde la UI.
  final List<Product> products;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingNextPage;
  final String? nextPageError;

  static const Object _keepNextPageError = Object();

  SearchLoaded copyWith({
    List<Product>? products,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingNextPage,
    Object? nextPageError = _keepNextPageError,
  }) {
    return SearchLoaded(
      products: products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      nextPageError: identical(nextPageError, _keepNextPageError)
          ? this.nextPageError
          : nextPageError as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    products,
    currentPage,
    hasReachedMax,
    isLoadingNextPage,
    nextPageError,
  ];
}

final class SearchError extends SearchState {
  const SearchError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
