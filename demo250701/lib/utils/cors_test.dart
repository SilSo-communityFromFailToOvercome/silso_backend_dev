import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// CORS testing utility for web platform
class CorsTest {
  /// Test CORS configuration by attempting to fetch an image from Firebase Storage
  static Future<bool> testFirebaseStorageCors(String imageUrl) async {
    if (!kIsWeb) {
      // CORS only applies to web, return true for other platforms
      return true;
    }

    try {
      // Method 1: Try to load image with fetch API to test CORS
      final response = await html.window.fetch(
        imageUrl,
        {
          'mode': 'cors',
          'method': 'GET',
        },
      );

      if (response.ok) {
        print('✅ CORS Test PASSED: Successfully fetched image from Firebase Storage');
        print('   URL: $imageUrl');
        print('   Status: ${response.status}');
        return true;
      } else {
        print('❌ CORS Test FAILED: HTTP Error ${response.status}');
        print('   URL: $imageUrl');
        return false;
      }
    } catch (e) {
      print('❌ CORS Test FAILED: Exception occurred');
      print('   URL: $imageUrl');
      print('   Error: $e');
      
      // Check if it's a CORS-specific error
      if (e.toString().contains('CORS') || 
          e.toString().contains('Cross-Origin') ||
          e.toString().contains('blocked')) {
        print('   This appears to be a CORS-related error.');
        print('   Make sure CORS is configured for your Firebase Storage bucket.');
      }
      
      return false;
    }
  }

  /// Test CORS with a preflight request
  static Future<bool> testCorsPreflightRequest(String bucketUrl) async {
    if (!kIsWeb) return true;

    try {
      // Send an OPTIONS request to test preflight
      final response = await html.window.fetch(
        bucketUrl,
        {
          'method': 'OPTIONS',
          'mode': 'cors',
          'headers': {
            'Access-Control-Request-Method': 'GET',
            'Access-Control-Request-Headers': 'Content-Type',
          },
        },
      );

      if (response.ok) {
        print('✅ CORS Preflight PASSED');
        return true;
      } else {
        print('❌ CORS Preflight FAILED: ${response.status}');
        return false;
      }
    } catch (e) {
      print('❌ CORS Preflight FAILED: $e');
      return false;
    }
  }

  /// Get current origin for debugging
  static String getCurrentOrigin() {
    if (!kIsWeb) return 'Not Web Platform';
    return html.window.location.origin;
  }

  /// Print CORS debugging information
  static void printCorsDebugInfo() {
    if (!kIsWeb) {
      print('🔍 Platform: Not Web (CORS not applicable)');
      return;
    }

    print('🔍 CORS Debug Information:');
    print('   Current Origin: ${getCurrentOrigin()}');
    print('   User Agent: ${html.window.navigator.userAgent}');
    print('   Protocol: ${html.window.location.protocol}');
    print('   Host: ${html.window.location.host}');
    print('   Port: ${html.window.location.port}');
  }

  /// Test if an image URL is accessible
  static Future<bool> testImageAccess(String imageUrl) async {
    if (!kIsWeb) return true;

    try {
      // Create an image element to test loading
      final img = html.ImageElement();
      
      // Set up a completer to handle the async image load
      bool loadSuccess = false;
      bool loadComplete = false;

      img.onLoad.listen((_) {
        loadSuccess = true;
        loadComplete = true;
        print('✅ Image Load Test PASSED: Image loaded successfully');
      });

      img.onError.listen((_) {
        loadSuccess = false;
        loadComplete = true;
        print('❌ Image Load Test FAILED: Image failed to load');
        print('   This could be due to CORS restrictions or invalid URL');
      });

      // Set the source to trigger loading
      img.src = imageUrl;

      // Wait for load to complete (with timeout)
      int attempts = 0;
      while (!loadComplete && attempts < 50) { // 5 second timeout
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!loadComplete) {
        print('❌ Image Load Test TIMEOUT: Image took too long to load');
        return false;
      }

      return loadSuccess;
    } catch (e) {
      print('❌ Image Load Test ERROR: $e');
      return false;
    }
  }

  /// Comprehensive CORS test
  static Future<Map<String, dynamic>> runComprehensiveCorsTest(String? testImageUrl) async {
    print('🧪 Running Comprehensive CORS Test...');
    printCorsDebugInfo();

    final results = <String, dynamic>{
      'platform': kIsWeb ? 'web' : 'native',
      'origin': getCurrentOrigin(),
      'corsRequired': kIsWeb,
    };

    if (!kIsWeb) {
      results['status'] = 'skipped';
      results['message'] = 'CORS testing skipped on non-web platform';
      return results;
    }

    if (testImageUrl == null || testImageUrl.isEmpty) {
      results['status'] = 'error';
      results['message'] = 'No test image URL provided';
      return results;
    }

    // Test 1: Direct image access
    print('\n📸 Testing image access...');
    final imageTest = await testImageAccess(testImageUrl);
    results['imageAccessTest'] = imageTest;

    // Test 2: Fetch API test
    print('\n🌐 Testing fetch API access...');
    final fetchTest = await testFirebaseStorageCors(testImageUrl);
    results['fetchTest'] = fetchTest;

    // Determine overall status
    if (imageTest && fetchTest) {
      results['status'] = 'success';
      results['message'] = 'All CORS tests passed';
      print('\n✅ CORS Configuration appears to be working correctly!');
    } else {
      results['status'] = 'failed';
      results['message'] = 'One or more CORS tests failed';
      print('\n❌ CORS Configuration issues detected');
      print('\n🔧 Troubleshooting steps:');
      print('   1. Apply CORS configuration: gsutil cors set cors.json gs://your-bucket');
      print('   2. Verify your current origin (${getCurrentOrigin()}) is in cors.json');
      print('   3. Clear browser cache and try again');
      print('   4. Check Firebase Storage security rules');
    }

    return results;
  }
}