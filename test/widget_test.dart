import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hapa_app/features/auth/presentation/login_page.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    expect(find.text('Welcome to Hapa'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create a new account'), findsOneWidget);
  });
}
