// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import '../lib/utils/responsive_asset_manager.dart';

// /// Test to validate ResponsiveAssetManager methods are properly defined
// void main() {
//   group('ResponsiveAssetManager Tests', () {
//     testWidgets('All methods should be defined and accessible', (WidgetTester tester) async {
//       // Create a test widget with a BuildContext
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Builder(
//             builder: (BuildContext context) {
//               // Test getResponsiveButtonSize method
//               final buttonSize = ResponsiveAssetManager.getResponsiveButtonSize(
//                 context,
//                 baseSize: const Size(360, 52),
//               );
//               expect(buttonSize, isA<Size>());
//               expect(buttonSize.width, greaterThan(0));
//               expect(buttonSize.height, greaterThan(0));

//               // Test getResponsiveLogoSize method
//               final logoSize = ResponsiveAssetManager.getResponsiveLogoSize(
//                 context,
//                 baseSize: 120,
//               );
//               expect(logoSize, isA<double>());
//               expect(logoSize, greaterThan(0));

//               // Test getDeviceType method
//               final deviceType = ResponsiveAssetManager.getDeviceType(context);
//               expect(deviceType, isA<DeviceType>());

//               // Test asset path methods
//               final kakaoAsset = ResponsiveAssetManager.getKakaoSigninAsset(context);
//               expect(kakaoAsset, isA<String>());
//               expect(kakaoAsset, contains('kakao_signin'));

//               final googleAsset = ResponsiveAssetManager.getGoogleSigninAsset(context);
//               expect(googleAsset, isA<String>());
//               expect(googleAsset, contains('google_signin'));

//               final silsoAsset = ResponsiveAssetManager.getSilsoLogoAsset(context);
//               expect(silsoAsset, isA<String>());
//               expect(silsoAsset, contains('silso_logo'));

//               // Test responsive font size
//               final fontSize = ResponsiveAssetManager.getResponsiveFontSize(
//                 context,
//                 baseSize: 16.0,
//               );
//               expect(fontSize, isA<double>());
//               expect(fontSize, greaterThan(0));

//               // Test responsive padding
//               final padding = ResponsiveAssetManager.getResponsivePadding(context);
//               expect(padding, isA<EdgeInsets>());

//               // Test device type helpers
//               expect(ResponsiveAssetManager.isMobile(context), isA<bool>());
//               expect(ResponsiveAssetManager.isTablet(context), isA<bool>());
//               expect(ResponsiveAssetManager.isDesktop(context), isA<bool>());

//               return const Scaffold(
//                 body: Center(
//                   child: Text('ResponsiveAssetManager Test Complete'),
//                 ),
//               );
//             },
//           ),
//         ),
//       );

//       // Verify the widget builds without errors
//       expect(find.text('ResponsiveAssetManager Test Complete'), findsOneWidget);
//     });

//     testWidgets('ResponsiveImage should handle asset paths correctly', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Builder(
//             builder: (BuildContext context) {
//               return Scaffold(
//                 body: Column(
//                   children: [
//                     // Test ResponsiveImage.auto constructor
//                     ResponsiveImage.auto(
//                       assetPath: 'assets/images/silso_logo/login_logo_svg.svg',
//                       width: 100,
//                       height: 100,
//                     ),
//                     // Test regular ResponsiveImage constructor
//                     const ResponsiveImage(
//                       svgPath: 'assets/images/silso_logo/login_logo_svg.svg',
//                       pngPath: 'assets/images/silso_logo/login_logo.png',
//                       width: 50,
//                       height: 50,
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       );

//       // Verify ResponsiveImage widgets build without errors
//       expect(find.byType(ResponsiveImage), findsNWidgets(2));
//     });

//     test('DeviceType enum should have all expected values', () {
//       expect(DeviceType.values, hasLength(3));
//       expect(DeviceType.values, contains(DeviceType.mobile));
//       expect(DeviceType.values, contains(DeviceType.tablet));
//       expect(DeviceType.values, contains(DeviceType.desktop));
//     });

//     testWidgets('Asset paths should be correctly formatted', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Builder(
//             builder: (BuildContext context) {
//               // Test asset path generation
//               final kakaoAsset = ResponsiveAssetManager.getKakaoSigninAsset(context);
//               expect(kakaoAsset, contains('assets/images/kakao_signin'));
              
//               final googleAsset = ResponsiveAssetManager.getGoogleSigninAsset(context);
//               expect(googleAsset, contains('assets/images/google_signin'));
              
//               final silsoAsset = ResponsiveAssetManager.getSilsoLogoAsset(context);
//               expect(silsoAsset, contains('assets/images/silso_logo'));
              
//               return const SizedBox();
//             },
//           ),
//         ),
//       );
//     });
//   });

//   group('AssetPreloader Tests', () {
//     testWidgets('AssetPreloader should not crash on preload', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Builder(
//             builder: (BuildContext context) {
//               // Test asset preloading (should not crash even if assets don't exist)
//               AssetPreloader.preloadAssets(context).catchError((error) {
//                 // Silent catch for missing assets in test environment
//                 return null;
//               });
              
//               return const Scaffold(
//                 body: Center(
//                   child: Text('AssetPreloader Test Complete'),
//                 ),
//               );
//             },
//           ),
//         ),
//       );

//       expect(find.text('AssetPreloader Test Complete'), findsOneWidget);
//     });
//   });
// }