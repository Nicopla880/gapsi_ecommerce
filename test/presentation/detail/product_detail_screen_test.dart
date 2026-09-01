import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/presentation/detail/product_detail_screen.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_notifier.dart';
import 'package:gapsi_ecommerce/presentation/favorites/favorites_providers.dart';

class _FakeFavoritesNotifier extends FavoritesNotifier {
  _FakeFavoritesNotifier(this.initialIds);

  final Set<String> initialIds;

  @override
  Future<Set<String>> build() async => Set<String>.unmodifiable(initialIds);

  @override
  Future<bool> toggleFavorite(String productId) async {
    final Set<String> updated = Set<String>.of(state.requireValue);
    if (!updated.add(productId)) updated.remove(productId);
    state = AsyncData<Set<String>>(Set<String>.unmodifiable(updated));
    return true;
  }
}

Future<void> _pumpDetail(
  WidgetTester tester,
  Product product, {
  TextScaler? textScaler,
  Set<String> favoriteIds = const <String>{},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesProvider.overrideWith(
          () => _FakeFavoritesNotifier(favoriteIds),
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
        home: ProductDetailScreen(product: product),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final Finder scrollable = find.descendant(
    of: find.byKey(const Key('productDetailScrollView')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);
  await tester.pump();
}

void main() {
  testWidgets('refleja favorito persistido y permite quitarlo', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      const Product(id: 'favorite', title: 'Favorite product'),
      favoriteIds: const <String>{'favorite'},
    );

    expect(
      find.byKey(const Key('productDetailFavoriteFilled')),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.tap(find.byKey(const Key('productDetailFavoriteButton')));
    await tester.pump();

    expect(
      find.byKey(const Key('productDetailFavoriteOutline')),
      findsOneWidget,
    );
    expect(find.byTooltip('Add to favorites'), findsOneWidget);
  });

  testWidgets('muestra datos reales e infraestructura de imagen de red', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      const Product(
        id: '927771478',
        title: 'Nintendo Switch Lite - Blue',
        price: 132.30,
        thumbnailUrl: 'https://i5.walmartimages.com/asr/example.jpeg',
        description: 'Portable Nintendo console',
      ),
    );

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('productDetailNetworkImage')), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('productDetailTitle')));

    expect(find.text('Nintendo Switch Lite - Blue'), findsOneWidget);
    expect(find.text(r'$132.30'), findsOneWidget);
    expect(find.text('Portable Nintendo console'), findsOneWidget);
  });

  testWidgets('muestra fallbacks para precio, imagen y descripción ausentes', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      const Product(id: 'missing', title: 'Incomplete product'),
    );

    expect(
      find.byKey(const Key('productDetailImagePlaceholder')),
      findsOneWidget,
    );

    await _scrollTo(tester, find.byKey(const Key('productDetailDescription')));

    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.text('Description unavailable'), findsOneWidget);
  });

  testWidgets('convierte el HTML limitado de descripción a texto legible', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      const Product(
        id: 'html',
        title: 'Product with HTML description',
        description:
            '<ul><li>Portable &amp; lightweight</li>'
            '<li>Works <strong>well</strong></li></ul>',
      ),
    );

    await _scrollTo(tester, find.byKey(const Key('productDetailDescription')));

    final Text description = tester.widget<Text>(
      find.byKey(const Key('productDetailDescription')),
    );
    expect(description.data, '• Portable & lightweight\n• Works well');
    expect(find.textContaining('<li>'), findsNothing);
  });

  testWidgets(
    'título largo y escala alta renderizan en contenido scrolleable',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const String longTitle =
          'Nintendo Switch console bundle with a deliberately long product '
          'title that must wrap naturally without truncation';
      await _pumpDetail(
        tester,
        const Product(
          id: 'long',
          title: longTitle,
          price: 349.99,
          description:
              'A long but real-style description that remains readable while '
              'the user scrolls through the product detail content.',
        ),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text(longTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byKey(const Key('productDetailScrollView')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('A long but real-style description'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
