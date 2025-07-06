import 'package:flutter/material.dart';
import 'package:smartsacco/pages/dashboard_page.dart';
import 'package:smartsacco/pages/forgotpassword.dart';
import 'package:smartsacco/pages/home_page.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/member_dashboard.dart';
import 'package:smartsacco/pages/register.dart';
import 'package:smartsacco/pages/splash_page.dart';
// ignore: unused_import
import 'package:smartsacco/pages/emailverification_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smartsacco/pages/voicewelcome.dart';
import 'package:smartsacco/pages/voiceregister.dart';
import 'package:smartsacco/pages/voicelogin.dart';

import 'package:smartsacco/utils/logger.dart';


import 'package:app_links/app_links.dart';
import 'dart:async';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging(); // Initialize logging
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SaccoDashboardApp());
}

class SaccoDashboardApp extends StatefulWidget {
  const SaccoDashboardApp({super.key});

  @override
  State<SaccoDashboardApp> createState() => _SaccoDashboardAppState();
}

class _SaccoDashboardAppState extends State<SaccoDashboardApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  void _initializeDeepLinks() {
    _appLinks = AppLinks();

    // Handle incoming links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (Uri uri) {
        _handleIncomingLink(uri.toString());
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _handleIncomingLink(String link) {
    try {
      final uri = Uri.parse(link);

      // Check if it's a password reset link
      if (uri.path.contains('reset') || uri.queryParameters.containsKey('oobCode')) {
        final resetCode = uri.queryParameters['oobCode'];
        final mode = uri.queryParameters['mode'];

        if (mode == 'resetPassword' && resetCode != null) {
          // Navigate to custom password reset page
          navigatorKey.currentState?.pushNamed(
            '/custom-password-reset',
            arguments: {'resetCode': resetCode},
          );
        } else if (mode == 'verifyEmail') {
          // Handle email verification if needed
          final actionCode = uri.queryParameters['oobCode'];
          if (actionCode != null) {
            navigatorKey.currentState?.pushNamed(
              '/verify-email',
              arguments: {'actionCode': actionCode},
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'SACCO SHIELD',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/forgotpassword': (context) => ForgotPasswordPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/voiceWelcome': (context) => const VoiceWelcomeScreen(),
        '/voiceRegister': (context) => const VoiceRegisterPage(),
        '/voiceLogin': (context) => const VoiceLoginPage(),
        '/member-dashboard': (context) => const MemberDashboard(),

      },
      // Handle routes that need parameters
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/verification':
          case '/verify-email':
            return MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                userEmail: args?['userEmail'] ?? '',
              ),
            );

          case '/custom-password-reset':
            final resetCode = args?['resetCode'] as String?;
            if (resetCode != null) {
              return MaterialPageRoute(
                builder: (context) => CustomPasswordResetPage(resetCode: resetCode),
              );
            }
            // If no reset code, redirect to forgot password page
            return MaterialPageRoute(
              builder: (context) => ForgotPasswordPage(),
            );

          default:
            return null;
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Add this class to handle deep links manually (for testing)
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  static void handleResetLink(BuildContext context, String resetCode) {
    Navigator.pushNamed(
      context,
      '/custom-password-reset',
      arguments: {'resetCode': resetCode},
    );
  }

  // Method to manually test password reset (for development)
  static void testPasswordReset(BuildContext context, String testCode) {
    Navigator.pushNamed(
      context,
      '/custom-password-reset',
      arguments: {'resetCode': testCode},
    );
  }
}