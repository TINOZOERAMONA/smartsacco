// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'transactionmodel.dart' hide Transaction;


// class TransactionRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> saveTransaction(String userId, Transaction transaction) async {
//     await _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('transactions')
//         .doc(transaction.id)
//         .set(transaction.toJson());
//   }
  

//   Future<List<Transaction>> getTransactions(String userId) async {
//     final snapshot = await _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('transactions')
//         .orderBy('date', descending: true)
//         .get();

//     return snapshot.docs.map((doc) {
//       return Transaction.fromJson({
//         ...doc.data(),
//         'id': doc.id,
//       });
//     }).toList();
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'transactionmodel.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save transaction to Firestore
  Future<void> saveTransaction(String userId, Transaction txn) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(txn.id)
          .set(txn.toJson());
    } catch (e) {
      throw Exception('Failed to save transaction: $e');
    }
  }

  // Update existing transaction
  Future<void> updateTransaction(String userId, Transaction txn) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(txn.id)
          .update(txn.toJson());
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get single transaction by ID
  Future<Transaction?> getTransactionById(String userId, String transactionId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Transaction.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  // Retrieve all transactions from Firestore
  Future<List<Transaction>> getTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  // Get transactions with real-time updates
  Stream<List<Transaction>> getTransactionsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          return Transaction.fromJson({
            ...doc.data(),
            'id': doc.id,
          });
        }).toList())
        .handleError((error) {
          throw Exception('Failed to stream transactions: $error');
        });
  }

  // Get transactions by date range
  Future<List<Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  // Get transactions by type (Deposit, Withdrawal, Loan Payment)
  Future<List<Transaction>> getTransactionsByType(
    String userId,
    String type,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: type)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by type: $e');
    }
  }

  // Get transactions by status (Pending, Completed, Failed)
  Future<List<Transaction>> getTransactionsByStatus(
    String userId,
    String status,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('status', isEqualTo: status)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by status: $e');
    }
  }

  // Get transactions by method (Mobile Money, Bank Transfer)
  Future<List<Transaction>> getTransactionsByMethod(
    String userId,
    String method,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('method', isEqualTo: method)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by method: $e');
    }
  }

  // Get transactions by loan ID
  Future<List<Transaction>> getTransactionsByLoanId(
    String userId,
    String loanId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('loanId', isEqualTo: loanId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by loan ID: $e');
    }
  }

  // Get transactions by phone number
  Future<List<Transaction>> getTransactionsByPhoneNumber(
    String userId,
    String phoneNumber,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get transactions by phone number: $e');
    }
  }

  // Get paginated transactions
  Future<List<Transaction>> getTransactionsPaginated(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get paginated transactions: $e');
    }
  }

  // Save multiple transactions in batch
  Future<void> saveMultipleTransactions(
    String userId,
    List<Transaction> transactions,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (final txn in transactions) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(txn.id);
        batch.set(docRef, txn.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save multiple transactions: $e');
    }
  }

  // Delete multiple transactions in batch
  Future<void> deleteMultipleTransactions(
    String userId,
    List<String> transactionIds,
  ) async {
    try {
      final batch = _firestore.batch();
      
      for (final id in transactionIds) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete multiple transactions: $e');
    }
  }

  // Get transaction count
  Future<int> getTransactionCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get transaction count: $e');
    }
  }

  // Get transaction count by status
  Future<int> getTransactionCountByStatus(String userId, String status) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('status', isEqualTo: status)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get transaction count by status: $e');
    }
  }

  // Get total amount by type
  Future<double> getTotalAmountByType(String userId, String type) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: 'Completed')
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        total += (data['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      throw Exception('Failed to get total amount by type: $e');
    }
  }

  // Get recent transactions (last N transactions)
  Future<List<Transaction>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
    String userId,
    String transactionId,
    String newStatus,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }

  // Get pending transactions
  Future<List<Transaction>> getPendingTransactions(String userId) async {
    return getTransactionsByStatus(userId, 'Pending');
  }

  // Get completed transactions
  Future<List<Transaction>> getCompletedTransactions(String userId) async {
    return getTransactionsByStatus(userId, 'Completed');
  }

  // Get failed transactions
  Future<List<Transaction>> getFailedTransactions(String userId) async {
    return getTransactionsByStatus(userId, 'Failed');
  }

  // Get deposits
  Future<List<Transaction>> getDeposits(String userId) async {
    return getTransactionsByType(userId, 'Deposit');
  }

  // Get withdrawals
  Future<List<Transaction>> getWithdrawals(String userId) async {
    return getTransactionsByType(userId, 'Withdrawal');
  }

  // Get loan payments
  Future<List<Transaction>> getLoanPayments(String userId) async {
    return getTransactionsByType(userId, 'Loan Payment');
  }
}