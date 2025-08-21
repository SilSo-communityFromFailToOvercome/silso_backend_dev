class KakaoConfig {
  // Kakao Application Keys
  static const String restApiKey = '9b1309a06067eedd2ebc6f3ddc3a65d0';
  static const String javascriptKey = '3d1ed1dc6cd2c4797f2dfd65ee48c8e8';
  static const String nativeAppKey = '3c7a8b482a7de8109be0c367da2eb33a';
  
  // Note: Client secret should never be exposed in client-side code
  // It's properly stored in the backend server's .env file
  
  // OAuth Scopes
  static const List<String> defaultScopes = [
    'profile_nickname',
    'profile_image', 
    'account_email'
  ];
  
  // OAuth URLs
  static const String authorizeUrl = 'https://kauth.kakao.com/oauth/authorize';
  static const String tokenUrl = 'https://kauth.kakao.com/oauth/token';
  static const String userInfoUrl = 'https://kapi.kakao.com/v2/user/me';
  
  // Helper method to get scope string
  static String getScopeString() {
    return defaultScopes.join(',');
  }
  
  // Helper method to build OAuth URL
  static String buildOAuthUrl(String redirectUri) {
    final params = {
      'client_id': restApiKey,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': getScopeString(),
    };
    
    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$authorizeUrl?$queryString';
  }
}