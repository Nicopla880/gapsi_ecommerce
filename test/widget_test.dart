import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gapsi_ecommerce/main.dart';

void main() {
  testWidgets('GapsiApp monta sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GapsiApp()));

    expect(find.byType(GapsiApp), findsOneWidget);
  });
}
