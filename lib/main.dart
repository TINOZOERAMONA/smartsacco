import 'package:flutter/material.dart';
import 'package:smartsacco/pages/admin/dashboard_page.dart';
import 'package:smartsacco/pages/admin/member_page.dart';
import 'package:smartsacco/pages/admin/membersDetails.dart';
import 'package:smartsacco/pages/blinddashboard.dart';
import 'package:smartsacco/pages/forgotpassword.dart';
import 'package:smartsacco/pages/home_page.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/member_dashboard.dart';
import 'package:smartsacco/pages/register.dart';
import 'package:smartsacco/pages/splash_page.dart';
import 'package:smartsacco/pages/emailverification_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smartsacco/pages/voicewelcome.dart';
import 'package:smartsacco/pages/voiceregister.dart';
import 'package:smartsacco/pages/voicelogin.dart';
import 'package:smartsacco/utils/logger.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    setupLogging();

    await Firebase.initializeApp(
      options: kIsWeb
          ? DefaultFirebaseOptions.web
          : DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const SaccoDashboardApp());
  } catch (e, stack) {
    print("🔥 Error during app startup: $e");
    print("📌 Stack trace: $stack");
  }
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
    debugPrint("SplashPage loaded ✅");
  }

  void _initializeDeepLinks() {
    _appLinks = AppLinks();

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

      if (uri.path.contains('reset') || uri.queryParameters.containsKey('oobCode')) {
        final resetCode = uri.queryParameters['oobCode'];
        final mode = uri.queryParameters['mode'];

        if (mode == 'resetPassword' && resetCode != null) {
          navigatorKey.currentState?.pushNamed(
            '/custom-password-reset',
            arguments: {'resetCode': resetCode},
          );
        } else if (mode == 'verifyEmail') {
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
        '/voiceWelcome': (context) => const VoiceWelcomeScreen(),
        '/voiceRegister': (context) => const VoiceRegisterPage(),
        '/voiceLogin': (context) => const VoiceLoginPage(),
        '/member-dashboard': (context) => const MemberDashboard(),
        '/admin-dashboard': (context) => const AdminMainPage(),
        '/members': (context) => const MembersPage(),
        //'/member_details': (context) => const MemberDetailsPage(),
        '/blindmember': (context) => const VoiceMemberDashboard(),

      },
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
            return MaterialPageRoute(builder: (context) => ForgotPasswordPage());

          case '/member_details':
            final userId = args?['userId'] as String?;
            if (userId != null) {
              return MaterialPageRoute(
                builder: (context) => MemberLoanDetailsPage(userId: userId),
              );
            }
            return _errorRoute("Missing userId for member details");

          default:
            return _errorRoute("Route not found: ${settings.name}");
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }


  Route _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}

// Optional helper class for testing deep links
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

  static void testPasswordReset(BuildContext context, String testCode) {
    Navigator.pushNamed(
      context,
      '/custom-password-reset',
      arguments: {'resetCode': testCode},
    );
  }
}