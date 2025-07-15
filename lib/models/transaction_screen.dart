// FILEPATH: lib/models/transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore; // add prefix here
import 'package:smartsacco/models/transaction_card.dart'; // keep your Transaction class import without hiding

class TransactionsScreen extends StatefulWidget {
  final String memberId;

  const TransactionsScreen({super.key, required this.memberId});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];

  final Color _primaryColor = const Color(0xFF3366CC);
  final Color _textSecondary = const Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final transactionsSnapshot = await firestore.FirebaseFirestore.instance
        .collection('users')
        .doc(widget.memberId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    List<Transaction> transactions = [];

    for (var doc in transactionsSnapshot.docs) {
      transactions.add(
        Transaction(
          id: doc.id,
          amount: doc['amount']?.toDouble() ?? 0,
          date: doc['date']?.toDate() ?? DateTime.now(),
          type: doc['type'] ?? 'Transaction',
          status: doc['status'] ?? 'Completed',
          method: doc['method'] ?? 'Mobile Money',
          loanId: doc['loanId'],
          paymentId: doc['paymentId'],
        ),
      );
    }

    if (mounted) {
      setState(() {
        _transactions = transactions;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
      case 'active':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'failed':
      case 'rejected':
      case 'overdue':
        return const Color(0xFFF44336);
      default:
        return _textSecondary;
    }
  }

  void _showTransactionDetails(Transaction txn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Transaction Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Transaction ID:', txn.id.substring(0, 8)),
            _buildDetailRow('Type:', txn.type),
            _buildDetailRow('Amount:', _formatCurrency(txn.amount)),
            _buildDetailRow(
              'Date:',
              DateFormat('MMM d, y h:mm a').format(txn.date),
            ),
            _buildDetailRow('Method:', txn.method),
            _buildDetailRow('Status:', txn.status),
            if (txn.loanId != null)
              _buildDetailRow('Loan ID:', txn.loanId!.substring(0, 8)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: _textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  void _filterTransactions() {
    // Implement filtering logic
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: _primaryColor),
                onPressed: _filterTransactions,
              ),
            ],
          ),
        ),
        Expanded(
          child: _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt,
                        size: 50,
                        color: _textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: GoogleFonts.poppins(color: _textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) => TransactionCard(
                    transaction: _transactions[index],
                    formatCurrency: _formatCurrency,
                    getStatusColor: _getStatusColor,
                    onTap: (txn) => _showTransactionDetails(txn),
                    primaryColor: _primaryColor,
                    textSecondary: _textSecondary,
                  ),
                ),
        ),
      ],
    );
  }
}