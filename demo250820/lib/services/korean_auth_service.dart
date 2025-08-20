// Conditional imports for platform-specific implementations
export 'korean_auth_service_stub.dart'
    if (dart.library.html) 'korean_auth_service_web.dart'
    if (dart.library.io) 'korean_auth_service_mobile.dart';