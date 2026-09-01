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

class _FakeFavoritesNotifier extends FavoritesNotifier {
  _FakeFavoritesNotifier(this.initialProducts);

  final List<Product> initialProducts;

  @override
  Future<FavoritesCollection> build() async =>
      FavoritesCollection(products: initialProducts);

  @override
  Future<bool> toggleFavorite(Product product) async {
    final FavoritesCollection current = state.requireValue;
    state = AsyncData<FavoritesCollection>(
      current.setFavorite(product, value: !current.contains(product.id)),
    );
    return true;
  }
}

Future<void> _pumpDetail(
  WidgetTester tester,
  Product product, {
  TextScaler? textScaler,
  List<Product> favoriteProducts = const <Product>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesProvider.overrideWith(
          () => _FakeFavoritesNotifier(favoriteProducts),
        ),
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
      favoriteProducts: const <Product>[
        Product(id: 'favorite', title: 'Favorite product'),
      ],
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

  testWidgets('la imagen comparte el Hero con la tarjeta de origen', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      const Product(id: 'console-1', title: 'Nintendo Switch OLED Console'),
    );

    final List<Object> tags = tester
        .widgetList<Hero>(find.byType(Hero))
        .map((Hero hero) => hero.tag)
        .toList(growable: false);

    expect(tags, <Object>['productImage-console-1']);
  });

  testWidgets('el precio usa el rol tipográfico más prominente del tema', (
    WidgetTester tester,
  ) async {
    await _pumpDetail(
      tester,
      const Product(id: 'p1', title: 'Product', price: 12.5),
    );

    // La imagen cuadrada ocupa el primer viewport, asi que el bloque de texto
    // llega recien despues de desplazarse.
    await _scrollTo(tester, find.byKey(const Key('productDetailPrice')));

    final RenderParagraph price =
        tester.renderObject(find.byKey(const Key('productDetailPrice')))
            as RenderParagraph;
    final TextTheme textTheme = GapsiTheme.light().textTheme;

    expect(price.text.style?.fontFamily, GapsiTypography.fontFamily);
    expect(price.text.style?.color, GapsiColors.blue);
    expect(price.text.style?.fontSize, textTheme.headlineMedium!.fontSize);
    expect(
      price.text.style!.fontSize,
      greaterThan(textTheme.headlineSmall!.fontSize!),
    );
  });
}
