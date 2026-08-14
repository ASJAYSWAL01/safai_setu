import 'package:flutter_test/flutter_test.dart';

import 'package:safai_setu/main.dart';

void main() {
  testWidgets('Login page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SafaiSetuApp());

    expect(find.text('Safai Setu'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}
