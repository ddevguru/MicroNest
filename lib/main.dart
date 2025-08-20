import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/onboarding_second_screen.dart';
import 'screens/video_page.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/profile_screen.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/create_group_screen.dart';
import 'screens/join_group_screen.dart';
import 'screens/group_details_screen.dart';
import 'screens/request_loan_screen.dart';
import 'screens/withdraw_funds_screen.dart';
import 'screens/transactions_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MicroNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/video': (context) => const VideoPage(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/onboarding_second': (context) => const OnboardingSecondScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeDashboard(),
        '/profile': (context) => const ProfileScreen(),
        '/biometric_lock': (context) => BiometricLockScreen(
          onSuccess: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        '/pin_lock': (context) => PinLockScreen(
          onSuccess: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        '/groups': (context) => const GroupsScreen(),
        '/create-group': (context) => const CreateGroupScreen(),
        '/request-loan': (context) => const RequestLoanScreen(),
        '/withdraw-funds': (context) => const WithdrawFundsScreen(),
        '/transactions': (context) => const TransactionsScreen(),
      },
    );
  }
}
