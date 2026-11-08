import 'package:flutter_test/flutter_test.dart';
import 'package:textile_balancer_flutter/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TextileLineBalancerApp());
    expect(find.textContaining('Équilibrez vos lignes'), findsOneWidget);
  });
}