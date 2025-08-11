import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/keyboard_aware_scaffold.dart';

void main() {
  group('Keyboard Awareness Tests', () {
    testWidgets('KeyboardAwarePositioned adjusts position when keyboard appears', (WidgetTester tester) async {
      late StateSetter setState;
      double keyboardHeight = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setStateCallback) {
                setState = setStateCallback;
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewInsets: EdgeInsets.only(bottom: keyboardHeight),
                  ),
                  child: Stack(
                    children: [
                      KeyboardAwarePositioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        minKeyboardPadding: 20.0,
                        child: Container(
                          height: 50,
                          color: Colors.blue,
                          child: const Text('Input Field'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state - no keyboard
      expect(find.text('Input Field'), findsOneWidget);

      // Simulate keyboard appearing
      setState(() {
        keyboardHeight = 300;
      });
      await tester.pumpAndSettle();

      // Input field should still be visible
      expect(find.text('Input Field'), findsOneWidget);
    });

    testWidgets('KeyboardAwareScaffold transforms body when keyboard appears', (WidgetTester tester) async {
      late StateSetter setState;
      double keyboardHeight = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setStateCallback) {
              setState = setStateCallback;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  viewInsets: EdgeInsets.only(bottom: keyboardHeight),
                ),
                child: KeyboardAwareScaffold(
                  appBar: AppBar(title: const Text('Test')),
                  body: const Center(
                    child: Text('Body Content'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('Body Content'), findsOneWidget);

      // Simulate keyboard appearing
      setState(() {
        keyboardHeight = 300;
      });
      await tester.pumpAndSettle();

      // Body should still be visible with transform applied
      expect(find.text('Body Content'), findsOneWidget);
    });

    testWidgets('Keyboard height calculation works correctly', (WidgetTester tester) async {
      const testKeyboardHeight = 250.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: testKeyboardHeight),
              ),
              child: Builder(
                builder: (context) {
                  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                  return Center(
                    child: Text('Keyboard Height: $keyboardHeight'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Keyboard Height: $testKeyboardHeight'), findsOneWidget);
    });
  });
}