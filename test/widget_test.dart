import 'package:flutter_test/flutter_test.dart';
import 'package:pockify/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PockifyApp());
    // Just verifying it builds and launches
    expect(find.byType(PockifyApp), findsOneWidget);
  });
}
