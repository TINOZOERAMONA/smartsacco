import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smartsacco/services/notification_service.dart';
import 'package:smartsacco/models/notification.dart';

class LoanService {
  static final LoanService _instance = LoanService._internal();
  factory LoanService() => _instance;
  LoanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Submit loan application with enhanced validation
  Future<Map<String, dynamic>> submitLoanApplication({
    required String userId,
    required double amount,
    required int repaymentPeriod,
    required double interestRate,
    required String loanType,
    required String purpose,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate input
      if (amount <= 0) {
        return {
          'success': false,
          'message': 'Invalid loan amount. Amount must be greater than zero.',
          'error': 'INVALID_AMOUNT',
        };
      }

      if (repaymentPeriod <= 0) {
        return {
          'success': false,
          'message':
              'Invalid repayment period. Period must be greater than zero.',
          'error': 'INVALID_PERIOD',
        };
      }

      if (interestRate < 0) {
        return {
          'success': false,
          'message': 'Invalid interest rate. Rate cannot be negative.',
          'error': 'INVALID_RATE',
        };
      }

      // Check if user has existing pending applications
      final existingPending = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .where('status', isEqualTo: 'Pending Approval')
          .get();

      if (existingPending.docs.isNotEmpty) {
        return {
          'success': false,
          'message':
              'You already have a pending loan application. Please wait for approval.',
          'error': 'EXISTING_PENDING',
        };
      }

      // Calculate loan details
      final interest = (amount * interestRate / 100) * (repaymentPeriod / 12);
      final totalRepayment = amount + interest;
      final monthlyPayment = repaymentPeriod > 0
          ? totalRepayment / repaymentPeriod
          : 0;

      // Create loan application
      final loanRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .add({
            'amount': amount,
            'interestRate': interestRate,
            'repaymentPeriod': repaymentPeriod,
            'type': loanType,
            'purpose': purpose,
            'interest': interest,
            'totalRepayment': totalRepayment,
            'monthlyPayment': monthlyPayment,
            'remainingBalance': totalRepayment,
            'status': 'Pending Approval',
            'applicationDate': FieldValue.serverTimestamp(),
            'disbursementDate': null,
            'dueDate': null,
            'additionalData': additionalData ?? {},
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Send notification to admin (you would typically send this to all admins)
      await _notificationService.sendNotificationToAllUsers(
        title: 'New Loan Application',
        message:
            'A new loan application of UGX ${amount.toStringAsFixed(2)} has been submitted.',
        type: NotificationType.loan,
        data: {
          'loanId': loanRef.id,
          'userId': userId,
          'amount': amount,
          'type': 'new_application',
        },
      );

      return {
        'success': true,
        'message': 'Loan application submitted successfully',
        'loanId': loanRef.id,
        'status': 'Pending Approval',
      };
    } catch (e) {
      debugPrint('Error submitting loan application: $e');
      return {
        'success': false,
        'message':
            'An error occurred while submitting your loan application. Please try again.',
        'error': 'SUBMISSION_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Approve loan application (admin function)
  Future<Map<String, dynamic>> approveLoan({
    required String userId,
    required String loanId,
    required String adminId,
    String? comments,
  }) async {
    try {
      final loanDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(loanId)
          .get();

      if (!loanDoc.exists) {
        return {
          'success': false,
          'message': 'Loan application not found.',
          'error': 'LOAN_NOT_FOUND',
        };
      }

      final loanData = loanDoc.data()!;
      if (loanData['status'] != 'Pending Approval') {
        return {
          'success': false,
          'message': 'Loan application is not in pending status.',
          'error': 'INVALID_STATUS',
        };
      }

      // Calculate disbursement and due dates
      final now = DateTime.now();
      final disbursementDate = now;
      final dueDate = now.add(Duration(days: loanData['repaymentPeriod'] * 30));

      // Update loan status
      await loanDoc.reference.update({
        'status': 'Approved',
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'disbursementDate': disbursementDate,
        'dueDate': dueDate,
        'comments': comments,
      });

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: 'Loan Approved',
        message:
            'Your loan application of UGX ${loanData['amount'].toStringAsFixed(2)} has been approved.',
        type: NotificationType.loan,
        data: {
          'loanId': loanId,
          'amount': loanData['amount'],
          'type': 'loan_approved',
        },
      );

      return {
        'success': true,
        'message': 'Loan approved successfully',
        'loanId': loanId,
        'status': 'Approved',
      };
    } catch (e) {
      debugPrint('Error approving loan: $e');
      return {
        'success': false,
        'message':
            'An error occurred while approving the loan. Please try again.',
        'error': 'APPROVAL_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Reject loan application (admin function)
  Future<Map<String, dynamic>> rejectLoan({
    required String userId,
    required String loanId,
    required String adminId,
    required String reason,
  }) async {
    try {
      final loanDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(loanId)
          .get();

      if (!loanDoc.exists) {
        return {
          'success': false,
          'message': 'Loan application not found.',
          'error': 'LOAN_NOT_FOUND',
        };
      }

      final loanData = loanDoc.data()!;
      if (loanData['status'] != 'Pending Approval') {
        return {
          'success': false,
          'message': 'Loan application is not in pending status.',
          'error': 'INVALID_STATUS',
        };
      }

      // Update loan status
      await loanDoc.reference.update({
        'status': 'Rejected',
        'rejectedBy': adminId,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: 'Loan Application Rejected',
        message: 'Your loan application has been rejected. Reason: $reason',
        type: NotificationType.loan,
        data: {
          'loanId': loanId,
          'amount': loanData['amount'],
          'type': 'loan_rejected',
          'reason': reason,
        },
      );

      return {
        'success': true,
        'message': 'Loan rejected successfully',
        'loanId': loanId,
        'status': 'Rejected',
      };
    } catch (e) {
      debugPrint('Error rejecting loan: $e');
      return {
        'success': false,
        'message':
            'An error occurred while rejecting the loan. Please try again.',
        'error': 'REJECTION_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Process loan payment
  Future<Map<String, dynamic>> processLoanPayment({
    required String userId,
    required String loanId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    try {
      final loanDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(loanId)
          .get();

      if (!loanDoc.exists) {
        return {
          'success': false,
          'message': 'Loan not found.',
          'error': 'LOAN_NOT_FOUND',
        };
      }

      final loanData = loanDoc.data()!;
      if (loanData['status'] != 'Approved') {
        return {
          'success': false,
          'message': 'Loan is not in approved status.',
          'error': 'INVALID_STATUS',
        };
      }

      final remainingBalance = (loanData['remainingBalance'] ?? 0).toDouble();
      if (amount > remainingBalance) {
        return {
          'success': false,
          'message': 'Payment amount exceeds remaining balance.',
          'error': 'EXCESS_AMOUNT',
          'remainingBalance': remainingBalance,
        };
      }

      // Create payment record
      final paymentRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(loanId)
          .collection('payments')
          .add({
            'amount': amount,
            'date': FieldValue.serverTimestamp(),
            'method': method,
            'reference':
                reference ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
            'status': 'completed',
          });

      // Update loan remaining balance
      final newRemainingBalance = remainingBalance - amount;
      final isFullyPaid = newRemainingBalance <= 0;

      await loanDoc.reference.update({
        'remainingBalance': newRemainingBalance,
        'status': isFullyPaid ? 'Completed' : 'Approved',
        'lastPaymentDate': FieldValue.serverTimestamp(),
      });

      // Send notification to user
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: 'Loan Payment Received',
        message:
            'Your loan payment of UGX ${amount.toStringAsFixed(2)} has been received.',
        type: NotificationType.payment,
        data: {
          'loanId': loanId,
          'paymentId': paymentRef.id,
          'amount': amount,
          'type': 'loan_payment',
        },
      );

      return {
        'success': true,
        'message': 'Loan payment processed successfully',
        'paymentId': paymentRef.id,
        'remainingBalance': newRemainingBalance,
        'isFullyPaid': isFullyPaid,
      };
    } catch (e) {
      debugPrint('Error processing loan payment: $e');
      return {
        'success': false,
        'message':
            'An error occurred while processing your loan payment. Please try again.',
        'error': 'PAYMENT_ERROR',
        'details': e.toString(),
      };
    }
  }

  // Get loan details
  Future<Map<String, dynamic>?> getLoanDetails({
    required String userId,
    required String loanId,
  }) async {
    try {
      final loanDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(loanId)
          .get();

      if (!loanDoc.exists) {
        return null;
      }

      final loanData = loanDoc.data()!;

      // Get payment history
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .doc(loanId)
          .collection('payments')
          .orderBy('date', descending: true)
          .get();

      final payments = paymentsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'id': doc.id,
          'amount': (data?['amount'] ?? 0).toDouble(),
          'date': data?['date'],
          'method': data?['method'] ?? '',
          'reference': data?['reference'] ?? '',
          'status': data?['status'] ?? '',
        };
      }).toList();

      return {
        'id': loanId,
        'amount': (loanData['amount'] ?? 0).toDouble(),
        'interestRate': (loanData['interestRate'] ?? 0).toDouble(),
        'repaymentPeriod': loanData['repaymentPeriod'] ?? 0,
        'type': loanData['type'] ?? '',
        'purpose': loanData['purpose'] ?? '',
        'status': loanData['status'] ?? '',
        'totalRepayment': (loanData['totalRepayment'] ?? 0).toDouble(),
        'remainingBalance': (loanData['remainingBalance'] ?? 0).toDouble(),
        'monthlyPayment': (loanData['monthlyPayment'] ?? 0).toDouble(),
        'applicationDate': loanData['applicationDate'],
        'disbursementDate': loanData['disbursementDate'],
        'dueDate': loanData['dueDate'],
        'payments': payments,
      };
    } catch (e) {
      debugPrint('Error getting loan details: $e');
      return null;
    }
  }

  // Get all loans for a user
  Future<List<Map<String, dynamic>>> getUserLoans({
    required String userId,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('loans')
          .orderBy('applicationDate', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      final loans = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        loans.add({
          'id': doc.id,
          'amount': (data?['amount'] ?? 0).toDouble(),
          'type': data?['type'] ?? '',
          'status': data?['status'] ?? '',
          'totalRepayment': (data?['totalRepayment'] ?? 0).toDouble(),
          'remainingBalance': (data?['remainingBalance'] ?? 0).toDouble(),
          'applicationDate': data?['applicationDate'],
          'dueDate': data?['dueDate'],
        });
      }

      return loans;
    } catch (e) {
      debugPrint('Error getting user loans: $e');
      return [];
    }
  }

  // Get all pending loan applications (admin function)
  Future<List<Map<String, dynamic>>> getPendingLoans() async {
    try {
      final snapshot = await _firestore
          .collectionGroup('loans')
          .where('status', isEqualTo: 'Pending Approval')
          .orderBy('applicationDate', descending: true)
          .get();

      List<Map<String, dynamic>> loans = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        final userId = doc.reference.parent.parent?.id;

        // Get user details
        String userName = 'Unknown User';
        if (userId != null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(userId)
                .get();
            if (userDoc.exists) {
              userName = userDoc.data()?['fullName'] ?? 'Unknown User';
            }
          } catch (e) {
            debugPrint('Error fetching user details: $e');
          }
        }

        loans.add({
          'id': doc.id,
          'userId': userId,
          'userName': userName,
          'amount': (data?['amount'] ?? 0).toDouble(),
          'type': data?['type'] ?? '',
          'purpose': data?['purpose'] ?? '',
          'interestRate': (data?['interestRate'] ?? 0).toDouble(),
          'repaymentPeriod': data?['repaymentPeriod'] ?? 0,
          'totalRepayment': (data?['totalRepayment'] ?? 0).toDouble(),
          'applicationDate': data?['applicationDate'],
        });
      }

      return loans;
    } catch (e) {
      debugPrint('Error getting pending loans: $e');
      return [];
    }
  }
}
