import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/korean_auth_service.dart';
import 'screens/splash_screen.dart';
// Korean UI imports
import 'screens/korean_ui/login_screen.dart';
import 'screens/korean_ui/intro_after_login_splash2.dart';  // Korean UI community flow 
import 'screens/korean_ui/community/community_main.dart'; 
import 'screens/korean_ui/community/community_explore_page.dart'; 
import 'screens/korean_ui/community/community_search_page.dart';

// Legacy UI imports
import 'screens/legacy_ui/home_screen.dart';
import 'screens/legacy_ui/community_screen.dart';
import 'screens/legacy_ui/intro_community_splash.dart'; // Import the legacy splash screen 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Kakao SDK with correct keys for each platform
  await KoreanAuthService.initialize(
    kakaoAppKey: '3d1ed1dc6cd2c4797f2dfd65ee48c8e8', // JavaScript key for web
    nativeAppKey: '3c7a8b482a7de8109be0c367da2eb33a', // Native app key for mobile
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silso',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => const LoginScreen(), // Korean UI
        '/after-login-splash': (context) => const AfterLoginSplashScreen(), // Korean UI
        '/home': (context) => const HomeScreen(), // Legacy UI
        '/intro-community-splash': (context) => const IntroCommunitySplash(), // Legacy UI
        '/community': (context) => const CommunityScreen(), // Legacy UI
        '/mvp_community' : (context) => const CommunityMainTabScreenMycom(), // Korean UI
      },
    );
  }
}

