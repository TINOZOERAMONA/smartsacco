import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class TransactionValidationService {
  static final TransactionValidationService _instance =
      TransactionValidationService._internal();
  factory TransactionValidationService() => _instance;
  TransactionValidationService._internal();

  final Logger _logger = Logger('TransactionValidationService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate deposit transaction
  Future<Map<String, dynamic>> validateDepositTransaction({
    required String userId,
    required double amount,
    required String method,
    required String transactionId,
  }) async {
    try {
      _logger.info(
        'Validating deposit transaction: $transactionId for user: $userId',
      );

      // Check if transaction exists in transactions collection
      final transactionDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        return {
          'valid': false,
          'error': 'Transaction not found in transactions collection',
          'transactionId': transactionId,
        };
      }

      final transactionData = transactionDoc.data()!;

      // Validate transaction data
      if (transactionData['amount'] != amount) {
        return {
          'valid': false,
          'error': 'Amount mismatch in transaction',
          'expected': amount,
          'actual': transactionData['amount'],
        };
      }

      if (transactionData['type'] != 'Deposit') {
        return {
          'valid': false,
          'error': 'Transaction type mismatch',
          'expected': 'Deposit',
          'actual': transactionData['type'],
        };
      }

      if (transactionData['method'] != method) {
        return {
          'valid': false,
          'error': 'Method mismatch in transaction',
          'expected': method,
          'actual': transactionData['method'],
        };
      }

      if (transactionData['status'] != 'Completed') {
        return {
          'valid': false,
          'error': 'Transaction status not completed',
          'actual': transactionData['status'],
        };
      }

      // Check if savings record exists
      final savingsQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savings')
          .where('amount', isEqualTo: amount)
          .where('type', isEqualTo: 'Deposit')
          .where('method', isEqualTo: method)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (savingsQuery.docs.isEmpty) {
        return {
          'valid': false,
          'error': 'Savings record not found for deposit',
          'transactionId': transactionId,
        };
      }

      final savingsData = savingsQuery.docs.first.data();

      // Validate savings data
      if (savingsData['amount'] != amount) {
        return {
          'valid': false,
          'error': 'Amount mismatch in savings record',
          'expected': amount,
          'actual': savingsData['amount'],
        };
      }

      _logger.info('Deposit transaction validation successful: $transactionId');

      return {
        'valid': true,
        'transactionId': transactionId,
        'savingsId': savingsQuery.docs.first.id,
        'message': 'Deposit transaction validated successfully',
      };
    } catch (e) {
      _logger.severe('Error validating deposit transaction: $e');
      return {
        'valid': false,
        'error': 'Validation error: $e',
        'transactionId': transactionId,
      };
    }
  }

  // Validate withdrawal transaction
  Future<Map<String, dynamic>> validateWithdrawalTransaction({
    required String userId,
    required double amount,
    required String method,
    required String reference,
  }) async {
    try {
      _logger.info(
        'Validating withdrawal transaction for user: $userId, reference: $reference',
      );

      // Check if transaction exists in transactions collection
      final transactionQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'Withdrawal')
          .where('method', isEqualTo: method)
          .where('reference', isEqualTo: reference)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (transactionQuery.docs.isEmpty) {
        return {
          'valid': false,
          'error': 'Withdrawal transaction not found',
          'reference': reference,
        };
      }

      final transactionData = transactionQuery.docs.first.data();

      // Validate transaction data
      if (transactionData['amount'] != amount) {
        return {
          'valid': false,
          'error': 'Amount mismatch in withdrawal transaction',
          'expected': amount,
          'actual': transactionData['amount'],
        };
      }

      if (transactionData['status'] != 'Completed') {
        return {
          'valid': false,
          'error': 'Withdrawal transaction status not completed',
          'actual': transactionData['status'],
        };
      }

      _logger.info('Withdrawal transaction validation successful: $reference');

      return {
        'valid': true,
        'transactionId': transactionQuery.docs.first.id,
        'reference': reference,
        'message': 'Withdrawal transaction validated successfully',
      };
    } catch (e) {
      _logger.severe('Error validating withdrawal transaction: $e');
      return {
        'valid': false,
        'error': 'Validation error: $e',
        'reference': reference,
      };
    }
  }

  // Validate all transactions for a user
  Future<Map<String, dynamic>> validateAllUserTransactions(
    String userId,
  ) async {
    try {
      _logger.info('Validating all transactions for user: $userId');

      // Get all transactions
      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      // Get all savings records
      final savingsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savings')
          .orderBy('date', descending: true)
          .get();

      final validationResults = {
        'totalTransactions': transactionsSnapshot.docs.length,
        'totalSavings': savingsSnapshot.docs.length,
        'validTransactions': 0 as int,
        'invalidTransactions': 0 as int,
        'errors': <String>[],
        'details': <Map<String, dynamic>>[],
      };

      // Validate each transaction
      for (var transactionDoc in transactionsSnapshot.docs) {
        final transactionData = transactionDoc.data();
        final transactionType = transactionData['type'] as String?;
        final amount = transactionData['amount'] as double?;
        final method = transactionData['method'] as String?;
        final status = transactionData['status'] as String?;

        if (transactionType == null ||
            amount == null ||
            method == null ||
            status == null) {
          validationResults['invalidTransactions'] =
              (validationResults['invalidTransactions'] as int) + 1;
          (validationResults['errors'] as List<String>).add(
            'Invalid transaction data structure: ${transactionDoc.id}',
          );
          (validationResults['details'] as List<Map<String, dynamic>>).add({
            'transactionId': transactionDoc.id,
            'valid': false,
            'error': 'Missing required fields',
          });
          continue;
        }

        // Check if corresponding savings record exists for deposits
        if (transactionType == 'Deposit') {
          final savingsExists = savingsSnapshot.docs.any((savingsDoc) {
            final savingsData = savingsDoc.data();
            return savingsData['amount'] == amount &&
                savingsData['type'] == 'Deposit' &&
                savingsData['method'] == method;
          });
          if (!savingsExists) {
            validationResults['invalidTransactions'] =
                (validationResults['invalidTransactions'] as int) + 1;
            (validationResults['errors'] as List<String>).add(
              'Missing savings record for deposit: ${transactionDoc.id}',
            );
            (validationResults['details'] as List<Map<String, dynamic>>).add({
              'transactionId': transactionDoc.id,
              'valid': false,
              'error': 'Missing corresponding savings record',
            });
            continue;
          }
          }
        validationResults['validTransactions'] =
            (validationResults['validTransactions'] as int) + 1;
        (validationResults['details'] as List<Map<String, dynamic>>).add({
          'transactionId': transactionDoc.id,
          'valid': true,
          'type': transactionType,
          'amount': amount,
          'method': method,
          'status': status,
        });
      }

      _logger.info('Transaction validation completed for user: $userId');
      _logger.info(
        'Valid: ${validationResults['validTransactions']}, Invalid: ${validationResults['invalidTransactions']}',
      );

      return validationResults;
    } catch (e) {
      _logger.severe('Error validating all transactions: $e');
      return {'valid': false, 'error': 'Validation error: $e'};
    }
  }

  // Verify transaction data integrity
  Future<Map<String, dynamic>> verifyTransactionIntegrity(String userId) async {
    try {
      _logger.info('Verifying transaction integrity for user: $userId');

      // Get user's current savings balance
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {'valid': false, 'error': 'User document not found'};
      }

      // Calculate expected savings from transactions
      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('status', isEqualTo: 'Completed')
          .get();

      double expectedSavings = 0;
      final transactionDetails = <Map<String, dynamic>>[];

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final amount = data['amount'] as double?;

        if (type == 'Deposit' && amount != null) {
          expectedSavings += amount;
          transactionDetails.add({
            'type': 'Deposit',
            'amount': amount,
            'date': data['date'],
          });
        } else if (type == 'Withdrawal' && amount != null) {
          expectedSavings -= amount;
          transactionDetails.add({
            'type': 'Withdrawal',
            'amount': amount,
            'date': data['date'],
          });
        }
      }

      // Get actual savings from savings collection
      final savingsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savings')
          .get();

      double actualSavings = 0;
      for (var doc in savingsSnapshot.docs) {
        final data = doc.data();
        final amount = data['amount'] as double?;
        if (amount != null) {
          actualSavings += amount;
        }
      }

      final balanceDifference = (expectedSavings - actualSavings).abs();
      final isBalanced =
          balanceDifference <
          0.01; // Allow for small floating point differences

      _logger.info('Transaction integrity check completed');
      _logger.info('Expected savings: $expectedSavings');
      _logger.info('Actual savings: $actualSavings');
      _logger.info('Difference: $balanceDifference');
      _logger.info('Balanced: $isBalanced');

      return {
        'valid': isBalanced,
        'expectedSavings': expectedSavings,
        'actualSavings': actualSavings,
        'difference': balanceDifference,
        'isBalanced': isBalanced,
        'totalTransactions': transactionsSnapshot.docs.length,
        'totalSavingsRecords': savingsSnapshot.docs.length,
        'transactionDetails': transactionDetails,
      };
    } catch (e) {
      _logger.severe('Error verifying transaction integrity: $e');
      return {'valid': false, 'error': 'Integrity check error: $e'};
    }
  }

  // Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStatistics(String userId) async {
    try {
      _logger.info('Getting transaction statistics for user: $userId');

      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      double totalDeposits = 0;
      double totalWithdrawals = 0;
      int depositCount = 0;
      int withdrawalCount = 0;
      int completedTransactions = 0;
      int pendingTransactions = 0;
      int failedTransactions = 0;

      final methodStats = <String, int>{};
      final monthlyStats = <String, Map<String, dynamic>>{};

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        final amount = data['amount'] as double?;
        final status = data['status'] as String?;
        final method = data['method'] as String?;
        final date = data['date'] as Timestamp?;

        if (type == 'Deposit' && amount != null) {
          totalDeposits += amount;
          depositCount++;
        } else if (type == 'Withdrawal' && amount != null) {
          totalWithdrawals += amount;
          withdrawalCount++;
        }

        if (status == 'Completed') {
          completedTransactions++;
        } else if (status == 'Pending') {
          pendingTransactions++;
        } else if (status == 'Failed') {
          failedTransactions++;
        }

        if (method != null) {
          methodStats[method] = (methodStats[method] ?? 0) + 1;
        }

        if (date != null) {
          final monthKey =
              '${date.toDate().year}-${date.toDate().month.toString().padLeft(2, '0')}';
          if (!monthlyStats.containsKey(monthKey)) {
            monthlyStats[monthKey] = {
              'deposits': 0.0,
              'withdrawals': 0.0,
              'count': 0,
            };
          }

          if (type == 'Deposit' && amount != null) {
            monthlyStats[monthKey]!['deposits'] += amount;
          } else if (type == 'Withdrawal' && amount != null) {
            monthlyStats[monthKey]!['withdrawals'] += amount;
          }
          monthlyStats[monthKey]!['count']++;
        }
      }

      return {
        'totalTransactions': transactionsSnapshot.docs.length,
        'totalDeposits': totalDeposits,
        'totalWithdrawals': totalWithdrawals,
        'netAmount': totalDeposits - totalWithdrawals,
        'depositCount': depositCount,
        'withdrawalCount': withdrawalCount,
        'completedTransactions': completedTransactions,
        'pendingTransactions': pendingTransactions,
        'failedTransactions': failedTransactions,
        'methodStats': methodStats,
        'monthlyStats': monthlyStats,
        'successRate': transactionsSnapshot.docs.isNotEmpty
            ? (completedTransactions / transactionsSnapshot.docs.length * 100)
                  .toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      _logger.severe('Error getting transaction statistics: $e');
      return {'error': 'Statistics error: $e'};
    }
  }
}
