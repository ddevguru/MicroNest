import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/video_page.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_dashboard.dart';

void main() {
  runApp(const MicroNestApp());
}

class MicroNestApp extends StatelessWidget {
  const MicroNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MicroNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF66BB6A),
          surface: Color(0xFF1A1A1A),
          background: Color(0xFF0A0A0A),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFB0B0B0),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/video': (context) => const VideoPage(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeDashboard(),
        // Add more routes as you create other screens
        // '/registration': (context) => const RegistrationScreen(),
      },
    );
  }
}
