// Stub implementation for dart:js when not available on mobile platforms
// This file provides mock implementations for dart:js functionality
// to prevent compilation errors on mobile platforms

// Mock context object for mobile platforms
final MockJsContext context = MockJsContext();

// Mock function for allowInterop
T allowInterop<T extends Function>(T f) => f;

class MockJsContext {
  // Mock implementation for js.context['property'] access
  dynamic operator [](String key) {
    switch (key) {
      case 'location':
        return MockLocation();
      case 'Kakao':
        return null; // Kakao SDK not available on mobile
      default:
        return null;
    }
  }

  // Mock implementation for js.context['property'] = value
  void operator []=(String key, dynamic value) {
    // Do nothing on mobile - web-specific functionality
  }

  // Mock implementation for js.context.callMethod
  dynamic callMethod(String method, [List<dynamic>? args]) {
    // Do nothing on mobile - web-specific functionality
    return null;
  }
}

class MockLocation {
  // Mock location object for mobile
  dynamic operator [](String key) {
    switch (key) {
      case 'href':
        return 'http://localhost/'; // Mock URL for mobile
      case 'origin':
        return 'http://localhost'; // Mock origin for mobile
      default:
        return '';
    }
  }

  @override
  String toString() => 'http://localhost/';
}