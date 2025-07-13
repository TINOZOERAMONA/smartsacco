// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smartsacco/pages/admin/pending_loan_page.dart';
import 'active_loan_page.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({Key? key}) : super(key: key);

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });
    try {
      final snapshot = await _firestore
          .collectionGroup('momo_callbacks')
          .orderBy('transactionId', descending: true)
          .limit(50)
          .get();

      _transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'description': data['description'] ?? '',
          'date': data['date'],
          'amount': (data['amount'] ?? 0).toDouble(),
          'type': data['type'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _transactions;
    return _transactions.where((tx) {
      final desc = (tx['description'] ?? '').toLowerCase();
      final type = (tx['type'] ?? '').toLowerCase();
      return desc.contains(_searchQuery) || type.contains(_searchQuery);
    }).toList();
  }

  Future<void> _exportTransactionsCsv() async {
    if (_transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export')),
      );
      return;
    }

    List<List<dynamic>> rows = [
      ['Description', 'Date', 'Amount', 'Type'],
      ..._filteredTransactions.map((tx) {
        final date = tx['date'];
        String formattedDate = '';
        if (date is Timestamp) {
          formattedDate = date.toDate().toIso8601String();
        } else {
          formattedDate = 'N/A';
        }

        return [
          tx['description'],
          formattedDate,
          tx['amount'].toStringAsFixed(2),
          tx['type'],
        ];
      }),
    ];

    String csvData = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(path)], text: 'Exported Transactions CSV');
    } catch (e) {
      if (kDebugMode) print('Error exporting CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e')),
      );
    }
  }

  void _navigateToPage(String page) {
    switch (page) {
      case 'members':
        Navigator.pushNamed(context, '/members');
        break;
      case 'active_loans':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActiveLoansPage()),
        );
        break;
      case 'loan_approval':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PendingLoansPage()),
        );
        break;
    }
  }

  // Live balance
  Stream<double> getCurrentBalanceStream() {
    return _firestore.collectionGroup('transactions').snapshots().map((snapshot) {
      double totalDeposits = 0;
      double totalWithdrawals = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = (data['type'] ?? '').toString().toLowerCase();

        if (type == 'deposit') {
          totalDeposits += amount;
        } else if (type == 'withdraw') {
          totalWithdrawals += amount;
        }
      }

      return totalDeposits - totalWithdrawals;
    });
  }

  // Metrics
  Future<String> _getTotalMembersCount() async {
    try {
      final snapshot = await _firestore.collection('members').get();
      return snapshot.size.toString();
    } catch (e) {
      debugPrint('Error fetching total members count: $e');
      return '0';
    }
  }

  Future<String> _getActiveLoansCount() async {
    try {
      final snapshot = await _firestore.collectionGroup('loans').get();
      final approvedLoans = snapshot.docs.where((doc) {
        final status = (doc['status'] ?? '').toString().toLowerCase().trim();
        return status == 'approved';
      }).toList();
      return approvedLoans.length.toString();
    } catch (e) {
      debugPrint('Error fetching active loans count: $e');
      return '0';
    }
  }

  Future<String> _getPendingLoansCount() async {
    try {
      final snapshot = await _firestore.collectionGroup('loans').get();
      final pendingLoans = snapshot.docs.where((doc) {
        final status = (doc['status'] ?? '').toString().toLowerCase().trim();
        return status == 'pending';
      }).toList();
      return pendingLoans.length.toString();
    } catch (e) {
      debugPrint('Error fetching pending loans count: $e');
      return '0';
    }
  }

  Future<String> _getTotalSavings() async {
    try {
      final snapshot = await _firestore.collection('savings').get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
      }
      return 'UGX${total.toStringAsFixed(2)}';
    } catch (e) {
      debugPrint('Error fetching total savings: $e');
      return 'UGX0.00';
    }
  }

  Future<Map<String, int>> _getLoanStats() async {
    try {
      final snapshot = await _firestore.collectionGroup('loans').get();
      int approved = 0, pending = 0, rejected = 0;
      for (var doc in snapshot.docs) {
        final status = (doc.data()['status'] ?? '').toString().toLowerCase();
        if (status == 'approved') {
          approved++;
        } else if (status == 'pending') {
          pending++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }
      return {'approved': approved, 'pending': pending, 'rejected': rejected};
    } catch (e) {
      debugPrint('Error fetching loan stats: $e');
      return {'approved': 0, 'pending': 0, 'rejected': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("UI Code Removed for Brevity")),
    );
  }
}
