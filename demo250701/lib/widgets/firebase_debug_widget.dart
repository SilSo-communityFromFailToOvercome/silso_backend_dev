import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/image_service.dart';

class FirebaseDebugWidget extends StatefulWidget {
  const FirebaseDebugWidget({super.key});

  @override
  State<FirebaseDebugWidget> createState() => _FirebaseDebugWidgetState();
}

class _FirebaseDebugWidgetState extends State<FirebaseDebugWidget> {
  final ImageService _imageService = ImageService();
  Map<String, dynamic>? _debugInfo;
  bool _isLoading = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _runDebugTests();
  }

  Future<void> _runDebugTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running Firebase debug tests...\n\n';
    });

    try {
      // Get debug info
      final debugInfo = await _imageService.debugFirebaseConfig();
      setState(() {
        _debugInfo = debugInfo;
        _testResults += '📊 Firebase Configuration:\n';
        debugInfo.forEach((key, value) {
          _testResults += '   $key: $value\n';
        });
        _testResults += '\n';
      });

      // Test authentication
      _testResults += '🔐 Authentication Test:\n';
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user != null) {
        _testResults += '   ✅ User authenticated\n';
        _testResults += '   UID: ${user.uid}\n';
        _testResults += '   Email: ${user.email ?? "No email"}\n';
        _testResults += '   Provider: ${user.providerData.map((p) => p.providerId).join(", ")}\n';
        
        // Test getting ID token
        try {
          final token = await user.getIdToken();
          _testResults += '   ✅ Auth token obtained (length: ${token?.length ?? 0})\n';
        } catch (e) {
          _testResults += '   ❌ Failed to get auth token: $e\n';
        }
      } else {
        _testResults += '   ❌ No user authenticated\n';
      }
      _testResults += '\n';

      // Test Firebase Storage access
      _testResults += '🗄️ Firebase Storage Test:\n';
      final storage = FirebaseStorage.instance;
      _testResults += '   App: ${storage.app.name}\n';
      _testResults += '   Bucket: ${storage.bucket}\n';
      
      // Test creating a reference
      try {
        final testRef = storage.ref().child('debug/test.txt');
        _testResults += '   ✅ Reference created: ${testRef.fullPath}\n';
        
        // Test writing a small file (if authenticated)
        if (user != null) {
          try {
            final testData = 'Debug test ${DateTime.now().millisecondsSinceEpoch}';
            final uploadTask = testRef.putString(testData);
            await uploadTask;
            _testResults += '   ✅ Test upload successful (string data)\n';
            
            // Test getting download URL
            try {
              final downloadUrl = await testRef.getDownloadURL();
              _testResults += '   ✅ Download URL obtained\n';
              _testResults += '   URL: ${downloadUrl.substring(0, 50)}...\n';
            } catch (e) {
              _testResults += '   ❌ Failed to get download URL: $e\n';
            }
            
            // Clean up test file
            try {
              await testRef.delete();
              _testResults += '   ✅ Test file cleaned up\n';
            } catch (e) {
              _testResults += '   ⚠️ Failed to clean up test file: $e\n';
            }
            
          } catch (e) {
            _testResults += '   ❌ Test upload failed: $e\n';
            
            // Check for specific error types
            if (e is FirebaseException) {
              _testResults += '   Firebase Error Code: ${e.code}\n';
              _testResults += '   Firebase Error Message: ${e.message}\n';
              
              switch (e.code) {
                case 'storage/unauthorized':
                  _testResults += '   💡 Solution: Check Firebase Storage security rules\n';
                  break;
                case 'storage/unauthenticated':
                  _testResults += '   💡 Solution: User needs to be authenticated\n';
                  break;
                case 'storage/unknown':
                  _testResults += '   💡 Solution: Check CORS configuration for web\n';
                  break;
              }
            }
          }
        } else {
          _testResults += '   ⚠️ Skipping upload test (not authenticated)\n';
        }
      } catch (e) {
        _testResults += '   ❌ Failed to create storage reference: $e\n';
      }
      _testResults += '\n';

      // Web-specific tests
      if (kIsWeb) {
        _testResults += '🌐 Web-Specific Tests:\n';
        _testResults += '   Platform: Web\n';
        _testResults += '   Current origin: ${Uri.base.origin}\n';
        _testResults += '   Expected in CORS: http://localhost:50000\n';
        _testResults += '   Origins match: ${Uri.base.origin == "http://localhost:50000"}\n';
        
        // Test CORS by trying to fetch a Firebase Storage URL
        try {
          _testResults += '   Testing CORS with fetch...\n';
          // This is a placeholder - actual CORS test would need dart:html
          _testResults += '   ⚠️ Full CORS test requires dart:html (see cors_test.dart)\n';
        } catch (e) {
          _testResults += '   ❌ CORS test error: $e\n';
        }
      } else {
        _testResults += '📱 Platform: Native (CORS not applicable)\n';
      }
      _testResults += '\n';

      // Security Rules Check
      _testResults += '🛡️ Security Rules Recommendations:\n';
      _testResults += '   For testing, use these rules in Firebase Console:\n';
      _testResults += '   \n';
      _testResults += '   rules_version = "2";\n';
      _testResults += '   service firebase.storage {\n';
      _testResults += '     match /b/{bucket}/o {\n';
      _testResults += '       match /{allPaths=**} {\n';
      _testResults += '         allow read: if true;\n';
      _testResults += '         allow write: if request.auth != null;\n';
      _testResults += '       }\n';
      _testResults += '     }\n';
      _testResults += '   }\n';

    } catch (e) {
      _testResults += '❌ Debug test failed: $e\n';
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Debug Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _runDebugTests,
              child: const Text('Run Debug Tests'),
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            
            if (_testResults.isNotEmpty) ...[
              const Text(
                'Debug Results:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}