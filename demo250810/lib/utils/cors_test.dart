import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// CORS testing utility - cross-platform compatible
class CorsTest {
  /// Test network connectivity by attempting to fetch an image from Firebase Storage
  static Future<bool> testFirebaseStorageCors(String imageUrl) async {
    try {
      // Use HTTP package for all platforms
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        print('✅ Network Test PASSED: Successfully fetched image from Firebase Storage');
        print('   URL: $imageUrl');
        print('   Status: ${response.statusCode}');
        return true;
      } else {
        print('❌ Network Test FAILED: HTTP Error ${response.statusCode}');
        print('   URL: $imageUrl');
        return false;
      }
    } catch (e) {
      print('❌ Network Test FAILED: Exception occurred');
      print('   URL: $imageUrl');
      print('   Error: $e');
      
      if (kIsWeb) {
        // Check if it's a CORS-specific error on web
        if (e.toString().contains('CORS') || 
            e.toString().contains('Cross-Origin') ||
            e.toString().contains('blocked')) {
          print('   This appears to be a CORS-related error.');
          print('   Make sure CORS is configured for your Firebase Storage bucket.');
        }
      }
      
      return false;
    }
  }

  /// Test network connectivity with HEAD request (lighter than GET)
  static Future<bool> testCorsPreflightRequest(String bucketUrl) async {
    try {
      // Use HEAD request to test accessibility
      final response = await http.head(Uri.parse(bucketUrl));
      
      if (response.statusCode == 200) {
        print('✅ HEAD Request Test PASSED');
        return true;
      } else {
        print('❌ HEAD Request Test FAILED: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ HEAD Request Test FAILED: $e');
      return false;
    }
  }

  /// Get current platform for debugging
  static String getCurrentOrigin() {
    if (kIsWeb) {
      return 'Web Platform';
    }
    return 'Mobile Platform';
  }

  /// Print platform debugging information
  static void printCorsDebugInfo() {
    print('🔍 Platform Debug Information:');
    print('   Platform: ${getCurrentOrigin()}');
    print('   Is Web: $kIsWeb');
    if (kIsWeb) {
      print('   Note: CORS applies to web platform only');
    } else {
      print('   Note: CORS does not apply to mobile platforms');
    }
  }

  /// Test if an image URL is accessible
  static Future<bool> testImageAccess(String imageUrl) async {
    try {
      // Use HEAD request to test accessibility without downloading content
      final response = await http.head(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        print('✅ Image Access Test PASSED: Image URL is accessible');
        return true;
      } else {
        print('❌ Image Access Test FAILED: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Image Access Test ERROR: $e');
      return false;
    }
  }

  /// Comprehensive network connectivity test
  static Future<Map<String, dynamic>> runComprehensiveCorsTest(String? testImageUrl) async {
    print('🧪 Running Comprehensive Network Test...');
    printCorsDebugInfo();

    final results = <String, dynamic>{
      'platform': kIsWeb ? 'web' : 'native',
      'origin': getCurrentOrigin(),
      'corsRequired': kIsWeb,
    };

    if (testImageUrl == null || testImageUrl.isEmpty) {
      results['status'] = 'error';
      results['message'] = 'No test image URL provided';
      return results;
    }

    // Test 1: Direct image access
    print('\n📸 Testing image access...');
    final imageTest = await testImageAccess(testImageUrl);
    results['imageAccessTest'] = imageTest;

    // Test 2: Network connectivity test
    print('\n🌐 Testing network connectivity...');
    final fetchTest = await testFirebaseStorageCors(testImageUrl);
    results['fetchTest'] = fetchTest;

    // Determine overall status
    if (imageTest && fetchTest) {
      results['status'] = 'success';
      results['message'] = 'All network tests passed';
      print('\n✅ Network connectivity is working correctly!');
    } else {
      results['status'] = 'failed';
      results['message'] = 'One or more network tests failed';
      print('\n❌ Network connectivity issues detected');
      print('\n🔧 Troubleshooting steps:');
      if (kIsWeb) {
        print('   1. Apply CORS configuration: gsutil cors set cors.json gs://your-bucket');
        print('   2. Verify your current origin is in cors.json');
        print('   3. Clear browser cache and try again');
      }
      print('   4. Check Firebase Storage security rules');
      print('   5. Verify internet connectivity');
      print('   6. Check if the URL is valid and accessible');
    }

    return results;
  }
}