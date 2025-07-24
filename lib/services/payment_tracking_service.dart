import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smartsacco/services/notification_service.dart';
import 'package:smartsacco/models/notification.dart';

class PaymentTrackingService {
  static final PaymentTrackingService _instance =
      PaymentTrackingService._internal();
  factory PaymentTrackingService() => _instance;
  PaymentTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Webhook server URL - update this with your actual webhook server URL
  static const String _webhookBaseUrl = 'https://your-webhook-server.com';

  // Stream controllers for real-time payment status updates
  final Map<String, StreamController<Map<String, dynamic>>>
  _paymentStatusControllers = {};
  final Map<String, Timer> _statusCheckTimers = {};

  // Track payment status with real-time updates
  Stream<Map<String, dynamic>> trackPaymentStatus(String transactionId) {
    if (_paymentStatusControllers.containsKey(transactionId)) {
      return _paymentStatusControllers[transactionId]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>();
    _paymentStatusControllers[transactionId] = controller;

    // Start periodic status checking
    _startStatusChecking(transactionId);

    // Listen to Firestore changes
    _listenToTransactionChanges(transactionId);

    return controller.stream;
  }

  // Start periodic status checking for a transaction
  void _startStatusChecking(String transactionId) {
    // Check status every 10 seconds for the first 2 minutes, then every 30 seconds
    int checkCount = 0;
    const int maxChecks =
        24; // 2 minutes of 10-second checks + 10 minutes of 30-second checks

    _statusCheckTimers[transactionId] = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        checkCount++;

        try {
          final status = await getPaymentStatus(transactionId);

          if (status['success']) {
            final transactionData = status['transaction'];
            final currentStatus = transactionData['status'];

            // Emit status update
            _paymentStatusControllers[transactionId]?.add(transactionData);

            // Stop checking if payment is completed or failed
            if (currentStatus == 'completed' || currentStatus == 'failed') {
              _stopStatusChecking(transactionId);
              _paymentStatusControllers[transactionId]?.close();
              _paymentStatusControllers.remove(transactionId);
            }
          }

          // Switch to 30-second intervals after 2 minutes
          if (checkCount == 12) {
            timer.cancel();
            _statusCheckTimers[transactionId] = Timer.periodic(
              const Duration(seconds: 30),
              (timer) async {
                checkCount++;

                try {
                  final status = await getPaymentStatus(transactionId);

                  if (status['success']) {
                    final transactionData = status['transaction'];
                    final currentStatus = transactionData['status'];

                    _paymentStatusControllers[transactionId]?.add(
                      transactionData,
                    );

                    if (currentStatus == 'completed' ||
                        currentStatus == 'failed') {
                      _stopStatusChecking(transactionId);
                      _paymentStatusControllers[transactionId]?.close();
                      _paymentStatusControllers.remove(transactionId);
                    }
                  }

                  // Stop checking after max checks
                  if (checkCount >= maxChecks) {
                    _stopStatusChecking(transactionId);
                    _paymentStatusControllers[transactionId]?.add({
                      'status': 'timeout',
                      'message': 'Payment status check timed out',
                    });
                    _paymentStatusControllers[transactionId]?.close();
                    _paymentStatusControllers.remove(transactionId);
                  }
                } catch (e) {
                  debugPrint('Error checking payment status: $e');
                }
              },
            );
          }

          // Stop checking after max checks
          if (checkCount >= maxChecks) {
            _stopStatusChecking(transactionId);
            _paymentStatusControllers[transactionId]?.add({
              'status': 'timeout',
              'message': 'Payment status check timed out',
            });
            _paymentStatusControllers[transactionId]?.close();
            _paymentStatusControllers.remove(transactionId);
          }
        } catch (e) {
          debugPrint('Error checking payment status: $e');
        }
      },
    );
  }

  // Stop status checking for a transaction
  void _stopStatusChecking(String transactionId) {
    _statusCheckTimers[transactionId]?.cancel();
    _statusCheckTimers.remove(transactionId);
  }

  // Listen to Firestore transaction changes
  void _listenToTransactionChanges(String transactionId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('reference', isEqualTo: transactionId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final data = doc.data() as Map<String, dynamic>?;

            _paymentStatusControllers[transactionId]?.add({
              'id': doc.id,
              'status': data?['status'],
              'amount': data?['amount'],
              'type': data?['type'],
              'method': data?['method'],
              'date': data?['date'],
              'reference': data?['reference'],
              'error': data?['error'],
              'momoCallback': data?['momoCallback'],
            });
          }
        });
  }

  // Get payment status from webhook server
  Future<Map<String, dynamic>> getPaymentStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_webhookBaseUrl/payment-status/$transactionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to get payment status',
          'error': 'HTTP_${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error getting payment status: $e');
      return {
        'success': false,
        'message': 'Network error while checking payment status',
        'error': 'NETWORK_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Retry failed payment
  Future<Map<String, dynamic>> retryPayment({
    required String transactionId,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_webhookBaseUrl/retry-payment/$transactionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Send notification to user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _notificationService.sendNotificationToUser(
            userId: user.uid,
            title: 'Payment Retry Initiated',
            message:
                'Your payment is being retried. You will receive a mobile money prompt shortly.',
            type: NotificationType.payment,
            data: {'transactionId': transactionId, 'type': 'payment_retry'},
          );
        }

        return result;
      } else {
        return {
          'success': false,
          'message': 'Failed to retry payment',
          'error': 'HTTP_${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Error retrying payment: $e');
      return {
        'success': false,
        'message': 'Network error while retrying payment',
        'error': 'NETWORK_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? status,
    int limit = 50,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'id': doc.id,
          'amount': (data?['amount'] ?? 0).toDouble(),
          'type': data?['type'] ?? '',
          'status': data?['status'] ?? '',
          'method': data?['method'] ?? '',
          'date': data?['date'],
          'reference': data?['reference'] ?? '',
          'phoneNumber': data?['phoneNumber'] ?? '',
          'error': data?['error'],
          'momoCallback': data?['momoCallback'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting payment history: $e');
      return [];
    }
  }

  // Get pending payments for a user
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .where('status', whereIn: ['pending', 'processing', 'retrying'])
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'id': doc.id,
          'amount': (data?['amount'] ?? 0).toDouble(),
          'type': data?['type'] ?? '',
          'status': data?['status'] ?? '',
          'method': data?['method'] ?? '',
          'date': data?['date'],
          'reference': data?['reference'] ?? '',
          'phoneNumber': data?['phoneNumber'] ?? '',
          'retryCount': data?['retryCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting pending payments: $e');
      return [];
    }
  }

  // Cancel a pending payment
  Future<Map<String, dynamic>> cancelPayment(String transactionId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
          'error': 'AUTH_ERROR',
        };
      }

      // Update transaction status
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(transactionId)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

      // Stop tracking this payment
      _stopStatusChecking(transactionId);
      _paymentStatusControllers[transactionId]?.close();
      _paymentStatusControllers.remove(transactionId);

      // Send notification
      await _notificationService.sendNotificationToUser(
        userId: user.uid,
        title: 'Payment Cancelled',
        message: 'Your payment has been cancelled successfully.',
        type: NotificationType.payment,
        data: {'transactionId': transactionId, 'type': 'payment_cancelled'},
      );

      return {
        'success': true,
        'message': 'Payment cancelled successfully',
        'transactionId': transactionId,
      };
    } catch (e) {
      debugPrint('Error cancelling payment: $e');
      return {
        'success': false,
        'message': 'Error cancelling payment',
        'error': 'CANCELLATION_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Get payment statistics for a user
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {};
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .get();

      int totalPayments = 0;
      int completedPayments = 0;
      int failedPayments = 0;
      int pendingPayments = 0;
      double totalAmount = 0;
      double completedAmount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = (data?['amount'] ?? 0).toDouble();
        final status = data?['status'] ?? '';

        totalPayments++;
        totalAmount += amount;

        switch (status) {
          case 'completed':
            completedPayments++;
            completedAmount += amount;
            break;
          case 'failed':
            failedPayments++;
            break;
          case 'pending':
          case 'processing':
          case 'retrying':
            pendingPayments++;
            break;
        }
      }

      return {
        'totalPayments': totalPayments,
        'completedPayments': completedPayments,
        'failedPayments': failedPayments,
        'pendingPayments': pendingPayments,
        'totalAmount': totalAmount,
        'completedAmount': completedAmount,
        'successRate': totalPayments > 0
            ? (completedPayments / totalPayments) * 100
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting payment statistics: $e');
      return {};
    }
  }

  // Dispose of all resources
  void dispose() {
    for (var controller in _paymentStatusControllers.values) {
      controller.close();
    }
    _paymentStatusControllers.clear();

    for (var timer in _statusCheckTimers.values) {
      timer.cancel();
    }
    _statusCheckTimers.clear();
  }
}
