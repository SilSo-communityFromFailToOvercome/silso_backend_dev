import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/korean_auth_service.dart';
import 'screens/splash_screen.dart';
// Community UI imports
import 'screens/login/login_screen.dart';
import 'screens/login/intro_after_login_splash2.dart';  // After login flow 
import 'screens/community/community_main.dart';
import 'screens/temporary_home.dart'; // Temporary home page
// Initial profile setup screens
import 'screens/community/initial_profile/intro_community_splash2.dart';
import 'screens/community/initial_profile/category_selection_screen.dart';
import 'screens/community/initial_profile/profile_information_screen.dart';
import 'screens/community/initial_profile/policy_agreement_screen.dart';

 

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
        '/temporary-home': (context) => const TemporaryHomePage(), // Temporary home
        '/mvp_community' : (context) => const CommunityMainTabScreenMycom(), // Korean UI
        // Initial profile setup flow
        '/intro-community-splash': (context) => const IntroCommunitySplash(),
        '/category-selection': (context) => const CategorySelectionScreen(),
        '/profile-information': (context) => const ProfileInformationScreen(),
        '/policy-agreement': (context) => const PolicyAgreementScreen(),
      },
    );
  }
}

