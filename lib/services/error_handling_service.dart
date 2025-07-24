import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsacco/services/analytics_service.dart';
import 'package:smartsacco/services/notification_service.dart';
import 'package:smartsacco/models/notification.dart';

class ErrorHandlingService {
  static final ErrorHandlingService _instance =
      ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final NotificationService _notificationService = NotificationService();

  // Error types
  static const String _errorTypeNetwork = 'network';
  static const String _errorTypeAuthentication = 'authentication';
  static const String _errorTypeDatabase = 'database';
  static const String _errorTypePayment = 'payment';
  static const String _errorTypeVoice = 'voice';
  static const String _errorTypeValidation = 'validation';
  static const String _errorTypeSystem = 'system';
  // static const String _errorTypeUnknown = 'unknown'; // Removed unused field

  // Error severity levels
  static const String _severityLow = 'low';
  static const String _severityMedium = 'medium';
  static const String _severityHigh = 'high';
  static const String _severityCritical = 'critical';

  // Error tracking
  final List<Map<String, dynamic>> _errorLog = [];
  final StreamController<Map<String, dynamic>> _errorStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get errorStream => _errorStreamController.stream;

  // Initialize error handling
  Future<void> initialize() async {
    // Set up global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Set up uncaught error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleUncaughtError(error, stack);
      return true;
    };

    // Set up periodic error reporting
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _reportErrorsToServer();
    });

    debugPrint('Error handling service initialized');
  }

  // Handle Flutter errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final error = {
      'type': _errorTypeSystem,
      'severity': _severityHigh,
      'message': details.exception.toString(),
      'stack_trace': details.stack?.toString(),
      'library': details.library ?? 'unknown',
      'context': details.context?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    _logError(error);
    _errorStreamController.add(error);
  }

  // Handle uncaught errors
  void _handleUncaughtError(Object error, StackTrace stack) {
    final errorData = {
      'type': _errorTypeSystem,
      'severity': _severityCritical,
      'message': error.toString(),
      'stack_trace': stack.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    _logError(errorData);
    _errorStreamController.add(errorData);
  }

  // Log error
  Future<void> _logError(Map<String, dynamic> error) async {
    try {
      // Add to local log
      _errorLog.add(error);

      // Keep only last 100 errors in memory
      if (_errorLog.length > 100) {
        _errorLog.removeRange(0, _errorLog.length - 100);
      }

      // Save to local storage
      await _saveErrorToLocalStorage(error);

      // Track analytics
      await _analytics.trackError(
        errorType: error['type'],
        errorMessage: error['message'],
        stackTrace: error['stack_trace'],
        context: error,
      );

      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('Error logged: ${error['type']} - ${error['message']}');
      }
    } catch (e) {
      debugPrint('Error logging error: $e');
    }
  }

  // Save error to local storage
  Future<void> _saveErrorToLocalStorage(Map<String, dynamic> error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorKey = 'error_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(errorKey, jsonEncode(error));
    } catch (e) {
      debugPrint('Error saving error to local storage: $e');
    }
  }

  // Report errors to server
  Future<void> _reportErrorsToServer() async {
    try {
      if (_errorLog.isEmpty) return;

      final errorsToReport = List<Map<String, dynamic>>.from(_errorLog);
      _errorLog.clear();

      for (final error in errorsToReport) {
        await _firestore.collection('error_logs').add({
          ...error,
          'reported_at': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Reported ${errorsToReport.length} errors to server');
    } catch (e) {
      debugPrint('Error reporting errors to server: $e');
    }
  }

  // Handle network errors
  Future<void> handleNetworkError(
    String operation,
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    final errorData = {
      'type': _errorTypeNetwork,
      'severity': _severityMedium,
      'message': 'Network error during $operation: ${error.toString()}',
      'operation': operation,
      'context': context,
      'additional_data': additionalData,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    await _logError(errorData);
    await _showUserFriendlyError(
      'Network Error',
      'Please check your internet connection and try again.',
    );
  }

  // Handle authentication errors
  Future<void> handleAuthenticationError(
    String operation,
    dynamic error, {
    String? context,
  }) async {
    final errorData = {
      'type': _errorTypeAuthentication,
      'severity': _severityHigh,
      'message': 'Authentication error during $operation: ${error.toString()}',
      'operation': operation,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    await _logError(errorData);
    await _showUserFriendlyError(
      'Authentication Error',
      'Please log in again.',
    );
  }

  // Handle database errors
  Future<void> handleDatabaseError(
    String operation,
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    final errorData = {
      'type': _errorTypeDatabase,
      'severity': _severityHigh,
      'message': 'Database error during $operation: ${error.toString()}',
      'operation': operation,
      'context': context,
      'additional_data': additionalData,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    await _logError(errorData);
    await _showUserFriendlyError(
      'Database Error',
      'Unable to save or retrieve data. Please try again.',
    );
  }

  // Handle payment errors
  Future<void> handlePaymentError(
    String operation,
    dynamic error, {
    String? transactionId,
    Map<String, dynamic>? paymentData,
  }) async {
    final errorData = {
      'type': _errorTypePayment,
      'severity': _severityHigh,
      'message': 'Payment error during $operation: ${error.toString()}',
      'operation': operation,
      'transaction_id': transactionId,
      'payment_data': paymentData,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    await _logError(errorData);
    await _showUserFriendlyError(
      'Payment Error',
      'Payment could not be processed. Please try again.',
    );
  }

  // Handle voice errors
  Future<void> handleVoiceError(
    String operation,
    dynamic error, {
    String? command,
    Map<String, dynamic>? voiceData,
  }) async {
    final errorData = {
      'type': _errorTypeVoice,
      'severity': _severityMedium,
      'message': 'Voice error during $operation: ${error.toString()}',
      'operation': operation,
      'command': command,
      'voice_data': voiceData,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    await _logError(errorData);
    await _showUserFriendlyError(
      'Voice Error',
      'Voice command could not be processed. Please try again.',
    );
  }

  // Handle validation errors
  Future<void> handleValidationError(
    String field,
    String message, {
    Map<String, dynamic>? formData,
  }) async {
    final errorData = {
      'type': _errorTypeValidation,
      'severity': _severityLow,
      'message': 'Validation error for $field: $message',
      'field': field,
      'form_data': formData,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': _auth.currentUser?.uid,
    };

    await _logError(errorData);
    await _showUserFriendlyError('Validation Error', message);
  }

  // Show user-friendly error message
  Future<void> _showUserFriendlyError(String title, String message) async {
    try {
      // Send notification
      final user = _auth.currentUser;
      if (user != null) {
        await _notificationService.sendNotificationToUser(
          userId: user.uid,
          title: title,
          message: message,
          type: NotificationType.general,
          data: {'type': 'error'},
        );
      }

      // Track error display
      await _analytics.trackFeatureUsage(
        featureName: 'error_displayed',
        parameters: {'title': title, 'message': message},
      );
    } catch (e) {
      debugPrint('Error showing user-friendly error: $e');
    }
  }

  // Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final stats = <String, dynamic>{};
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    // Filter errors from last 24 hours
    final recentErrors = _errorLog.where((error) {
      final timestamp = DateTime.parse(error['timestamp']);
      return timestamp.isAfter(last24Hours);
    }).toList();

    // Count by type
    final typeCounts = <String, int>{};
    final severityCounts = <String, int>{};

    for (final error in recentErrors) {
      final type = error['type'] as String? ?? 'unknown';
      final severity = error['severity'] as String? ?? 'unknown';

      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
    }

    stats['total_errors_24h'] = recentErrors.length;
    stats['total_errors_all_time'] = _errorLog.length;
    stats['errors_by_type'] = typeCounts;
    stats['errors_by_severity'] = severityCounts;
    stats['most_common_error'] = typeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return stats;
  }

  // Get recent errors
  List<Map<String, dynamic>> getRecentErrors({int limit = 10}) {
    final sortedErrors = List<Map<String, dynamic>>.from(_errorLog);
    sortedErrors.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp']);
      final bTime = DateTime.parse(b['timestamp']);
      return bTime.compareTo(aTime);
    });

    return sortedErrors.take(limit).toList();
  }

  // Clear error log
  Future<void> clearErrorLog() async {
    try {
      _errorLog.clear();

      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('error_'));
      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('Error log cleared');
    } catch (e) {
      debugPrint('Error clearing error log: $e');
    }
  }

  // Test error handling
  Future<void> testErrorHandling() async {
    try {
      // Simulate different types of errors
      await handleNetworkError('test_operation', 'Test network error');
      await handleValidationError('test_field', 'Test validation error');
      await handleVoiceError('test_voice', 'Test voice error');

      debugPrint('Error handling test completed');
    } catch (e) {
      debugPrint('Error during error handling test: $e');
    }
  }

  // Get error recommendations
  List<String> getErrorRecommendations() {
    final recommendations = <String>[];
    final stats = getErrorStatistics();

    if (stats['total_errors_24h'] > 10) {
      recommendations.add(
        'High error rate detected. Consider checking system stability.',
      );
    }

    final networkErrors = stats['errors_by_type']['network'] ?? 0;
    if (networkErrors > 5) {
      recommendations.add(
        'Multiple network errors. Check internet connectivity.',
      );
    }

    final authErrors = stats['errors_by_type']['authentication'] ?? 0;
    if (authErrors > 3) {
      recommendations.add(
        'Authentication issues detected. Consider re-authentication.',
      );
    }

    final criticalErrors = stats['errors_by_severity']['critical'] ?? 0;
    if (criticalErrors > 0) {
      recommendations.add(
        'Critical errors detected. Immediate attention required.',
      );
    }

    return recommendations;
  }

  // Dispose resources
  void dispose() {
    _errorStreamController.close();
  }
}
