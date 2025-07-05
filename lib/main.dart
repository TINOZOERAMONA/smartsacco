import 'package:flutter/material.dart';
import 'package:smartsacco/pages/dashboard_page.dart';
import 'package:smartsacco/pages/forgot_password.dart';
import 'package:smartsacco/pages/home_page.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/member_dashboard.dart';
import 'package:smartsacco/pages/register.dart';
import 'package:smartsacco/pages/splash_page.dart';
import 'package:smartsacco/pages/verification_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:smartsacco/pages/voicewelcome.dart';
import 'package:smartsacco/pages/voiceregister.dart';
import 'package:smartsacco/pages/voicelogin.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(SaccoDashboardApp());
}

class SaccoDashboardApp extends StatelessWidget {
  const SaccoDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SACCO SHIELD',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/forgotpassword': (context) => ResetPin(),
        '/register': (context) => const RegisterPage(),
        '/verification': (context) => const VerificationPage(),
        '/dashboard': (context) => const AdminMainPage(),
        '/voiceWelcome': (context) => const VoiceWelcomeScreen(),
        '/voiceRegister': (context) => const VoiceRegisterPage(),
        '/voiceLogin': (context) => const VoiceLoginPage(),
        '/member-dashboard': (context) => const MemberDashboard(
          userName: 'Member',
          email: 'default@member.com',
          currentSavings: 500000,
          outstandingLoan: 120000,
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}