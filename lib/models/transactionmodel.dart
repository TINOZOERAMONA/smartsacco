import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String type; // Deposit, Withdrawal, Loan Payment
  final String status; // Pending, Completed, Failed
  final String method; // Mobile Money, Bank Transfer
  final String? reference;
  final String? phoneNumber;
  final String? loanId;         // optional
  final String? paymentId; 

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    required this.method,
    this.reference,
    this.phoneNumber,
    this.loanId,
    this.paymentId,
  });

  String getFormattedDate() => DateFormat('MMM d, y').format(date);
  String getAmountText() => NumberFormat.currency(symbol: 'UGX ').format(amount);

  // Add this to TransactionModel.dart
static Transaction createDeposit({
  required String id,
  required double amount,
  required String method,
  String? reference,
  String? phoneNumber,
}) {
  return Transaction(
    id: id,
    amount: amount,
    date: DateTime.now(),
    type: 'Deposit',
    status: 'Completed',
    method: method,
    reference: reference,
    phoneNumber: phoneNumber,
  );
}

  Color getStatusColor() {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

   factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      type: json['type'] ?? 'Transaction',
      status: json['status'] ?? 'Completed',
      method: json['method'] ?? 'Mobile Money',
      reference: json['reference'],
      phoneNumber: json['phoneNumber'],
      loanId: json['loanId'] as String?,
      paymentId: json['paymentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type,
    'status': status,
    'method': method,
    'reference': reference,
    'phoneNumber': phoneNumber,
    'loanId': loanId,
    'paymentId': paymentId,
  };
}






