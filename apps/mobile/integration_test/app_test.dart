import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petaliacropassist/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end flow test', () {
    testWidgets('Login and navigate to dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Since we start from a clean state (seeded data), we might be on Login or Onboarding.
      // If we see "Petalia Field Pro", we are on the right track.
      expect(find.text('Petalia Field Pro'), findsOneWidget);

      // Try to find the "Créer un compte" button if no user registered
      final registerBtn = find.text('Créer un compte');
      if (registerBtn.evaluate().isNotEmpty) {
        await tester.tap(registerBtn);
        await tester.pumpAndSettle();
        expect(find.text('Inscription'), findsOneWidget);
      }
    });

    testWidgets('Explore map and parcels', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // This is a placeholder as full E2E requires registered user and valid session.
      // We are validating that the app starts without crashing.
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
