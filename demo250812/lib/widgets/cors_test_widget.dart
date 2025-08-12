import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/cors_test.dart';

class CorsTestWidget extends StatefulWidget {
  const CorsTestWidget({super.key});

  @override
  State<CorsTestWidget> createState() => _CorsTestWidgetState();
}

class _CorsTestWidgetState extends State<CorsTestWidget> {
  String _testResults = '';
  bool _isLoading = false;
  final TextEditingController _urlController = TextEditingController();

  // Example Firebase Storage URL - replace with an actual URL from your bucket
  final String _defaultTestUrl = 'https://firebasestorage.googleapis.com/v0/b/yeskitest2.firebasestorage.app/o/test-image.jpg?alt=media';

  @override
  void initState() {
    super.initState();
    _urlController.text = _defaultTestUrl;
    if (kIsWeb) {
      _runInitialTest();
    }
  }

  Future<void> _runInitialTest() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running initial CORS test...\n';
    });

    CorsTest.printCorsDebugInfo();
    
    setState(() {
      _testResults += '\n🔍 Current Origin: ${CorsTest.getCurrentOrigin()}\n';
      _testResults += 'Expected in CORS config: http://localhost:50000\n\n';
    });

    if (_urlController.text.isNotEmpty) {
      final results = await CorsTest.runComprehensiveCorsTest(_urlController.text);
      setState(() {
        _testResults += '\n📊 Test Results:\n';
        _testResults += 'Platform: ${results['platform']}\n';
        _testResults += 'Origin: ${results['origin']}\n';
        _testResults += 'Status: ${results['status']}\n';
        _testResults += 'Message: ${results['message']}\n';
        
        if (results.containsKey('imageAccessTest')) {
          _testResults += 'Image Access: ${results['imageAccessTest'] ? "✅ PASS" : "❌ FAIL"}\n';
        }
        if (results.containsKey('fetchTest')) {
          _testResults += 'Fetch API: ${results['fetchTest'] ? "✅ PASS" : "❌ FAIL"}\n';
        }
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testCustomUrl() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _testResults = 'Please enter a test URL\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResults = 'Testing custom URL...\n${_urlController.text}\n\n';
    });

    final results = await CorsTest.runComprehensiveCorsTest(_urlController.text);
    
    setState(() {
      _testResults += '\n📊 Custom URL Test Results:\n';
      _testResults += 'Status: ${results['status']}\n';
      _testResults += 'Message: ${results['message']}\n';
      
      if (results.containsKey('imageAccessTest')) {
        _testResults += 'Image Access: ${results['imageAccessTest'] ? "✅ PASS" : "❌ FAIL"}\n';
      }
      if (results.containsKey('fetchTest')) {
        _testResults += 'Fetch API: ${results['fetchTest'] ? "✅ PASS" : "❌ FAIL"}\n';
      }
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(height: 8),
              Text('CORS testing is only available on web platform'),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Storage CORS Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // URL Input
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Test Image URL',
                hintText: 'Enter Firebase Storage image URL to test',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Test Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runInitialTest,
                  child: const Text('Test CORS Setup'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testCustomUrl,
                  child: const Text('Test Custom URL'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Loading Indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Results
            if (_testResults.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Test Results:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _testResults,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            
            // Instructions
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Setup Instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Make sure you have gcloud CLI installed\n'
              '2. Run: gcloud config set project yeskitest2\n'
              '3. Run: gsutil cors set cors.json gs://yeskitest2.firebasestorage.app\n'
              '4. Upload a test image to Firebase Storage\n'
              '5. Use the image URL in the test above',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}