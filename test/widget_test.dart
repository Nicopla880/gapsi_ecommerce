import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaspi_ecommerce/main.dart';

void main() {
  testWidgets('GaspiApp monta sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GaspiApp()));

    expect(find.byType(GaspiApp), findsOneWidget);
  });
}
