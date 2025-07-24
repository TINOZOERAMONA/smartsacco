// ignore_for_file: library_private_types_in_public_api, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching role
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String userEmail;

  const EmailVerificationScreen({super.key, required this.userEmail});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool isLoading = false;
  Timer? timer;
  int resendCooldown = 0;
  Timer? cooldownTimer;

  @override
  void initState() {
    super.initState();

    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();
      startVerificationCheck();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> sendVerificationEmail() async {
    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        startResendCooldown();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification email sent to ${widget.userEmail}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void startVerificationCheck() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await checkEmailVerified();
    });
  }

  void startResendCooldown() {
    resendCooldown = 60;
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          resendCooldown--;
        });
      }

      if (resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> checkEmailVerified() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        setState(() => isEmailVerified = true);
        timer?.cancel();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(seconds: 2));

          // Fetch user role from Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          final role = userDoc.data()?['role'] ?? 'member';

          // Navigate based on role with logging
          if (mounted) {
            print('Email verified successfully. User role: $role');
            if (role == 'admin') {
              print('Navigating to admin dashboard');
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            } else if (role == 'member') {
              print('Navigating to member dashboard');
              Navigator.pushReplacementNamed(context, '/member-dashboard');
            } else {
              print('Unknown role, navigating to home');
              Navigator.pushReplacementNamed(context, '/home'); // fallback
            }
          }
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 100),
              SizedBox(height: 20),
              Text(
                'Email Verified!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              Text('Redirecting based on your role...'),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Color(0xFF007C91),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 100,
              color: Color(0xFF007C91),
            ),
            const SizedBox(height: 30),
            const Text(
              'Check Your Email',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'We\'ve sent a verification email to:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              widget.userEmail,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Click the link in the email to verify your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isLoading || resendCooldown > 0)
                    ? null
                    : sendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        resendCooldown > 0
                            ? 'Resend in ${resendCooldown}s'
                            : 'Resend Email',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Back to Login',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Checking verification status...',
                      style: TextStyle(color: Color(0xFF007C91), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
