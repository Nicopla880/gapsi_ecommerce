import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/design_system/gapsi_design_system.dart';

void main() {
  group('GapsiTheme', () {
    test('expone la paleta y la tipografía de marca', () {
      final ThemeData theme = GapsiTheme.light();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, GapsiColors.blue);
      expect(theme.colorScheme.primaryContainer, GapsiColors.blueSoft);
      expect(theme.scaffoldBackgroundColor, GapsiColors.background);
      expect(theme.colorScheme.onSurface, GapsiColors.textPrimary);
      expect(theme.colorScheme.onSurfaceVariant, GapsiColors.textSecondary);
    });

    test('todos los roles de texto resuelven a Manrope', () {
      final TextTheme textTheme = GapsiTheme.light().textTheme;
      final List<TextStyle?> roles = <TextStyle?>[
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
      ];

      for (final TextStyle? style in roles) {
        expect(style?.fontFamily, GapsiTypography.fontFamily);
      }
    });

    test('solo usa los pesos empaquetados en pubspec', () {
      final TextTheme textTheme = GapsiTheme.light().textTheme;
      final Set<FontWeight> bundled = <FontWeight>{
        GapsiTypography.regular,
        GapsiTypography.semiBold,
        GapsiTypography.bold,
        GapsiTypography.extraBold,
      };

      for (final TextStyle? style in <TextStyle?>[
        textTheme.headlineMedium,
        textTheme.headlineSmall,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.titleSmall,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.bodySmall,
        textTheme.labelLarge,
        textTheme.labelMedium,
        textTheme.labelSmall,
      ]) {
        expect(bundled, contains(style?.fontWeight));
      }
    });

    test('la jerarquía de precio, título y cuerpo es distinguible', () {
      final TextTheme textTheme = GapsiTheme.light().textTheme;

      // Precio del detalle > título del detalle > precio de tarjeta > título
      // de tarjeta > cuerpo.
      expect(
        textTheme.headlineMedium!.fontSize,
        greaterThan(textTheme.headlineSmall!.fontSize!),
      );
      expect(
        textTheme.headlineSmall!.fontSize,
        greaterThan(textTheme.titleMedium!.fontSize!),
      );
      expect(
        textTheme.titleMedium!.fontSize,
        greaterThan(textTheme.titleSmall!.fontSize!),
      );
      expect(textTheme.titleMedium!.fontWeight, GapsiTypography.extraBold);
      expect(textTheme.bodyLarge!.fontWeight, GapsiTypography.regular);
    });
  });

  group('GapsiEntrance', () {
    Widget host({required bool disableAnimations}) {
      return MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: GapsiEntrance(child: Text('content')),
        ),
      );
    }

    double opacityOf(WidgetTester tester) {
      return tester
          .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .opacity;
    }

    testWidgets('aparece con un fundido corto', (WidgetTester tester) async {
      await tester.pumpWidget(host(disableAnimations: false));
      expect(opacityOf(tester), 0);

      await tester.pump();
      expect(opacityOf(tester), 1);

      await tester.pumpAndSettle();
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('respeta la preferencia de movimiento reducido', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(disableAnimations: true));

      // Sin animación: el contenido ya está en su estado final en el primer
      // frame.
      expect(opacityOf(tester), 1);
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
        Offset.zero,
      );
    });

    test('el escalonado solo alcanza al primer tramo visible', () {
      expect(GapsiEntrance.staggerFor(0), Duration.zero);
      expect(GapsiEntrance.staggerFor(3), GapsiMotion.entranceStagger * 3);
      expect(
        GapsiEntrance.staggerFor(GapsiMotion.entranceStaggerCount),
        Duration.zero,
      );
      expect(GapsiEntrance.staggerFor(120), Duration.zero);
    });
  });

  group('GapsiFavoriteButton', () {
    Widget host({
      required bool isFavorite,
      required VoidCallback onPressed,
      bool disableAnimations = false,
    }) {
      return MaterialApp(
        theme: GapsiTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Center(
              child: GapsiFavoriteButton(
                isFavorite: isFavorite,
                onPressed: onPressed,
                filled: true,
                filledIconKey: const Key('filled'),
                outlineIconKey: const Key('outline'),
              ),
            ),
          ),
        ),
      );
    }

    double scaleOf(WidgetTester tester) {
      return tester
          .widget<ScaleTransition>(
            find.descendant(
              of: find.byType(GapsiFavoriteButton),
              matching: find.byType(ScaleTransition),
            ),
          )
          .scale
          .value;
    }

    testWidgets('el pulso no bloquea el tap ni pierde la etiqueta', (
      WidgetTester tester,
    ) async {
      bool isFavorite = false;
      int taps = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return host(
              isFavorite: isFavorite,
              onPressed: () => setState(() {
                taps++;
                isFavorite = !isFavorite;
              }),
            );
          },
        ),
      );

      expect(find.byTooltip('Add to favorites'), findsOneWidget);
      expect(find.byKey(const Key('outline')), findsOneWidget);

      await tester.tap(find.byType(GapsiFavoriteButton));
      await tester.pump();
      expect(find.byKey(const Key('filled')), findsOneWidget);
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);

      // A mitad del pulso el corazón está agrandado y el botón sigue
      // aceptando toques.
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleOf(tester), greaterThan(1.0));
      await tester.tap(find.byType(GapsiFavoriteButton));
      await tester.pump();

      expect(taps, 2);
      expect(find.byKey(const Key('outline')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('mantiene el área táctil mínima de Material', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(isFavorite: false, onPressed: () {}));

      final Size size = tester.getSize(find.byType(GapsiFavoriteButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('con movimiento reducido no anima la escala', (
      WidgetTester tester,
    ) async {
      bool isFavorite = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return host(
              isFavorite: isFavorite,
              disableAnimations: true,
              onPressed: () => setState(() => isFavorite = !isFavorite),
            );
          },
        ),
      );

      await tester.tap(find.byType(GapsiFavoriteButton));
      await tester.pump();

      // El estado cambia igual; lo que no ocurre es el pulso de escala.
      expect(find.byKey(const Key('filled')), findsOneWidget);
      expect(scaleOf(tester), 1.0);
      await tester.pump(const Duration(milliseconds: 90));
      expect(scaleOf(tester), 1.0);
      await tester.pumpAndSettle();
    });
  });
}
