import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/korean_auth_service.dart';
import 'services/device_info_service.dart'; // Add device info service
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/after_login_splash.dart';
import 'screens/intro_community_splash.dart'; // Import the new splash screen
// Removed unused imports for community screens

// for test 
import 'screens/community/community_mvp/community_main.dart'; 


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
  
  // Collect comprehensive device information on startup
  final deviceInfoService = DeviceInfoService();
  await deviceInfoService.collectAllDeviceInfo(null);
  
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
        '/': (context) =>  SplashScreen(), //CommunityMainScreen(),
        '/login': (context) => const LoginScreen(),
        '/after-login-splash': (context) => const AfterLoginSplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/intro-community-splash': (context) => const IntroCommunitySplash(),
        '/community': (context) => const CommunityScreen(),
      },
    );
  }
}

