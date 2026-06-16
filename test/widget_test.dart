import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:konecta/app.dart';

void main() {
  testWidgets('KonectaApp arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KonectaApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
