import 'package:flutter_test/flutter_test.dart';
import 'package:appflutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RentEasyApp());
    expect(find.byType(RentEasyApp), findsOneWidget);
  });
}
