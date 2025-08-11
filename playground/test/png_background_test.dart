import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/png_background.dart';

void main() {
  group('PNG Background Tests', () {
    testWidgets('PngBackground renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PngBackground(
              child: const Center(
                child: Text('PNG Background Test'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('PNG Background Test'), findsOneWidget);
    });

    testWidgets('PngBackground with custom parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PngBackground(
              imageAssetPath: 'assets/background/background.png',
              fit: BoxFit.fill,
              enableOverlay: false,
              fallbackColor: Colors.red,
              child: const Center(
                child: Text('Custom PNG'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom PNG'), findsOneWidget);
    });

    testWidgets('SafePngBackground renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              child: const Center(
                child: Text('Safe PNG Background'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Safe PNG Background'), findsOneWidget);
    });

    testWidgets('SafePngBackground with custom overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              overlayColor: Colors.blue.withValues(alpha: 0.5),
              enableOverlay: true,
              child: const Center(
                child: Text('Custom Overlay'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Overlay'), findsOneWidget);
    });

    testWidgets('PngBackground without overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PngBackground(
              enableOverlay: false,
              child: const Center(
                child: Text('No Overlay'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Overlay'), findsOneWidget);
    });

    test('PngBackgroundUtils getOptimalFit works correctly', () {
      // 세로가 긴 화면 (폰)
      expect(
        PngBackgroundUtils.getOptimalFit(const Size(375, 667)),
        BoxFit.cover,
      );

      // 가로가 긴 화면 (태블릿 가로)
      expect(
        PngBackgroundUtils.getOptimalFit(const Size(1024, 600)),
        BoxFit.cover,
      );

      // 표준 비율 화면
      expect(
        PngBackgroundUtils.getOptimalFit(const Size(800, 800)),
        BoxFit.cover,
      );
    });

    test('PngBackgroundUtils getOptimalOverlayOpacity works correctly', () {
      // 작은 화면 (폰)
      final phoneOpacity = PngBackgroundUtils.getOptimalOverlayOpacity(
        const Size(375, 667),
      );
      expect(phoneOpacity, 0.35);

      // 중간 화면 (태블릿)
      final tabletOpacity = PngBackgroundUtils.getOptimalOverlayOpacity(
        const Size(768, 1024),
      );
      expect(tabletOpacity, 0.25);

      // 큰 화면 (데스크톱)
      final desktopOpacity = PngBackgroundUtils.getOptimalOverlayOpacity(
        const Size(1920, 1080),
      );
      expect(desktopOpacity, 0.2);
    });

    test('PngBackgroundUtils getPerformanceInfo provides detailed info', () {
      final info = PngBackgroundUtils.getPerformanceInfo(
        const Size(375, 667),
        'assets/background/background.png',
      );
      
      expect(info.contains('Screen: 375x667'), true);
      expect(info.contains('Asset: assets/background/background.png'), true);
      expect(info.contains('Optimal Fit:'), true);
      expect(info.contains('Overlay Opacity:'), true);
      expect(info.contains('Performance: High'), true);
    });

    testWidgets('PNG background adapts to different screen sizes', (WidgetTester tester) async {
      // 폰 사이즈로 테스트
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              child: const Center(
                child: Text('Phone Size'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Phone Size'), findsOneWidget);

      // 태블릿 사이즈로 테스트
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              child: const Center(
                child: Text('Tablet Size'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tablet Size'), findsOneWidget);
    });

    testWidgets('PNG background with non-existent image fails gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePngBackground(
              imageAssetPath: 'assets/nonexistent.png',
              child: const Center(
                child: Text('Fallback Test'),
              ),
            ),
          ),
        ),
      );

      // 콘텐츠는 여전히 표시되어야 함
      expect(find.text('Fallback Test'), findsOneWidget);
      
      // 약간의 시간을 기다려서 에러 처리 확인
      await tester.pumpAndSettle();
      expect(find.text('Fallback Test'), findsOneWidget);
    });
  });
}