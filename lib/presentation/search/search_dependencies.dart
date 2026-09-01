import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../core/utils/debouncer.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../../domain/usecases/get_search_history.dart';
import '../../domain/usecases/save_search_term.dart';
import '../../domain/usecases/search_products.dart';

/// Casos de uso que consume la capa de presentación.
///
/// GetIt conserva la composición existente de core/data y Riverpod expone
/// dependencias reemplazables para el estado y sus tests.
final Provider<SearchProducts> searchProductsUseCaseProvider =
    Provider<SearchProducts>(
      (Ref ref) => SearchProducts(getIt<ProductRepository>()),
    );

final Provider<SaveSearchTerm> saveSearchTermUseCaseProvider =
    Provider<SaveSearchTerm>(
      (Ref ref) => SaveSearchTerm(getIt<SearchHistoryRepository>()),
    );

final Provider<GetSearchHistory> getSearchHistoryUseCaseProvider =
    Provider<GetSearchHistory>(
      (Ref ref) => GetSearchHistory(getIt<SearchHistoryRepository>()),
    );

/// Instancia propia del ciclo de vida del provider de búsqueda.
final Provider<Debouncer> searchDebouncerProvider = Provider<Debouncer>((
  Ref ref,
) {
  final Debouncer debouncer = Debouncer();
  ref.onDispose(debouncer.dispose);
  return debouncer;
});

/// Historial persistido, separado del estado de resultados activo.
///
/// [SearchNotifier] lo invalida después de guardar un término para que una UI
/// que lo esté observando reciba la versión actualizada sin reiniciar la app.
final FutureProvider<List<String>> searchHistoryProvider =
    FutureProvider<List<String>>((Ref ref) {
      return ref.watch(getSearchHistoryUseCaseProvider)();
    });
