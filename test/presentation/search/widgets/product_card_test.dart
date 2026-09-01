import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/design_system/gapsi_design_system.dart';
import 'package:gapsi_ecommerce/domain/entities/product.dart';
import 'package:gapsi_ecommerce/presentation/search/widgets/product_card.dart';

const Product _console = Product(
  id: 'console-1',
  title: 'Nintendo Switch OLED Console',
  price: 349.99,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  Product product = _console,
  bool isFavorite = false,
  VoidCallback? onTap,
  VoidCallback? onFavoriteToggle,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: GapsiTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            height: 286,
            child: ProductCard(
              product: product,
              isFavorite: isFavorite,
              onTap: onTap,
              onFavoriteToggle: onFavoriteToggle,
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _favoriteButton(String productId) =>
    find.byKey(ValueKey<String>('favoriteButton-$productId'));

void main() {
  testWidgets('muestra título y precio formateado a dos decimales', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester);

    expect(find.text('Nintendo Switch OLED Console'), findsOneWidget);
    expect(find.text(r'$349.99'), findsOneWidget);
    expect(find.text('Price unavailable'), findsNothing);
  });

  testWidgets('sin precio ni título usa los textos de reemplazo', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      product: const Product(id: 'sin-datos', title: ''),
    );

    expect(find.text('Product name unavailable'), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
  });

  testWidgets('un precio ausente no se disfraza de precio real', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      product: const Product(id: 'sin-precio', title: 'Producto'),
    );

    // El fallback no debe heredar el rol tipográfico del precio: un texto
    // secundario deja claro que el dato falta, un $0.00 se leería como gratis.
    final TextTheme textTheme = GapsiTheme.light().textTheme;
    final Text fallback = tester.widget<Text>(find.text('Price unavailable'));

    expect(fallback.style?.fontSize, textTheme.bodySmall!.fontSize);
    expect(fallback.style?.color, isNot(GapsiColors.blue));
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('el corazón refleja el estado y delega el toggle', (
    WidgetTester tester,
  ) async {
    int toggles = 0;
    int taps = 0;

    await _pumpCard(
      tester,
      isFavorite: true,
      onTap: () => taps++,
      onFavoriteToggle: () => toggles++,
    );

    expect(
      find.byKey(const ValueKey<String>('favoriteFilled-console-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('favoriteOutline-console-1')),
      findsNothing,
    );

    await tester.tap(_favoriteButton('console-1'));
    await tester.pump();

    // El corazón no debe abrir el detalle: los dos gestos conviven.
    expect(toggles, 1);
    expect(taps, isZero);
  });

  testWidgets('el tap en la tarjeta abre el detalle', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await _pumpCard(tester, onTap: () => taps++);

    await tester.tap(find.text('Nintendo Switch OLED Console'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('sin callback de favorito el botón queda deshabilitado', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, onTap: () {});

    final IconButton button = tester.widget<IconButton>(
      find.descendant(
        of: _favoriteButton('console-1'),
        matching: find.byType(IconButton),
      ),
    );

    // Mientras los favoritos no cargaron, el control se ve pero no acepta
    // toques: no hay a qué colección agregar todavía.
    expect(button.onPressed, isNull);
  });
}
