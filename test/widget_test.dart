import 'package:flutter_test/flutter_test.dart';
import 'package:presence_manager/main.dart';

void main() {
  testWidgets('Test initial app rendering', (WidgetTester tester) async {
    await tester.pumpWidget(const PresenceManagerApp());
    expect(find.text('Liste des Individus'), findsOneWidget);
  });
}
