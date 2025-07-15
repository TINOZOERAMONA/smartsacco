import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String Function(double) formatCurrency;
  final Color Function(String) getStatusColor;
  final Function(Transaction) onTap;
  final Color primaryColor;
  final Color textSecondary;

  const TransactionCard({
    required this.transaction,
    required this.formatCurrency,
    required this.getStatusColor,
    required this.onTap,
    required this.primaryColor,
    required this.textSecondary,
    super.key,
  });

  

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: transaction.type == 'Deposit'
                ? const Color(0xFF4CAF50).withOpacity(0.2)
                : primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            transaction.type == 'Deposit' ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.type == 'Deposit' 
                ? const Color(0xFF4CAF50) 
                : primaryColor,
          ),
        ),
        title: Text(
          transaction.type,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, y').format(transaction.date)} • ${transaction.method}',
          style: GoogleFonts.poppins(color: textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatCurrency(transaction.amount),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(transaction.status),
              backgroundColor: getStatusColor(transaction.status),
              labelStyle: GoogleFonts.poppins(fontSize: 10),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        onTap: () => onTap(transaction),
      ),
    );
  }
}

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String type;
  final String status;
  final String method;
  final String? loanId;
  final String? paymentId;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    required this.method,
    this.loanId,
    this.paymentId,
  });
}



