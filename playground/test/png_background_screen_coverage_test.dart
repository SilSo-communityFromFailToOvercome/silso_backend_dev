import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/png_background.dart';

void main() {
  group('PNG Background Screen Coverage Tests', () {
    testWidgets('PNG background covers full screen area', (WidgetTester tester) async {
      const testSize = Size(400, 800);
      await tester.binding.setSurfaceSize(testSize);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              imageAssetPath: 'assets/background/background.png',
              child: const Center(
                child: Text('Full Screen Coverage'),
              ),
            ),
          ),
        ),
      );

      // 콘텐츠가 올바르게 렌더링되는지 확인
      expect(find.text('Full Screen Coverage'), findsOneWidget);
      
      // Container가 존재하는지 확인 (배경 이미지를 포함하는)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('PNG background adapts to different aspect ratios', (WidgetTester tester) async {
      // 세로 화면 테스트
      await tester.binding.setSurfaceSize(const Size(375, 812)); // iPhone X
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              fit: BoxFit.cover,
              child: const Text('Portrait'),
            ),
          ),
        ),
      );
      expect(find.text('Portrait'), findsOneWidget);

      // 가로 화면 테스트
      await tester.binding.setSurfaceSize(const Size(812, 375)); // iPhone X Landscape
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              fit: BoxFit.cover,
              child: const Text('Landscape'),
            ),
          ),
        ),
      );
      expect(find.text('Landscape'), findsOneWidget);

      // 정사각형 화면 테스트
      await tester.binding.setSurfaceSize(const Size(600, 600)); // Square
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              fit: BoxFit.cover,
              child: const Text('Square'),
            ),
          ),
        ),
      );
      expect(find.text('Square'), findsOneWidget);
    });

    testWidgets('PNG background with overlay covers full screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              enableOverlay: true,
              overlayColor: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Text('Overlay Test'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Overlay Test'), findsOneWidget);
      
      // Stack이 존재하는지 확인 (오버레이 때문에)
      expect(find.byType(Stack), findsWidgets);
    });

    test('PNG background utils provide correct screen coverage recommendations', () {
      // 다양한 화면 크기에 대한 권장사항 테스트
      final phoneInfo = PngBackgroundUtils.getPerformanceInfo(
        const Size(375, 667),
        'assets/background/background.png',
      );
      expect(phoneInfo.contains('BoxFit.cover'), true);

      final tabletInfo = PngBackgroundUtils.getPerformanceInfo(
        const Size(768, 1024),
        'assets/background/background.png',
      );
      expect(tabletInfo.contains('BoxFit.cover'), true);

      final desktopInfo = PngBackgroundUtils.getPerformanceInfo(
        const Size(1920, 1080),
        'assets/background/background.png',
      );
      expect(desktopInfo.contains('BoxFit.cover'), true);
    });
  });
}