import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge/widgets/responsive_background.dart';

void main() {
  group('Responsive Background Tests', () {
    testWidgets('ResponsiveBackground renders with default settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBackground(
              child: const Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('ResponsiveBackground handles custom overlay color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBackground(
              overlayColor: Colors.red.withValues(alpha: 0.5),
              child: const Center(
                child: Text('Custom Overlay'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Overlay'), findsOneWidget);
    });

    testWidgets('ResponsiveBackground with custom BoxFit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBackground(
              fit: BoxFit.fitHeight,
              child: const Center(
                child: Text('Custom Fit'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Fit'), findsOneWidget);
    });

    testWidgets('ResponsiveBackground handles null background asset', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBackground(
              backgroundAssetPath: null,
              child: const Center(
                child: Text('No Background'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Background'), findsOneWidget);
    });

    test('BackgroundImageUtils getScreenCategory works correctly', () {
      // Desktop size
      expect(
        BackgroundImageUtils.getScreenCategory(const Size(1920, 1080)),
        ScreenSizeCategory.desktop,
      );

      // Tablet size (adjust size to be within tablet range)
      expect(
        BackgroundImageUtils.getScreenCategory(const Size(600, 800)),
        ScreenSizeCategory.tablet,
      );

      // Phone portrait (smaller diagonal)
      expect(
        BackgroundImageUtils.getScreenCategory(const Size(320, 568)),
        ScreenSizeCategory.phonePortrait,
      );

      // Phone landscape (smaller diagonal)
      expect(
        BackgroundImageUtils.getScreenCategory(const Size(568, 320)),
        ScreenSizeCategory.phoneLandscape,
      );
    });

    test('BackgroundImageUtils getOptimalConfig returns correct configs', () {
      final desktopConfig = BackgroundImageUtils.getOptimalConfig(
        ScreenSizeCategory.desktop,
      );
      expect(desktopConfig.fit, BoxFit.cover);
      expect(desktopConfig.overlayOpacity, 0.2);

      final phoneConfig = BackgroundImageUtils.getOptimalConfig(
        ScreenSizeCategory.phonePortrait,
      );
      expect(phoneConfig.fit, BoxFit.cover);
      expect(phoneConfig.overlayOpacity, 0.35);
    });

    test('BackgroundImageUtils getOptimizationInfo provides detailed info', () {
      final info = BackgroundImageUtils.getOptimizationInfo(const Size(375, 667));
      
      expect(info.contains('Screen: 375x667'), true);
      expect(info.contains('Aspect Ratio:'), true);
      expect(info.contains('Category:'), true);
      expect(info.contains('Optimal Fit:'), true);
    });

    testWidgets('ResponsiveBackground adapts to different screen sizes', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(375, 667)); // Phone
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBackground(
              child: const Center(
                child: Text('Phone Size'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Phone Size'), findsOneWidget);

      // Test with tablet size
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // Tablet
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBackground(
              child: const Center(
                child: Text('Tablet Size'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tablet Size'), findsOneWidget);
    });
  });
}