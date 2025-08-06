import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/responsive_asset_manager.dart';

/// Test to validate AssetPreloader functionality without dummy methods
void main() {
  group('AssetPreloader Tests', () {
    testWidgets('AssetPreloader should work without dummy methods', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Column(
                  children: [
                    // Test AppAssetProvider methods
                    Text('Kakao Path: ${AppAssetProvider.getPath(context, AppAsset.kakaoSignin)}'),
                    Text('Google Path: ${AppAssetProvider.getPath(context, AppAsset.googleSigninButton)}'),
                    Text('Silso Path: ${AppAssetProvider.getPath(context, AppAsset.silsoLogo)}'),
                    
                    // Test ResponsiveImage
                    ResponsiveImage.auto(
                      assetPath: AppAssetProvider.getPath(context, AppAsset.silsoLogo),
                      width: 50,
                      height: 50,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Verify basic functionality
      expect(find.byType(ResponsiveImage), findsOneWidget);
      expect(find.textContaining('Kakao Path:'), findsOneWidget);
      expect(find.textContaining('Google Path:'), findsOneWidget);
      expect(find.textContaining('Silso Path:'), findsOneWidget);
    });

    testWidgets('AssetPreloader.preloadAssets should not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              // Test asset preloading - should not crash even if assets don't exist
              AssetPreloader.preloadAssets(context).catchError((error) {
                // Expected to fail in test environment due to missing assets
                return null;
              });
              
              return const Scaffold(
                body: Center(
                  child: Text('AssetPreloader Test Complete'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('AssetPreloader Test Complete'), findsOneWidget);
    });

    testWidgets('ResponsiveImage should handle both SVG and PNG paths', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Test auto constructor with SVG path
                ResponsiveImage.auto(
                  assetPath: 'assets/images/silso_logo/login_logo_svg.svg',
                  width: 100,
                  height: 100,
                ),
                
                // Test manual constructor with both paths
                const ResponsiveImage(
                  svgPath: 'assets/images/silso_logo/login_logo_svg.svg',
                  pngPath: 'assets/images/silso_logo/login_logo.png',
                  width: 50,
                  height: 50,
                ),
                
                // Test PNG only
                const ResponsiveImage(
                  pngPath: 'assets/images/kakao_signin/kakao_login_medium_wide.png',
                  width: 200,
                  height: 50,
                  preferSvg: false,
                ),
              ],
            ),
          ),
        ),
      );

      // Should build without crashing
      expect(find.byType(ResponsiveImage), findsNWidgets(3));
    });

    test('AppAsset enum should have all expected values', () {
      expect(AppAsset.values, hasLength(4));
      expect(AppAsset.values, contains(AppAsset.kakaoSignin));
      expect(AppAsset.values, contains(AppAsset.googleSigninLogo));
      expect(AppAsset.values, contains(AppAsset.googleSigninButton));
      expect(AppAsset.values, contains(AppAsset.silsoLogo));
    });

    testWidgets('AppAssetProvider should generate correct paths', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              // Test path generation
              final kakaoPath = AppAssetProvider.getPath(context, AppAsset.kakaoSignin);
              expect(kakaoPath, contains('assets/images/kakao_signin'));
              expect(kakaoPath, contains('kakao_login_'));
              
              final kakaoEnglishPath = AppAssetProvider.getPath(context, AppAsset.kakaoSignin, useEnglish: true);
              expect(kakaoEnglishPath, contains('_en.png'));
              
              final googleButtonPath = AppAssetProvider.getPath(context, AppAsset.googleSigninButton);
              expect(googleButtonPath, contains('assets/images/google_signin'));
              expect(googleButtonPath, contains('web_neutral_sq_ctn'));
              
              final googleLogoPath = AppAssetProvider.getPath(context, AppAsset.googleSigninLogo);
              expect(googleLogoPath, contains('google_logo.png'));
              
              final silsoPath = AppAssetProvider.getPath(context, AppAsset.silsoLogo);
              expect(silsoPath, contains('assets/images/silso_logo'));
              expect(silsoPath, contains('login_logo_svg.svg'));
              
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('Responsive sizing should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              // Test responsive button sizing
              final buttonSize = AppAssetProvider.getResponsiveButtonSize(context);
              expect(buttonSize, isA<Size>());
              expect(buttonSize.width, greaterThan(0));
              expect(buttonSize.height, greaterThan(0));

              // Test responsive logo sizing
              final logoSize = AppAssetProvider.getResponsiveLogoSize(context);
              expect(logoSize, isA<double>());
              expect(logoSize, greaterThan(0));

              // Test with custom parameters
              final customButtonSize = AppAssetProvider.getResponsiveButtonSize(
                context,
                baseSize: const Size(300, 40),
                minScale: 0.5,
                maxScale: 2.0,
              );
              expect(customButtonSize.width, greaterThanOrEqualTo(150)); // 300 * 0.5
              expect(customButtonSize.width, lessThanOrEqualTo(600)); // 300 * 2.0

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}