// ignore_for_file: unnecessary_null_comparison, unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:smartsacco/services/momoservices.dart';
import 'package:smartsacco/config/mtn_api_config.dart';
import 'package:smartsacco/services/notification_service.dart';
import 'package:smartsacco/models/notification.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MomoService _momoService = MomoService();
  final NotificationService _notificationService = NotificationService();

  // Process deposit payment
  Future<Map<String, dynamic>> processDeposit({
    required String userId,
    required double amount,
    required String phoneNumber, //Make it nullable
    String? description,
  }) async {
    try {
      debugPrint('Processing deposit: $amount for user: $userId');

      //Add null check for phoneNumber
      if (phoneNumber == null || phoneNumber.isEmpty) {
        return {
          'success': false,
          'message': 'Phone number is required',
          'error': 'PHONE_REQUIRED',
        };
      }

      // Validate phone number
      if (!_momoService.isValidPhoneNumber(phoneNumber)) {
        return {
          'success': false,
          'message':
              'Invalid phone number format. Please use a valid MTN Uganda number.',
          'error': 'INVALID_PHONE',
        };
      }

      // Format phone number for MTN API
      final formattedPhone = _momoService.formatPhoneNumber(phoneNumber);

      // Generate external ID
      final externalId = 'DEPOSIT_${DateTime.now().millisecondsSinceEpoch}';

      // Create transaction record in Firestore
      final transactionRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
            'amount': amount,
            'type': 'Deposit',
            'method': 'MTN MoMo',
            'status': 'success',
            'date': FieldValue.serverTimestamp(),
            'phoneNumber': formattedPhone,
            'externalId': externalId,
            'description': description ?? 'SACCO Deposit',
            'reference': externalId,
          });

      // Request payment from MTN
      final paymentResult = await _momoService.requestPayment(
        phoneNumber: formattedPhone,
        amount: amount,
        externalId: externalId,
        payerMessage: description ?? 'SACCO Deposit',
      );

      if (paymentResult['success']) {
        // Update transaction with reference ID
        await transactionRef.update({
          'referenceId': paymentResult['referenceId'],
          'status': 'Processing',
        });

        // Start monitoring transaction status
        _monitorTransactionStatus(userId, externalId, paymentResult['referenceId'], transactionRef);

        return {
          'success': true,
          'message':
              'Payment request sent successfully. Please check your phone for the payment prompt.',
          'transactionId': transactionRef.id,
          'externalId': externalId,
          'referenceId': paymentResult['referenceId'],
        };
      } else {
        // Update transaction as failed
        await transactionRef.update({
          'status': 'Failed',
          'error': paymentResult['message'],
        });

        return {
          'success': false,
          'message': paymentResult['message'],
          'error': paymentResult['error'],
        };
      }
    } catch (e) {
      debugPrint('Error processing deposit: $e');
      return {
        'success': false,
        'message':
            'An error occurred while processing your deposit. Please try again.',
        'error': 'PROCESSING_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Process withdrawal payment
  Future<Map<String, dynamic>> processWithdrawal({
    required String userId,
    required double amount,
    required String phoneNumber,
    String? description,
  }) async {
    try {
      debugPrint('Processing withdrawal: $amount for user: $userId');

      // Validate phone number
      if (!_momoService.isValidPhoneNumber(phoneNumber)) {
        return {
          'success': false,
          'message':
              'Invalid phone number format. Please use a valid MTN Uganda number.',
          'error': 'INVALID_PHONE',
        };
      }

      // Format phone number for MTN API
      final formattedPhone = _momoService.formatPhoneNumber(phoneNumber);

      // Generate external ID
      final externalId = 'WITHDRAWAL_${DateTime.now().millisecondsSinceEpoch}';

      // Create transaction record in Firestore
      final transactionRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add({
            'amount': amount,
            'type': 'Withdrawal',
            'method': 'MTN MoMo',
            'status': 'Successful',
            'date': FieldValue.serverTimestamp(),
            'phoneNumber': formattedPhone,
            'externalId': externalId,
            'description': description ?? 'SACCO Withdrawal',
            'reference': externalId,
          });

      // Process transfer via MTN
      final transferResult = await _momoService.transferMoney(
        phoneNumber: formattedPhone,
        amount: amount,
        externalId: externalId,
        payeeMessage: description ?? 'SACCO Withdrawal',
      );

      if (transferResult['success']) {
        // Update transaction with reference ID
        await transactionRef.update({
          'referenceId': transferResult['referenceId'],
          'status': 'Processing',
        });

        // Start monitoring transaction status
        _monitorTransactionStatus(userId, externalId, transferResult['referenceId'], transactionRef);

        return {
          'success': true,
          'message':
              'Withdrawal initiated successfully. You will receive the money shortly.',
          'transactionId': transactionRef.id,
          'externalId': externalId,
          'referenceId': transferResult['referenceId'],
        };
      } else {
        // Update transaction as failed
        await transactionRef.update({
          'status': 'Failed',
          'error': transferResult['message'],
        });

        return {
          'success': false,
          'message': transferResult['message'],
          'error': transferResult['error'],
        };
      }
    } catch (e) {
      debugPrint('Error processing withdrawal: $e');
      return {
        'success': false,
        'message':
            'An error occurred while processing your withdrawal. Please try again.',
        'error': 'PROCESSING_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Monitor transaction status
  Future<void> _monitorTransactionStatus(
    String userId,
    String externalId,
    String referenceId,
    DocumentReference transactionRef,
  ) async {
    try {
      // Check status with retry
      final statusResult = await _momoService.checkTransactionStatus(
        externalId,
        referenceId,
        maxRetries: 12, // 1 minute total
        delay: const Duration(seconds: 5),
      );

      if (statusResult['success']) {
        final status = statusResult['status'];
        final financialTransactionId = statusResult['financialTransactionId'];

        // Update transaction status
        await transactionRef.update({
          'status': _mapMTNStatus(status),
          'financialTransactionId': financialTransactionId,
          'statusDetails': statusResult['data'],
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Send notification based on status
        if (status == 'SUCCESSFUL') {
          await _notificationService.sendNotificationToUser(
            userId: userId,
            title: 'Payment Successful',
            message: 'Your transaction has been completed successfully.',
            type: NotificationType.payment,
            data: {
              'transactionId': transactionRef.id,
              'type': 'payment_success',
            },
          );
        } else if (status == 'FAILED' || status == 'REJECTED') {
          await _notificationService.sendNotificationToUser(
            userId: userId,
            title: 'Payment Failed',
            message: 'Your transaction was not completed. Please try again.',
            type: NotificationType.payment,
            data: {
              'transactionId': transactionRef.id,
              'type': 'payment_failed',
            },
          );
        }
      } else {
        // Update as timeout
        await transactionRef.update({
          'status': 'Timeout',
          'error': statusResult['message'],
        });
      }
    } catch (e) {
      debugPrint('Error monitoring transaction status: $e');
      await transactionRef.update({
        'status': 'Error',
        'error': 'Failed to check transaction status: $e',
      });
    }
  }

  // Map MTN status to app status
  String _mapMTNStatus(String mtnStatus) {
    switch (mtnStatus.toUpperCase()) {
      case 'SUCCESSFUL':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'PENDING':
        return 'Pending';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      case 'TIMEOUT':
        return 'Timeout';
      default:
        return 'Unknown';
    }
  }

  // Get transaction status
  Future<Map<String, dynamic>> getTransactionStatus(
    String transactionId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('transactions')
          .where(FieldPath.documentId, isEqualTo: transactionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'Transaction not found'};
      }

      final data = querySnapshot.docs.first.data();
      return {
        'success': true,
        'status': data['status'],
        'amount': data['amount'],
        'type': data['type'],
        'method': data['method'],
        'date': data['date'],
        'externalId': data['externalId'],
        'referenceId': data['referenceId'],
        'financialTransactionId': data['financialTransactionId'],
        'error': data['error'],
      };
    } catch (e) {
      debugPrint('Error getting transaction status: $e');
      return {
        'success': false,
        'message': 'Error retrieving transaction status',
        'error': e.toString(),
      };
    }
  }

  // Get account balance
  Future<Map<String, dynamic>> getAccountBalance() async {
    try {
      final result = await _momoService.getAccountBalance();
      return result;
    } catch (e) {
      debugPrint('Error getting account balance: $e');
      return {
        'success': false,
        'message': 'Error retrieving account balance',
        'error': e.toString(),
      };
    }
  }

  // Get account holder info
  Future<Map<String, dynamic>> getAccountHolderInfo(String phoneNumber) async {
    try {
      final formattedPhone = _momoService.formatPhoneNumber(phoneNumber);
      final result = await _momoService.getAccountHolderInfo(formattedPhone);
      return result;
    } catch (e) {
      debugPrint('Error getting account holder info: $e');
      return {
        'success': false,
        'message': 'Error retrieving account holder information',
        'error': e.toString(),
      };
    }
  }

  // Validate phone number
  bool isValidPhoneNumber(String phoneNumber) {
    if (phoneNumber == Null) return false;
    return _momoService.isValidPhoneNumber(phoneNumber);
  }

  // Format phone number
  String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber == Null) return 'throw ArgumentError("Phone number cannot be null");';
    return _momoService.formatPhoneNumber(phoneNumber);
  }

  // Get configuration summary
  Map<String, dynamic> getConfigSummary() {
    return MTNApiConfig.configSummary;
  }
}
