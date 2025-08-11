import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/debug_background.dart';

void main() {
  group('Debug Background Tests', () {
    testWidgets('SimpleColorBackground renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleColorBackground(
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('SimpleColorBackground with custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleColorBackground(
              backgroundColor: Colors.blue,
              overlayColor: Colors.red.withValues(alpha: 0.5),
              child: const Center(
                child: Text('Custom Colors'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Colors'), findsOneWidget);
    });

    testWidgets('SimpleColorBackground with null overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleColorBackground(
              backgroundColor: const Color(0xFF3F3329),
              child: const Center(
                child: Text('No Overlay'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Overlay'), findsOneWidget);
    });
  });
}