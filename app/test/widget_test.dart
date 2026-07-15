// Smoke test for a Firebase-independent widget.
//
// Full-app boot now initialises Firebase (auth-aware router), which isn't
// available in a plain widget test, so we verify a leaf widget instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savarun/core/widgets/savarun_logo.dart';

void main() {
  testWidgets('SavarunLogo renders the wordmark', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SavarunLogo())),
      ),
    );

    expect(find.text('SAVARUN'), findsOneWidget);
  });
}
