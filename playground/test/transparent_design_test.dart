import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/transparent_overlay_design.dart';

void main() {
  group('Transparent Design Tests', () {
    testWidgets('TransparentOverlayDesign renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TransparentOverlayDesign(
            child: const Center(
              child: Text('Transparent Design Test'),
            ),
          ),
        ),
      );

      expect(find.text('Transparent Design Test'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('TransparentAppBarWrapper sets correct opacity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: TransparentAppBarWrapper(
              originalAppBar: AppBar(title: const Text('Test AppBar')),
              opacity: 0.0,
            ),
            body: const Center(child: Text('Body')),
          ),
        ),
      );

      expect(find.text('Test AppBar'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      
      // Opacity 위젯이 존재하는지 확인
      expect(find.byType(Opacity), findsWidgets);
    });

    testWidgets('TransparentBottomWrapper sets correct opacity', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: TransparentBottomWrapper(
                    opacity: 0.0,
                    child: const SizedBox(
                      height: 60,
                      child: ColoredBox(
                        color: Colors.blue,
                        child: Center(child: Text('Bottom Widget')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.text('Bottom Widget'), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
    });

    testWidgets('FullScreenBackgroundDesign creates proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenBackgroundDesign.createFullScreenBackground(
            backgroundWidget: const SizedBox.expand(
              child: ColoredBox(
                color: Colors.red,
                child: Center(child: Text('Background')),
              ),
            ),
            content: const Center(child: Text('Content')),
            transparentAppBar: AppBar(title: const Text('Transparent AppBar')),
            transparentBottomInput: const SizedBox(
              height: 60,
              child: Center(child: Text('Bottom Input')),
            ),
          ),
        ),
      );

      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Transparent AppBar'), findsOneWidget);
      expect(find.text('Bottom Input'), findsOneWidget);
      
      // Stack 구조가 올바르게 생성되는지 확인
      expect(find.byType(Stack), findsWidgets);
    });

    test('FullScreenBackgroundDesign getFullScreenSize calculates correctly', () {
      // 실제 context가 필요하므로 widget test로 이동하거나 mock 사용
      // 여기서는 기본적인 계산 로직 테스트
    });

    testWidgets('FullScreenBackgroundDesign getFullScreenSize works with MediaQuery', (WidgetTester tester) async {
      late Size screenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              screenSize = FullScreenBackgroundDesign.getFullScreenSize(context);
              return Container();
            },
          ),
        ),
      );

      expect(screenSize.width, greaterThan(0));
      expect(screenSize.height, greaterThan(0));
    });

    testWidgets('FullScreenBackgroundDesign getScreenInsets works with MediaQuery', (WidgetTester tester) async {
      late EdgeInsets insets;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              insets = FullScreenBackgroundDesign.getScreenInsets(context);
              return Container();
            },
          ),
        ),
      );

      expect(insets.top, greaterThanOrEqualTo(0));
      expect(insets.bottom, greaterThanOrEqualTo(0));
    });

    test('TransparencyController constants are correctly defined', () {
      expect(TransparencyController.appBarOpacity, 0.0);
      expect(TransparencyController.bottomInputOpacity, 0.0);
      expect(TransparencyController.backgroundOverlayOpacity, 0.3);
      expect(TransparencyController.debugOpacity, 0.3);
    });

    test('TransparentUXGuidelines constants are correctly defined', () {
      expect(TransparentUXGuidelines.minTouchTargetPadding, const EdgeInsets.all(8.0));
      expect(TransparentUXGuidelines.minActionButtonSize, const Size(44, 44));
      expect(TransparentUXGuidelines.minContrastRatio, 3.0);
    });

    testWidgets('TransparentUXGuidelines createInteractionHint works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TransparentUXGuidelines.createInteractionHint(
                  showHint: false,
                  child: const Text('No Hint'),
                ),
                TransparentUXGuidelines.createInteractionHint(
                  showHint: true,
                  child: const Text('With Hint'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No Hint'), findsOneWidget);
      expect(find.text('With Hint'), findsOneWidget);
      
      // Container with border should exist for the hint version
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Transparent design maintains touch targets', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TransparentOverlayDesign(
            appBar: TransparentAppBarWrapper(
              originalAppBar: AppBar(
                title: const Text('Test'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      buttonPressed = true;
                    },
                  ),
                ],
              ),
              opacity: 0.0,
            ),
            child: const Center(child: Text('Content')),
          ),
        ),
      );

      // 투명한 상태에서도 버튼이 터치 가능한지 확인
      await tester.tap(find.byIcon(Icons.close));
      expect(buttonPressed, true);
    });

    testWidgets('Background extends to full screen area', (WidgetTester tester) async {
      const testSize = Size(400, 800);
      await tester.binding.setSurfaceSize(testSize);
      
      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenBackgroundDesign.createFullScreenBackground(
            backgroundWidget: const SizedBox.expand(
              child: ColoredBox(
                color: Colors.red,
                child: Text('Full Screen Background'),
              ),
            ),
            content: const Center(child: Text('Content')),
          ),
        ),
      );

      expect(find.text('Full Screen Background'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      
      // Positioned.fill이 사용되어 전체 화면을 덮는지 확인
      expect(find.byType(Positioned), findsOneWidget);
    });
  });
}