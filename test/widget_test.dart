import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockathon/core/splash_screen.dart';

void main() {
  testWidgets('Splash Screen Smoke Test', (WidgetTester tester) async {
    // Build Splash Screen
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    // Verify Center Logo (Mockuplogo) is present
    expect(find.byType(Image), findsNWidgets(2)); // Expecting 2 images

    // We can't easily check asset paths in widget tests without more setup,
    // but finding 2 images is a good smoke test for now (Mockuplogo + softlogo).
  });
}
