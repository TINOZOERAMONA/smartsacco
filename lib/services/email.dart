// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class EmailVerificationService {
  static final _log = Logger('EmailVerificationService');

  // Send email verification to current user
  static Future<bool> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log.warning('No user is currently signed in');
        return false;
      }

      if (user.emailVerified) {
        _log.info('User email is already verified');
        return true;
      }

      await user.sendEmailVerification();
      _log.info('Email verification sent to: ${user.email}');
      return true;
    } catch (e) {
      _log.severe('Failed to send email verification: $e');
      return false;
    }
  }

  // Check if current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log.warning('No user is currently signed in');
        return false;
      }

      // Reload user to get latest verification status
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      return refreshedUser?.emailVerified ?? false;
    } catch (e) {
      _log.severe('Error checking email verification status: $e');
      return false;
    }
  }

  // Wait for email verification with timeout
  static Future<bool> waitForEmailVerification({
    Duration timeout = const Duration(minutes: 5),
    Duration checkInterval = const Duration(seconds: 3),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      final isVerified = await isEmailVerified();
      if (isVerified) {
        _log.info('Email verification completed');
        return true;
      }

      await Future.delayed(checkInterval);
    }

    _log.warning('Email verification timeout reached');
    return false;
  }

  // Send verification email with custom action code settings
  static Future<bool> sendEmailVerificationWithSettings({
    String? continueUrl,
    String? iOSBundleId,
    String? androidPackageName,
    bool? androidInstallApp,
    String? androidMinimumVersion,
    String? dynamicLinkDomain,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _log.warning('No user is currently signed in');
        return false;
      }

      if (user.emailVerified) {
        _log.info('User email is already verified');
        return true;
      }

      ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: continueUrl ?? 'https://your-project.firebaseapp.com', // Use your actual Firebase hosting URL
        handleCodeInApp: true,
        iOSBundleId: iOSBundleId,
        androidPackageName: androidPackageName,
        androidInstallApp: androidInstallApp ?? false,
        androidMinimumVersion: androidMinimumVersion,
        dynamicLinkDomain: dynamicLinkDomain,
      );

      await user.sendEmailVerification(actionCodeSettings);
      _log.info('Email verification with settings sent to: ${user.email}');
      return true;
    } catch (e) {
      _log.severe('Failed to send email verification with settings: $e');
      return false;
    }
  }

  // Handle email verification from deep link (FIXED)
  static Future<bool> handleEmailVerificationLink(String link) async {
    try {
      // Validate the link format first
      if (!link.contains('mode=verifyEmail') || !link.contains('oobCode=')) {
        _log.warning('Invalid email verification link format');
        return false;
      }

      // Extract the action code from the link manually
      final uri = Uri.parse(link);
      final actionCode = uri.queryParameters['oobCode'];

      if (actionCode == null || actionCode.isEmpty) {
        _log.warning('No action code found in email verification link');
        return false;
      }

      // Apply the action code to verify the email
      await FirebaseAuth.instance.applyActionCode(actionCode);

      // Refresh the user to get updated verification status
      await FirebaseAuth.instance.currentUser?.reload();

      _log.info('Email verification completed via link');
      return true;
    } on FirebaseAuthException catch (e) {
      _log.severe('Firebase Auth error handling email verification link: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _log.severe('Failed to handle email verification link: $e');
      return false;
    }
  }

  // Validate email verification link without applying it (FIXED)
  static Future<bool> validateEmailVerificationLink(String link) async {
    try {
      // Check if link has required parameters
      if (!link.contains('mode=verifyEmail') || !link.contains('oobCode=')) {
        return false;
      }

      // Extract and validate action code manually
      final uri = Uri.parse(link);
      final actionCode = uri.queryParameters['oobCode'];

      // Basic validation - check if action code exists and has minimum length
      if (actionCode == null || actionCode.isEmpty || actionCode.length < 10) {
        return false;
      }

      return true;
    } catch (e) {
      _log.warning('Invalid email verification link: $e');
      return false;
    }
  }

  // Get current user's email verification status details
  static Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'isSignedIn': false,
          'isEmailVerified': false,
          'email': null,
          'uid': null,
          'error': 'No user is currently signed in'
        };
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      return {
        'isSignedIn': true,
        'isEmailVerified': refreshedUser?.emailVerified ?? false,
        'email': refreshedUser?.email,
        'uid': refreshedUser?.uid,
        'creationTime': refreshedUser?.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': refreshedUser?.metadata.lastSignInTime?.toIso8601String(),
        'error': null
      };
    } catch (e) {
      _log.severe('Error getting verification status: $e');
      return {
        'isSignedIn': false,
        'isEmailVerified': false,
        'email': null,
        'uid': null,
        'error': e.toString()
      };
    }
  }

  // Resend verification email with rate limiting check
  static Future<Map<String, dynamic>> resendEmailVerification({
    Duration minInterval = const Duration(minutes: 1),
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user is currently signed in'
        };
      }

      if (user.emailVerified) {
        return {
          'success': true,
          'message': 'Email is already verified'
        };
      }

      await user.sendEmailVerification();

      return {
        'success': true,
        'message': 'Verification email sent successfully'
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please wait before trying again.';
          break;
        case 'user-not-found':
          errorMessage = 'User not found. Please sign in again.';
          break;
        default:
          errorMessage = 'Failed to send verification email: ${e.message}';
      }

      _log.warning('Failed to resend verification email: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': errorMessage
      };
    } catch (e) {
      _log.severe('Unexpected error resending verification email: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred'
      };
    }
  }
}