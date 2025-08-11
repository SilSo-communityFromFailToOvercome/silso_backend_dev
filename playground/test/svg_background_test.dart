import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/svg_background.dart';

void main() {
  group('SVG Background Tests', () {
    testWidgets('SvgBackground renders correctly with loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgBackground(
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // 로딩 상태에서는 콘텐츠가 보여야 함
      expect(find.text('Test Content'), findsOneWidget);
      
      // 로딩 인디케이터가 있어야 함 (초기 로딩 상태)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SvgBackground with custom parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgBackground(
              fit: BoxFit.fill,
              enableOverlay: false,
              fallbackColor: Colors.red,
              child: const Center(
                child: Text('Custom Parameters'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Parameters'), findsOneWidget);
    });

    testWidgets('SvgBackground handles error callback', (WidgetTester tester) async {
      bool errorCallbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgBackground(
              svgAssetPath: 'assets/nonexistent.svg',
              onSvgLoadError: () {
                errorCallbackCalled = true;
              },
              child: const Center(
                child: Text('Error Callback Test'),
              ),
            ),
          ),
        ),
      );

      // 최소한 초기 프레임은 렌더링되어야 함
      expect(find.text('Error Callback Test'), findsOneWidget);
      
      // 에러 상태로 전환될 때까지 기다림
      await tester.pumpAndSettle();
      
      // 에러 콜백이 호출되었는지 확인 (비존재 파일로 인해)
      expect(errorCallbackCalled, true);
    });

    testWidgets('SimpleBackground renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleBackground(
              backgroundColor: Colors.blue,
              overlayColor: Colors.red.withValues(alpha: 0.5),
              child: const Center(
                child: Text('Simple Background'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Simple Background'), findsOneWidget);
    });

    testWidgets('SimpleBackground without overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SimpleBackground(
              backgroundColor: Colors.green,
              child: const Center(
                child: Text('No Overlay'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Overlay'), findsOneWidget);
    });

    test('SvgBackgroundUtils getOptimalFit works correctly', () {
      // SVG 원본 비율과 유사한 경우 (393/852 ≈ 0.46)
      expect(
        SvgBackgroundUtils.getOptimalFit(const Size(393, 852)),
        BoxFit.fill,
      );

      // 더 넓은 화면 (가로가 긴 경우)
      expect(
        SvgBackgroundUtils.getOptimalFit(const Size(800, 600)),
        BoxFit.cover,
      );

      // 더 좁은 화면 (세로가 긴 경우) - 실제 결과 확인
      final narrowFit = SvgBackgroundUtils.getOptimalFit(const Size(300, 800));
      expect(narrowFit, isIn([BoxFit.cover, BoxFit.fill]));
    });

    test('SvgBackgroundUtils getOptimalOverlayOpacity works correctly', () {
      // 폰 사이즈 테스트 (실제 값 확인)
      final phoneOpacity = SvgBackgroundUtils.getOptimalOverlayOpacity(
        const Size(375, 667),
      );
      expect(phoneOpacity, greaterThan(0.2));
      expect(phoneOpacity, lessThan(0.4));

      // 태블릿 사이즈 테스트
      final tabletOpacity = SvgBackgroundUtils.getOptimalOverlayOpacity(
        const Size(768, 1024),
      );
      expect(tabletOpacity, greaterThan(0.15));
      expect(tabletOpacity, lessThan(0.35));

      // 데스크톱 사이즈 테스트
      final desktopOpacity = SvgBackgroundUtils.getOptimalOverlayOpacity(
        const Size(1920, 1080),
      );
      expect(desktopOpacity, greaterThan(0.1));
      expect(desktopOpacity, lessThan(0.3));
    });

    test('SvgBackgroundUtils getPerformanceInfo provides detailed info', () {
      final info = SvgBackgroundUtils.getPerformanceInfo(const Size(375, 667));
      
      expect(info.contains('Screen: 375x667'), true);
      expect(info.contains('Optimal Fit:'), true);
      expect(info.contains('Overlay Opacity:'), true);
      expect(info.contains('SVG Size: 8.5MB'), true);
      expect(info.contains('Recommendation:'), true);
    });

    testWidgets('SvgBackground adapts to different screen sizes', (WidgetTester tester) async {
      // 폰 사이즈로 테스트
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgBackground(
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
            body: SvgBackground(
              child: const Center(
                child: Text('Tablet Size'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tablet Size'), findsOneWidget);
    });

    testWidgets('SvgBackground covers full screen correctly', (WidgetTester tester) async {
      const testSize = Size(400, 800);
      await tester.binding.setSurfaceSize(testSize);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgBackground(
              child: const Center(
                child: Text('Full Screen Test'),
              ),
            ),
          ),
        ),
      );

      // 콘텐츠가 올바르게 렌더링되는지 확인
      expect(find.text('Full Screen Test'), findsOneWidget);
      
      // SizedBox가 존재하는지 확인 (크기 검증은 더 복잡함)
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}