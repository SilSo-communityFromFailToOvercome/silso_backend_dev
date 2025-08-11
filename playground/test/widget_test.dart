// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:judge/controllers/chat_controller.dart';
import 'package:judge/views/chat_bubble_view.dart';
import 'package:judge/models/chat_model.dart';

void main() {
  testWidgets('Chat controller unit test', (WidgetTester tester) async {
    // Test the ChatController directly without UI complications
    final controller = ChatController();
    
    // Create a mock context
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // Verify initial state
            expect(controller.messages.length, 0);
            expect(controller.isLimitReached, false);
            expect(controller.showResetNotice, false);

            // Test adding a message
            controller.addMessage('Test message', context);
            
            return Container();
          },
        ),
      ),
    );

    // Verify message was added
    expect(controller.messages.length, 1);
    expect(controller.messages.first.text, 'Test message');

    controller.dispose();
  });

  testWidgets('Chat bubble view test', (WidgetTester tester) async {
    // Test ChatBubbleView component
    final testMessage = Message(text: 'Test Bubble', isLeft: true);
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatBubbleView(message: testMessage),
        ),
      ),
    );

    // Verify the bubble displays the message text
    expect(find.text('Test Bubble'), findsOneWidget);
  });

  testWidgets('Bottom input view test', (WidgetTester tester) async {
    final controller = TextEditingController();
    bool sendPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomInputView(
            controller: controller,
            participantCount: 100,
            onSend: () {
              sendPressed = true;
            },
          ),
        ),
      ),
    );

    // Verify input field exists
    expect(find.byType(TextField), findsOneWidget);
    
    // Verify participant count is displayed
    expect(find.text('현재 참여자 수: 100명'), findsOneWidget);

    // Test send button
    await tester.tap(find.byIcon(Icons.send));
    expect(sendPressed, true);

    controller.dispose();
  });
}
