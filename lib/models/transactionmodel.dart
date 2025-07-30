import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//represents financial transaction in the sacco system
class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String type; // Deposit, Withdrawal, Loan Payment
  final String status; // Pending, Completed, Failed
  final String method; // Mobile Money, Bank Transfer
  final String? reference;
  final String? phoneNumber;

// Creates a new transaction record
  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.status,
    required this.method,
    this.reference,
    this.phoneNumber,
  });

// Formats the transaction date as "Jan 1, 2024"
  String getFormattedDate() => DateFormat('MMM d, y').format(date);
  // Formats the amount with currency symbol (e.g., "UGX 50,000")
  String getAmountText() => NumberFormat.currency(symbol: 'UGX ').format(amount);

// Returns a color based on transaction status:
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

 // Creates a Transaction from JSON data (API response)
  // Throws FormatException if date parsing fails
   factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      type: json['type'],
      status: json['status'],
      method: json['method'],
      reference: json['reference'],
      phoneNumber: json['phoneNumber'],
    );
  }

// Converts the transaction to JSON format (for API requests)
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'type': type,
    'status': status,
    'method': method,
    'reference': reference,
    'phoneNumber': phoneNumber,
  };
}






