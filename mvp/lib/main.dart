import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/community/category_selection_screen.dart';
import 'screens/community/profile_information_screen.dart';
import 'screens/community/phone_verification_screen.dart';
import 'screens/community/policy_agreement_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/community': (context) => const CommunityScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final authService = AuthService();
  bool _hasCheckedRedirect = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check for redirect result on web
      await authService.checkRedirectResult();
    } catch (e) {
      print('Redirect result check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _hasCheckedRedirect = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we haven't checked redirect results yet, show a loading state (not splash)
    if (!_hasCheckedRedirect) {
      return Container(
        color: const Color(0xFF1E1E2E),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
          ),
        ),
      );
    }
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show splash screen only on initial load
        if (snapshot.connectionState == ConnectionState.waiting && _showSplash) {
          // After splash screen completes, don't show it again
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _showSplash = false;
              });
            }
          });
          return const SplashScreen();
        }
        
        // If user is logged in, go to home
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        // If no user, show login screen
        return const LoginScreen();
      },
    );
  }
}

