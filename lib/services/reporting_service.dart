import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class ReportingService {
  static final ReportingService _instance = ReportingService._internal();
  factory ReportingService() => _instance;
  ReportingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Report types
  static const String _reportTypeFinancial = 'financial';
  static const String _reportTypeMember = 'member';
  static const String _reportTypeLoan = 'loan';
  static const String _reportTypeTransaction = 'transaction';
  // Remove unused field
  // static const String _reportTypeAnalytics = 'analytics'; // Removed unused field

  // Generate comprehensive financial report
  Future<Map<String, dynamic>> generateFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
    String? memberId,
  }) async {
    try {
      final report = <String, dynamic>{
        'report_type': _reportTypeFinancial,
        'generated_at': DateTime.now().toIso8601String(),
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'summary': {},
        'details': {},
      };

      // Get deposits
      final deposits = await _getDeposits(startDate, endDate, memberId);
      report['details']['deposits'] = deposits;

      // Get withdrawals
      final withdrawals = await _getWithdrawals(startDate, endDate, memberId);
      report['details']['withdrawals'] = withdrawals;

      // Get loan payments
      final loanPayments = await _getLoanPayments(startDate, endDate, memberId);
      report['details']['loan_payments'] = loanPayments;

      // Calculate summary
      report['summary'] = _calculateFinancialSummary(
        deposits,
        withdrawals,
        loanPayments,
      );

      return report;
    } catch (e) {
      debugPrint('Error generating financial report: $e');
      return {'error': 'Failed to generate financial report: $e'};
    }
  }

  // Generate member activity report
  Future<Map<String, dynamic>> generateMemberReport({
    DateTime? startDate,
    DateTime? endDate,
    String? memberId,
  }) async {
    try {
      final report = <String, dynamic>{
        'report_type': _reportTypeMember,
        'generated_at': DateTime.now().toIso8601String(),
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'members': [],
        'summary': {},
      };

      // Get member data
      Query query = _firestore
          .collection('users')
          .where('role', isEqualTo: 'member');
      if (memberId != null) {
        query = query.where(FieldPath.documentId, isEqualTo: memberId);
      }

      final memberSnapshot = await query.get();
      final members = <Map<String, dynamic>>[];

      // Fix nullable value errors in generateMemberReport
      for (final doc in memberSnapshot.docs) {
        final memberData = doc.data() as Map<String, dynamic>?;
        if (memberData == null) continue;

        final memberId = doc.id;
        final transactions = await _getMemberTransactions(
          memberId,
          startDate,
          endDate,
        );
        final loans = await _getMemberLoans(memberId, startDate, endDate);

        final memberReport = {
          'member_id': memberId,
          'name': memberData['name'] ?? 'Unknown',
          'email': memberData['email'] ?? '',
          'phone': memberData['phone'] ?? '',
          'join_date': memberData['joinDate']?.toDate().toIso8601String(),
          'transactions': transactions,
          'loans': loans,
          'summary': _calculateMemberSummary(transactions, loans),
        };

        members.add(memberReport);
      }

      report['members'] = members;
      report['summary'] = _calculateOverallMemberSummary(members);

      return report;
    } catch (e) {
      debugPrint('Error generating member report: $e');
      return {'error': 'Failed to generate member report: $e'};
    }
  }

  // Generate loan report
  Future<Map<String, dynamic>> generateLoanReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      final report = <String, dynamic>{
        'report_type': _reportTypeLoan,
        'generated_at': DateTime.now().toIso8601String(),
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'loans': [],
        'summary': {},
      };

      // Get loan data
      Query query = _firestore.collection('loans');
      if (startDate != null) {
        query = query.where(
          'applicationDate',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        query = query.where('applicationDate', isLessThanOrEqualTo: endDate);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final loanSnapshot = await query.get();
      final loans = <Map<String, dynamic>>[];

      for (final doc in loanSnapshot.docs) {
        final loanData = doc.data() as Map<String, dynamic>?;
        if (loanData == null) continue;

        final loanId = doc.id;

        // Get loan payments
        final payments = await _getLoanPaymentsByLoanId(loanId);

        final loanReport = {
          'loan_id': loanId,
          'member_id': loanData['memberId'],
          'member_name': loanData['memberName'] ?? 'Unknown',
          'amount': loanData['amount'] ?? 0,
          'interest_rate': loanData['interestRate'] ?? 0,
          'term_months': loanData['termMonths'] ?? 0,
          'status': loanData['status'] ?? 'pending',
          'application_date': loanData['applicationDate']
              ?.toDate()
              .toIso8601String(),
          'approval_date': loanData['approvalDate']?.toDate().toIso8601String(),
          'disbursement_date': loanData['disbursementDate']
              ?.toDate()
              .toIso8601String(),
          'payments': payments,
          'summary': _calculateLoanSummary(loanData, payments),
        };

        loans.add(loanReport);
      }

      report['loans'] = loans;
      report['summary'] = _calculateOverallLoanSummary(loans);

      return report;
    } catch (e) {
      debugPrint('Error generating loan report: $e');
      return {'error': 'Failed to generate loan report: $e'};
    }
  }

  // Generate transaction report
  Future<Map<String, dynamic>> generateTransactionReport({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? memberId,
  }) async {
    try {
      final report = <String, dynamic>{
        'report_type': _reportTypeTransaction,
        'generated_at': DateTime.now().toIso8601String(),
        'period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
        'transactions': [],
        'summary': {},
      };

      // Get transaction data
      Query query = _firestore.collection('transactions');
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      if (memberId != null) {
        query = query.where('memberId', isEqualTo: memberId);
      }

      final transactionSnapshot = await query.get();
      final transactions = <Map<String, dynamic>>[];

      for (final doc in transactionSnapshot.docs) {
        final transactionData = doc.data() as Map<String, dynamic>?;
        if (transactionData == null) continue;

        final transactionId = doc.id;

        final transactionReport = {
          'transaction_id': transactionId,
          'member_id': transactionData['memberId'],
          'member_name': transactionData['memberName'] ?? 'Unknown',
          'type': transactionData['type'] ?? 'unknown',
          'amount': transactionData['amount'] ?? 0,
          'status': transactionData['status'] ?? 'pending',
          'method': transactionData['method'] ?? 'unknown',
          'timestamp': transactionData['timestamp']?.toDate().toIso8601String(),
          'reference': transactionData['reference'] ?? '',
          'description': transactionData['description'] ?? '',
        };

        transactions.add(transactionReport);
      }

      report['transactions'] = transactions;
      report['summary'] = _calculateTransactionSummary(transactions);

      return report;
    } catch (e) {
      debugPrint('Error generating transaction report: $e');
      return {'error': 'Failed to generate transaction report: $e'};
    }
  }

  // Export report to file
  Future<String?> exportReport({
    required Map<String, dynamic> report,
    required String format,
    String? fileName,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'report_${report['report_type']}_$timestamp';
      final finalFileName = fileName ?? defaultFileName;

      String filePath;
      String content;

      if (format.toLowerCase() == 'csv') {
        content = _convertToCsv(report);
        filePath = '${directory.path}/$finalFileName.csv';
      } else {
        content = jsonEncode(report);
        filePath = '${directory.path}/$finalFileName.json';
      }

      final file = File(filePath);
      await file.writeAsString(content);

      return filePath;
    } catch (e) {
      debugPrint('Error exporting report: $e');
      return null;
    }
  }

  // Share report
  Future<bool> shareReport({
    required Map<String, dynamic> report,
    required String format,
    String? fileName,
  }) async {
    try {
      final filePath = await exportReport(
        report: report,
        format: format,
        fileName: fileName,
      );

      if (filePath != null) {
        await Share.shareXFiles([XFile(filePath)]);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing report: $e');
      return false;
    }
  }

  // Helper methods for data retrieval
  Future<List<Map<String, dynamic>>> _getDeposits(
    DateTime? startDate,
    DateTime? endDate,
    String? memberId,
  ) async {
    Query query = _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'deposit');

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>?)
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getWithdrawals(
    DateTime? startDate,
    DateTime? endDate,
    String? memberId,
  ) async {
    Query query = _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'withdrawal');

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>?)
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getLoanPayments(
    DateTime? startDate,
    DateTime? endDate,
    String? memberId,
  ) async {
    Query query = _firestore
        .collection('transactions')
        .where('type', isEqualTo: 'loan_payment');

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>?)
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getMemberTransactions(
    String memberId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    Query query = _firestore
        .collection('transactions')
        .where('memberId', isEqualTo: memberId);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>?)
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getMemberLoans(
    String memberId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    Query query = _firestore
        .collection('loans')
        .where('memberId', isEqualTo: memberId);

    if (startDate != null) {
      query = query.where('applicationDate', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('applicationDate', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>?)
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getLoanPaymentsByLoanId(
    String loanId,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('loanId', isEqualTo: loanId)
        .where('type', isEqualTo: 'loan_payment')
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>?)
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // Helper methods for calculations
  Map<String, dynamic> _calculateFinancialSummary(
    List<Map<String, dynamic>> deposits,
    List<Map<String, dynamic>> withdrawals,
    List<Map<String, dynamic>> loanPayments,
  ) {
    double totalDeposits = 0;
    double totalWithdrawals = 0;
    double totalLoanPayments = 0;

    for (final deposit in deposits) {
      totalDeposits += (deposit['amount'] as num?)?.toDouble() ?? 0;
    }

    for (final withdrawal in withdrawals) {
      totalWithdrawals += (withdrawal['amount'] as num?)?.toDouble() ?? 0;
    }

    for (final payment in loanPayments) {
      totalLoanPayments += (payment['amount'] as num?)?.toDouble() ?? 0;
    }

    return {
      'total_deposits': totalDeposits,
      'total_withdrawals': totalWithdrawals,
      'total_loan_payments': totalLoanPayments,
      'net_flow': totalDeposits - totalWithdrawals,
      'deposit_count': deposits.length,
      'withdrawal_count': withdrawals.length,
      'payment_count': loanPayments.length,
    };
  }

  Map<String, dynamic> _calculateMemberSummary(
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> loans,
  ) {
    double totalTransactions = 0;
    double totalLoans = 0;
    int activeLoans = 0;

    for (final transaction in transactions) {
      totalTransactions += (transaction['amount'] as num?)?.toDouble() ?? 0;
    }

    for (final loan in loans) {
      totalLoans += (loan['amount'] as num?)?.toDouble() ?? 0;
      if (loan['status'] == 'active') {
        activeLoans++;
      }
    }

    return {
      'total_transactions': totalTransactions,
      'total_loans': totalLoans,
      'active_loans': activeLoans,
      'transaction_count': transactions.length,
      'loan_count': loans.length,
    };
  }

  Map<String, dynamic> _calculateOverallMemberSummary(
    List<Map<String, dynamic>> members,
  ) {
    int totalMembers = 0;
    int totalTransactions = 0;
    int totalLoans = 0;
    int activeLoans = 0;

    for (final member in members) {
      final summary = member['summary'] as Map<String, dynamic>? ?? {};
      totalMembers++;
      totalTransactions +=
          (summary['total_transactions'] as num?)?.toInt() ?? 0;
      totalLoans += (summary['total_loans'] as num?)?.toInt() ?? 0;
      activeLoans += (summary['active_loans'] as num?)?.toInt() ?? 0;
    }

    return {
      'total_members': totalMembers,
      'total_transactions': totalTransactions,
      'total_loans': totalLoans,
      'active_loans': activeLoans,
      'average_transactions_per_member': totalMembers > 0
          ? totalTransactions / totalMembers
          : 0,
      'average_loans_per_member': totalMembers > 0
          ? totalLoans / totalMembers
          : 0,
    };
  }

  Map<String, dynamic> _calculateLoanSummary(
    Map<String, dynamic> loanData,
    List<Map<String, dynamic>> payments,
  ) {
    final amount = (loanData['amount'] as num?)?.toDouble() ?? 0;
    final interestRate = (loanData['interestRate'] as num?)?.toDouble() ?? 0;
    double totalPaid = 0;

    for (final payment in payments) {
      totalPaid += (payment['amount'] as num?)?.toDouble() ?? 0;
    }

    final remaining = amount - totalPaid;
    final interestAmount = amount * (interestRate / 100);

    return {
      'total_amount': amount,
      'total_paid': totalPaid,
      'remaining_balance': remaining,
      'interest_amount': interestAmount,
      'payment_count': payments.length,
      'status': loanData['status'] ?? 'pending',
    };
  }

  Map<String, dynamic> _calculateOverallLoanSummary(
    List<Map<String, dynamic>> loans,
  ) {
    double totalRequested = 0;
    double totalApproved = 0;
    double totalDisbursed = 0;
    double totalRepaid = 0;
    int pendingCount = 0;
    int approvedCount = 0;
    int activeCount = 0;
    int completedCount = 0;

    for (final loan in loans) {
      final amount = (loan['amount'] as num?)?.toDouble() ?? 0;
      final status = loan['status'] as String? ?? 'pending';
      final summary = loan['summary'] as Map<String, dynamic>;
      final totalPaid = summary['total_paid'] ?? 0;

      totalRequested += amount;

      switch (status) {
        case 'pending':
          pendingCount++;
          break;
        case 'approved':
          approvedCount++;
          totalApproved += amount;
          break;
        case 'active':
          activeCount++;
          totalDisbursed += amount;
          break;
        case 'completed':
          completedCount++;
          totalDisbursed += amount;
          break;
      }

      totalRepaid += totalPaid;
    }

    return {
      'total_requested': totalRequested,
      'total_approved': totalApproved,
      'total_disbursed': totalDisbursed,
      'total_repaid': totalRepaid,
      'pending_count': pendingCount,
      'approved_count': approvedCount,
      'active_count': activeCount,
      'completed_count': completedCount,
      'approval_rate': totalRequested > 0
          ? (totalApproved / totalRequested) * 100
          : 0,
      'repayment_rate': totalDisbursed > 0
          ? (totalRepaid / totalDisbursed) * 100
          : 0,
    };
  }

  Map<String, dynamic> _calculateTransactionSummary(
    List<Map<String, dynamic>> transactions,
  ) {
    double totalAmount = 0;
    double successfulAmount = 0;
    double failedAmount = 0;
    int totalCount = 0;
    int successfulCount = 0;
    int failedCount = 0;
    final typeCounts = <String, int>{};
    final methodCounts = <String, int>{};

    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
      final status = transaction['status'] as String? ?? 'pending';
      final type = transaction['type'] as String? ?? 'unknown';
      final method = transaction['method'] as String? ?? 'unknown';

      totalAmount += amount;
      totalCount++;

      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;

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
      'type_distribution': typeCounts,
      'method_distribution': methodCounts,
    };
  }

  // Convert report to CSV format
  String _convertToCsv(Map<String, dynamic> report) {
    final reportType = report['report_type'] as String? ?? 'unknown';

    switch (reportType) {
      case _reportTypeFinancial:
        return _convertFinancialReportToCsv(report);
      case _reportTypeMember:
        return _convertMemberReportToCsv(report);
      case _reportTypeLoan:
        return _convertLoanReportToCsv(report);
      case _reportTypeTransaction:
        return _convertTransactionReportToCsv(report);
      default:
        return '';
    }
  }

  String _convertFinancialReportToCsv(Map<String, dynamic> report) {
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add(['Date', 'Type', 'Amount', 'Status', 'Method', 'Reference']);

    // Add deposits
    final deposits = report['details']?['deposits'] as List<dynamic>? ?? [];
    for (final deposit in deposits) {
      csvData.add([
        deposit['timestamp'] ?? '',
        'Deposit',
        deposit['amount'] ?? 0,
        deposit['status'] ?? '',
        deposit['method'] ?? '',
        deposit['reference'] ?? '',
      ]);
    }

    // Add withdrawals
    final withdrawals =
        report['details']?['withdrawals'] as List<dynamic>? ?? [];
    for (final withdrawal in withdrawals) {
      csvData.add([
        withdrawal['timestamp'] ?? '',
        'Withdrawal',
        withdrawal['amount'] ?? 0,
        withdrawal['status'] ?? '',
        withdrawal['method'] ?? '',
        withdrawal['reference'] ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  String _convertMemberReportToCsv(Map<String, dynamic> report) {
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add([
      'Member ID',
      'Name',
      'Email',
      'Phone',
      'Join Date',
      'Total Transactions',
      'Total Loans',
      'Active Loans',
    ]);

    // Add member data
    final members = report['members'] as List<dynamic>? ?? [];
    for (final member in members) {
      final summary = member['summary'] as Map<String, dynamic>? ?? {};
      csvData.add([
        member['member_id'] ?? '',
        member['name'] ?? '',
        member['email'] ?? '',
        member['phone'] ?? '',
        member['join_date'] ?? '',
        summary['total_transactions'] ?? 0,
        summary['total_loans'] ?? 0,
        summary['active_loans'] ?? 0,
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  String _convertLoanReportToCsv(Map<String, dynamic> report) {
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add([
      'Loan ID',
      'Member ID',
      'Member Name',
      'Amount',
      'Interest Rate',
      'Term (Months)',
      'Status',
      'Application Date',
      'Approval Date',
      'Disbursement Date',
    ]);

    // Add loan data
    final loans = report['loans'] as List<dynamic>? ?? [];
    for (final loan in loans) {
      csvData.add([
        loan['loan_id'] ?? '',
        loan['member_id'] ?? '',
        loan['member_name'] ?? '',
        loan['amount'] ?? 0,
        loan['interest_rate'] ?? 0,
        loan['term_months'] ?? 0,
        loan['status'] ?? '',
        loan['application_date'] ?? '',
        loan['approval_date'] ?? '',
        loan['disbursement_date'] ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  String _convertTransactionReportToCsv(Map<String, dynamic> report) {
    final csvData = <List<dynamic>>[];

    // Add header
    csvData.add([
      'Transaction ID',
      'Member ID',
      'Member Name',
      'Type',
      'Amount',
      'Status',
      'Method',
      'Timestamp',
      'Reference',
      'Description',
    ]);

    // Add transaction data
    final transactions = report['transactions'] as List<dynamic>? ?? [];
    for (final transaction in transactions) {
      csvData.add([
        transaction['transaction_id'] ?? '',
        transaction['member_id'] ?? '',
        transaction['member_name'] ?? '',
        transaction['type'] ?? '',
        transaction['amount'] ?? 0,
        transaction['status'] ?? '',
        transaction['method'] ?? '',
        transaction['timestamp'] ?? '',
        transaction['reference'] ?? '',
        transaction['description'] ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }
}
