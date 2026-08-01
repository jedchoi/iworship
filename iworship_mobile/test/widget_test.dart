import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('iWorship App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('아이워십 (iWorship)')),
      ),
    );
    expect(find.text('아이워십 (iWorship)'), findsOneWidget);
  });
}
