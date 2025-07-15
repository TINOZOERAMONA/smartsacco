// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:smartsacco/pages/loan.dart';
// import 'dart:developer';

// class LoanService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// Returns a stream of loans for the given memberId, providing real-time updates.
//   Stream<List<Loan>> listenToLoansForMember(String memberId) {
//     return _firestore
//         .collection('users')
//         .doc(memberId)
//         .collection('loans')
//         .snapshots()
//         .asyncMap((snapshot) async {
//       final loans = await Future.wait(snapshot.docs.map((doc) async {
//         final paymentsSnap = await doc.reference.collection('payments').get();

//         return Loan(
//           id: doc.id,
//           amount: (doc['amount'] as num?)?.toDouble() ?? 0,
//           remainingBalance: (doc['remainingBalance'] as num?)?.toDouble() ?? 0,
//           disbursementDate: (doc['disbursementDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//           dueDate: (doc['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//           status: doc['status'] ?? 'Pending',
//           type: doc['type'] ?? 'Personal',
//           interestRate: (doc['interestRate'] as num?)?.toDouble() ?? 12.0,
//           totalRepayment: (doc['totalRepayment'] as num?)?.toDouble() ?? 0,
//           repaymentPeriod: doc['repaymentPeriod'] ?? 12,
//           applicationDate: (doc['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//           payments: paymentsSnap.docs.map((p) {
//             return Payment(
//               amount: (p['amount'] as num?)?.toDouble() ?? 0,
//               date: (p['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
//               reference: p['reference'] ?? '',
//             );
//           }).toList(),
//         );
//       }).toList());

//       return loans;
//     });
//   }

//   /// Existing one-time fetch method (optional)
//   Future<List<Loan>> fetchLoansForMember(String memberId) async {
//     try {
//       log('Fetching loans for memberId: $memberId');

//       final loansSnapshot = await _firestore
//           .collection('users')
//           .doc(memberId)
//           .collection('loans')
//           .where(
//             'status',
//             whereIn: ['Active', 'Overdue', 'Pending', 'Approved', 'Rejected'],
//           )
//           .get();

//       if (loansSnapshot.docs.isEmpty) {
//         log('No loans found for memberId: $memberId');
//       }

//       final loans = await Future.wait(loansSnapshot.docs.map((doc) async {
//         final paymentsSnap = await doc.reference.collection('payments').get();

//         return Loan(
//           id: doc.id,
//           amount: (doc['amount'] as num?)?.toDouble() ?? 0,
//           remainingBalance: (doc['remainingBalance'] as num?)?.toDouble() ?? 0,
//           disbursementDate: (doc['disbursementDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//           dueDate: (doc['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//           status: doc['status'] ?? 'Pending',
//           type: doc['type'] ?? 'Personal',
//           interestRate: (doc['interestRate'] as num?)?.toDouble() ?? 12.0,
//           totalRepayment: (doc['totalRepayment'] as num?)?.toDouble() ?? 0,
//           repaymentPeriod: doc['repaymentPeriod'] ?? 12,
//           applicationDate: (doc['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
//           payments: paymentsSnap.docs.map((p) {
//             return Payment(
//               amount: (p['amount'] as num?)?.toDouble() ?? 0,
//               date: (p['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
//               reference: p['reference'] ?? '',
//             );
//           }).toList(),
//         );
//       }).toList());

//       return loans;
//     } catch (e, st) {
//       log('Error fetching loans: $e\n$st');
//       rethrow;
//     }
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
// Ensure correct import path
import 'dart:developer';

import 'package:smartsacco/pages/loan.dart';

class LoanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of loans for the given memberId with real-time updates
  Stream<List<Loan>> listenToLoansForMember(String memberId) {
    return _firestore
        .collection('users')
        .doc(memberId)
        .collection('loans')
        .snapshots()
        .asyncMap((snapshot) async {
      final loans = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final paymentsSnap = await doc.reference.collection('payments').get();

        return Loan(
          id: doc.id,
          amount: (data['amount'] as num).toDouble(),
          remainingBalance: (data['remainingBalance'] as num).toDouble(),
          applicantFullName: data['applicantFullName'] as String,
          applicantPhoneNumber: data['applicantPhoneNumber'] as String,
          disbursementDate: (data['disbursementDate'] as Timestamp?)?.toDate(),
          dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
          status: data['status'] as String,
          type: data['type'] as String,
          interestRate: (data['interestRate'] as num).toDouble(),
          totalRepayment: (data['totalRepayment'] as num).toDouble(),
          repaymentPeriod: data['repaymentPeriod'] as int,
          payments: paymentsSnap.docs.map((p) {
            final paymentData = p.data();
            return Payment(
              amount: (paymentData['amount'] as num).toDouble(),
              date: (paymentData['date'] as Timestamp).toDate(),
              reference: paymentData['reference'] as String,
              payerFullName: paymentData['payerFullName'] as String,
              payerPhoneNumber: paymentData['payerPhoneNumber'] as String,
              paymentMethod: paymentData['paymentMethod'] as String?,
              status: _parsePaymentStatus(paymentData['status']),
              transactionId: paymentData['transactionId'] as String?,
            );
          }).toList(),
          applicationDate: (data['applicationDate'] as Timestamp).toDate(),
          coSignerFullName: data['coSignerFullName'] as String?,
          coSignerPhoneNumber: data['coSignerPhoneNumber'] as String?,
          purpose: data['purpose'] as String?,
          loanOfficerId: data['loanOfficerId'] as String?,
          loanOfficerName: data['loanOfficerName'] as String?,
          lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(), nextPaymentAmount: 0,
        );
      }));

      return loans;
    });
  }

  /// One-time fetch method with enhanced error handling
  Future<List<Loan>> fetchLoansForMember(String memberId) async {
    try {
      log('Fetching loans for member: $memberId');

      final loansSnapshot = await _firestore
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .where('status', whereIn: ['active', 'approved', 'pending', 'overdue'])
          .get();

      final loans = await Future.wait(loansSnapshot.docs.map((doc) async {
        final data = doc.data();
        final paymentsSnap = await doc.reference.collection('payments').get();

        return Loan(
          id: doc.id,
          amount: (data['amount'] as num).toDouble(),
          remainingBalance: (data['remainingBalance'] as num).toDouble(),
          applicantFullName: data['applicantFullName'] as String,
          applicantPhoneNumber: data['applicantPhoneNumber'] as String,
          disbursementDate: (data['disbursementDate'] as Timestamp?)?.toDate(),
          dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
          status: data['status'] as String,
          type: data['type'] as String,
          interestRate: (data['interestRate'] as num).toDouble(),
          totalRepayment: (data['totalRepayment'] as num).toDouble(),
          repaymentPeriod: data['repaymentPeriod'] as int,
          payments: paymentsSnap.docs.map((p) {
            final paymentData = p.data();
            return Payment(
              amount: (paymentData['amount'] as num).toDouble(),
              date: (paymentData['date'] as Timestamp).toDate(),
              reference: paymentData['reference'] as String,
              payerFullName: paymentData['payerFullName'] as String,
              payerPhoneNumber: paymentData['payerPhoneNumber'] as String,
              paymentMethod: paymentData['paymentMethod'] as String?,
              status: _parsePaymentStatus(paymentData['status']),
              transactionId: paymentData['transactionId'] as String?,
            );
          }).toList(),
          applicationDate: (data['applicationDate'] as Timestamp).toDate(),
          coSignerFullName: data['coSignerFullName'] as String?,
          coSignerPhoneNumber: data['coSignerPhoneNumber'] as String?,
          purpose: data['purpose'] as String?,
          loanOfficerId: data['loanOfficerId'] as String?,
          loanOfficerName: data['loanOfficerName'] as String?,
          lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(), nextPaymentAmount: 0,
        );
      }));

      log('Successfully fetched ${loans.length} loans');
      return loans;
    } catch (e, stackTrace) {
      log('Error fetching loans', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Helper function to parse payment status
  PaymentStatus _parsePaymentStatus(dynamic status) {
    if (status == null) return PaymentStatus.pending;
    if (status is PaymentStatus) return status;
    
    switch (status.toString().toLowerCase()) {
      case 'completed':
        return PaymentStatus.completed;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }

  /// Add a new payment to a loan
  Future<void> addPayment({
    required String memberId,
    required String loanId,
    required Payment payment,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .doc(loanId)
          .collection('payments')
          .add(payment.toJson());

      // Update loan's remaining balance
      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .doc(loanId)
          .update({
            'remainingBalance': FieldValue.increment(-payment.amount),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
    } catch (e, stackTrace) {
      log('Error adding payment', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update loan status
  Future<void> updateLoanStatus({
    required String memberId,
    required String loanId,
    required String status,
    String? loanOfficerId,
    String? loanOfficerName,
  }) async {
    try {
      final updateData = {
        'status': status.toLowerCase(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (loanOfficerId != null) {
        updateData['loanOfficerId'] = loanOfficerId;
      }
      if (loanOfficerName != null) {
        updateData['loanOfficerName'] = loanOfficerName;
      }

      await _firestore
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .doc(loanId)
          .update(updateData);
    } catch (e, stackTrace) {
      log('Error updating loan status', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}