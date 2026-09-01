import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/domain/entities/favorites_collection.dart';
import 'package:gapsi_ecommerce/main.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_notifier.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_providers.dart';
import 'package:gapsi_ecommerce/presentation/search/search_notifier.dart';
import 'package:gapsi_ecommerce/presentation/search/search_providers.dart';
import 'package:gapsi_ecommerce/presentation/search/search_state.dart';

class _InitialSearchNotifier extends SearchNotifier {
  @override
  SearchState build() => const SearchInitial();
}

class _EmptyFavoritesNotifier extends FavoritesNotifier {
  @override
  Future<FavoritesCollection> build() async => FavoritesCollection();
}

void main() {
  testWidgets('GapsiApp monta sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchNotifierProvider.overrideWith(_InitialSearchNotifier.new),
          searchHistoryProvider.overrideWith(
            (Ref ref) async => const <String>[],
          ),
          favoritesProvider.overrideWith(_EmptyFavoritesNotifier.new),
        ],
        child: const GapsiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GapsiApp), findsOneWidget);
  });
}
