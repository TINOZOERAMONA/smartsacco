
// ignore_for_file: depend_on_referenced_packages

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';


//A model class representing a deposit transaction
class Deposit {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String status;
  final String reference;
  final String? phoneNumber;
  final String? transactionId;

/// Constructor for creating a Deposit instance
 Deposit({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    required this.status,
    required this.reference,
    this.phoneNumber,
    this.transactionId,
  });
 

  /// Factory constructor to create Deposit from JSON data
  /// Used when parsing API responses or database records
  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      method: json['method'],
      status: json['status'],
      reference: json['reference'],
      phoneNumber: json['phoneNumber'],
      transactionId: json['transactionId'],
    );
  }

  /// Converts Deposit object to JSON format
  /// Useful for API requests or database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'status': status,
      'reference': reference,
      'phoneNumber': phoneNumber,
      'transactionId': transactionId,
    };
  }


  /// Formats the transaction date for display
  /// Returns string in format like "Jan 1, 2023 02:30 PM"
  String getFormattedDate() {
    return DateFormat('MMM d, y hh:mm a').format(date);
  }

  /// Formats the amount for display with currency
  /// Returns string like "UGX 10,000.00"
  String getAmountText() {
    return 'UGX ${NumberFormat('#,##0.00').format(amount)}';
  }
/// Returns a color based on transaction status
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}