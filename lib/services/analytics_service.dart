import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Event types
  static const String _eventLogin = 'user_login';
  static const String _eventLogout = 'user_logout';
  static const String _eventDeposit = 'deposit_made';
  static const String _eventWithdrawal = 'withdrawal_made';
  static const String _eventLoanApplication = 'loan_application';
  static const String _eventLoanApproval = 'loan_approval';
  static const String _eventPayment = 'payment_made';
  static const String _eventVoiceCommand = 'voice_command';
  static const String _eventError = 'error_occurred';
  static const String _eventPageView = 'page_view';
  static const String _eventFeatureUsage = 'feature_usage';

  // Track user event
  Future<void> trackEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final eventData = {
        'event_name': eventName,
        'user_id': userId ?? currentUser?.uid ?? 'anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'parameters': parameters ?? {},
        'platform': defaultTargetPlatform.toString(),
        'app_version': '1.0.0', // You can make this dynamic
      };

      await _firestore.collection('analytics_events').add(eventData);
      debugPrint('Analytics event tracked: $eventName');
    } catch (e) {
      debugPrint('Error tracking analytics event: $e');
    }
  }

  // Track user login
  Future<void> trackLogin({
    required String method, // 'email', 'voice', 'biometric'
    bool isSuccess = true,
    String? errorMessage,
  }) async {
    await trackEvent(
      eventName: _eventLogin,
      parameters: {
        'method': method,
        'success': isSuccess,
        'error_message': errorMessage,
      },
    );
  }

  // Track user logout
  Future<void> trackLogout({String? reason}) async {
    await trackEvent(
      eventName: _eventLogout,
      parameters: {'reason': reason ?? 'user_initiated'},
    );
  }

  // Track deposit
  Future<void> trackDeposit({
    required double amount,
    required String method, // 'mobile_money', 'bank_transfer'
    required String status, // 'pending', 'completed', 'failed'
    String? transactionId,
    String? errorMessage,
  }) async {
    await trackEvent(
      eventName: _eventDeposit,
      parameters: {
        'amount': amount,
        'method': method,
        'status': status,
        'transaction_id': transactionId,
        'error_message': errorMessage,
      },
    );
  }

  // Track withdrawal
  Future<void> trackWithdrawal({
    required double amount,
    required String method,
    required String status,
    String? transactionId,
    String? errorMessage,
  }) async {
    await trackEvent(
      eventName: _eventWithdrawal,
      parameters: {
        'amount': amount,
        'method': method,
        'status': status,
        'transaction_id': transactionId,
        'error_message': errorMessage,
      },
    );
  }

  // Track loan application
  Future<void> trackLoanApplication({
    required double amount,
    required String status, // 'submitted', 'approved', 'rejected'
    String? loanId,
    String? reason,
  }) async {
    await trackEvent(
      eventName: _eventLoanApplication,
      parameters: {
        'amount': amount,
        'status': status,
        'loan_id': loanId,
        'reason': reason,
      },
    );
  }

  // Track loan approval
  Future<void> trackLoanApproval({
    required String loanId,
    required String status, // 'approved', 'rejected'
    String? approvedBy,
    String? reason,
  }) async {
    await trackEvent(
      eventName: _eventLoanApproval,
      parameters: {
        'loan_id': loanId,
        'status': status,
        'approved_by': approvedBy,
        'reason': reason,
      },
    );
  }

  // Track payment
  Future<void> trackPayment({
    required double amount,
    required String type, // 'loan_repayment', 'fee_payment'
    required String method,
    required String status,
    String? transactionId,
  }) async {
    await trackEvent(
      eventName: _eventPayment,
      parameters: {
        'amount': amount,
        'type': type,
        'method': method,
        'status': status,
        'transaction_id': transactionId,
      },
    );
  }

  // Track voice command
  Future<void> trackVoiceCommand({
    required String command,
    required bool isSuccess,
    String? errorMessage,
    int? responseTime,
  }) async {
    await trackEvent(
      eventName: _eventVoiceCommand,
      parameters: {
        'command': command,
        'success': isSuccess,
        'error_message': errorMessage,
        'response_time_ms': responseTime,
      },
    );
  }

  // Track error
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent(
      eventName: _eventError,
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        'context': context,
      },
    );
  }

  // Track page view
  Future<void> trackPageView({
    required String pageName,
    String? previousPage,
    Map<String, dynamic>? parameters,
  }) async {
    await trackEvent(
      eventName: _eventPageView,
      parameters: {
        'page_name': pageName,
        'previous_page': previousPage,
        'parameters': parameters,
      },
    );
  }

  // Track feature usage
  Future<void> trackFeatureUsage({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    await trackEvent(
      eventName: _eventFeatureUsage,
      parameters: {'feature_name': featureName, 'parameters': parameters},
    );
  }

  // Get analytics data for reporting
  Future<Map<String, dynamic>> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    String? userId,
  }) async {
    try {
      Query query = _firestore.collection('analytics_events');

      // Apply filters
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (eventType != null) {
        query = query.where('event_name', isEqualTo: eventType);
      }
      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final querySnapshot = await query.get();
      final events = querySnapshot.docs.map((doc) => doc.data()).toList();

      return {
        'total_events': events.length,
        'events': events,
        'summary': _generateEventSummary(events),
      };
    } catch (e) {
      debugPrint('Error getting analytics data: $e');
      return {'total_events': 0, 'events': [], 'summary': {}};
    }
  }

  // Generate event summary
  Map<String, dynamic> _generateEventSummary(List<dynamic> events) {
    final summary = <String, dynamic>{};
    final eventCounts = <String, int>{};
    final userActivity = <String, int>{};
    final dailyActivity = <String, int>{};

    for (final event in events) {
      final eventName = event['event_name'] as String? ?? 'unknown';
      final userId = event['user_id'] as String? ?? 'anonymous';
      final timestamp = event['timestamp'] as Timestamp?;

      // Count events by type
      eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;

      // Count user activity
      userActivity[userId] = (userActivity[userId] ?? 0) + 1;

      // Count daily activity
      if (timestamp != null) {
        final date = timestamp.toDate().toIso8601String().split('T')[0];
        dailyActivity[date] = (dailyActivity[date] ?? 0) + 1;
      }
    }

    summary['event_counts'] = eventCounts;
    summary['user_activity'] = userActivity;
    summary['daily_activity'] = dailyActivity;
    summary['unique_users'] = userActivity.length;
    summary['total_events'] = events.length;

    return summary;
  }

  // Get user behavior insights
  Future<Map<String, dynamic>> getUserInsights(String userId) async {
    try {
      final userEvents = await getAnalyticsData(userId: userId);
      final events = userEvents['events'] as List<dynamic>;

      final insights = <String, dynamic>{};
      final featureUsage = <String, int>{};
      final errorCount = 0;
      final loginCount = 0;
      final lastActivity = DateTime.now();

      for (final event in events) {
        final eventName = event['event_name'] as String? ?? '';
        final timestamp = event['timestamp'] as Timestamp?;

        // Count feature usage
        if (eventName == _eventFeatureUsage) {
          final featureName =
              event['parameters']?['feature_name'] as String? ?? 'unknown';
          featureUsage[featureName] = (featureUsage[featureName] ?? 0) + 1;
        }

        // Count errors
        if (eventName == _eventError) {
          // errorCount++;
        }

        // Count logins
        if (eventName == _eventLogin) {
          // loginCount++;
        }

        // Track last activity
        if (timestamp != null) {
          final eventTime = timestamp.toDate();
          if (eventTime.isAfter(lastActivity)) {
            // lastActivity = eventTime;
          }
        }
      }

      insights['feature_usage'] = featureUsage;
      insights['error_count'] = errorCount;
      insights['login_count'] = loginCount;
      insights['last_activity'] = lastActivity.toIso8601String();
      insights['total_events'] = events.length;

      return insights;
    } catch (e) {
      debugPrint('Error getting user insights: $e');
      return {};
    }
  }

  // Get financial analytics
  Future<Map<String, dynamic>> getFinancialAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final depositEvents = await getAnalyticsData(
        startDate: startDate,
        endDate: endDate,
        eventType: _eventDeposit,
      );

      final withdrawalEvents = await getAnalyticsData(
        startDate: startDate,
        endDate: endDate,
        eventType: _eventWithdrawal,
      );

      final loanEvents = await getAnalyticsData(
        startDate: startDate,
        endDate: endDate,
        eventType: _eventLoanApplication,
      );

      final paymentEvents = await getAnalyticsData(
        startDate: startDate,
        endDate: endDate,
        eventType: _eventPayment,
      );

      return {
        'deposits': _calculateFinancialSummary(
          depositEvents['events'] as List<dynamic>,
        ),
        'withdrawals': _calculateFinancialSummary(
          withdrawalEvents['events'] as List<dynamic>,
        ),
        'loans': _calculateLoanSummary(loanEvents['events'] as List<dynamic>),
        'payments': _calculateFinancialSummary(
          paymentEvents['events'] as List<dynamic>,
        ),
      };
    } catch (e) {
      debugPrint('Error getting financial analytics: $e');
      return {};
    }
  }

  // Calculate financial summary
  Map<String, dynamic> _calculateFinancialSummary(List<dynamic> events) {
    double totalAmount = 0;
    double successfulAmount = 0;
    double failedAmount = 0;
    int totalCount = 0;
    int successfulCount = 0;
    int failedCount = 0;

    for (final event in events) {
      final amount = (event['parameters']?['amount'] as num?)?.toDouble() ?? 0;
      final status = event['parameters']?['status'] as String? ?? 'unknown';

      totalAmount += amount;
      totalCount++;

      if (status == 'completed' || status == 'successful') {
        successfulAmount += amount;
        successfulCount++;
      } else if (status == 'failed') {
        failedAmount += amount;
        failedCount++;
      }
    }

    return {
      'total_amount': totalAmount,
      'successful_amount': successfulAmount,
      'failed_amount': failedAmount,
      'total_count': totalCount,
      'successful_count': successfulCount,
      'failed_count': failedCount,
      'success_rate': totalCount > 0 ? (successfulCount / totalCount) * 100 : 0,
    };
  }

  // Calculate loan summary
  Map<String, dynamic> _calculateLoanSummary(List<dynamic> events) {
    double totalRequested = 0;
    double totalApproved = 0;
    double totalRejected = 0;
    int totalCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;

    for (final event in events) {
      final amount = (event['parameters']?['amount'] as num?)?.toDouble() ?? 0;
      final status = event['parameters']?['status'] as String? ?? 'unknown';

      totalRequested += amount;
      totalCount++;

      if (status == 'approved') {
        totalApproved += amount;
        approvedCount++;
      } else if (status == 'rejected') {
        totalRejected += amount;
        rejectedCount++;
      }
    }

    return {
      'total_requested': totalRequested,
      'total_approved': totalApproved,
      'total_rejected': totalRejected,
      'total_count': totalCount,
      'approved_count': approvedCount,
      'rejected_count': rejectedCount,
      'approval_rate': totalCount > 0 ? (approvedCount / totalCount) * 100 : 0,
    };
  }

  // Export analytics data
  Future<String> exportAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'json',
  }) async {
    try {
      final data = await getAnalyticsData(
        startDate: startDate,
        endDate: endDate,
      );

      if (format == 'json') {
        return jsonEncode(data);
      } else {
        // You can implement CSV export here
        return jsonEncode(data);
      }
    } catch (e) {
      debugPrint('Error exporting analytics data: $e');
      return '';
    }
  }

  // Clear analytics data (admin only)
  Future<bool> clearAnalyticsData({
    DateTime? beforeDate,
    String? userId,
  }) async {
    try {
      Query query = _firestore.collection('analytics_events');

      if (beforeDate != null) {
        query = query.where('timestamp', isLessThan: beforeDate);
      }
      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final querySnapshot = await query.get();
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error clearing analytics data: $e');
      return false;
    }
  }
}
