

// class Deposit {
//   final String id;
//   final double amount;
//   final DateTime date;
//   final String method;
//   final String status;
//   final String reference;

//     Deposit({
//     required this.id,
//     required this.amount,
//     required this.date,
//     required this.method,
//     required this.status,
//     required this.reference,
//   });

//   factory Deposit.fromJson(Map<String, dynamic> json) {
//     return Deposit(
//       id: json['id'],
//       amount: json['amount'].toDouble(),
//       date: DateTime.parse(json['date']),
//       method: json['method'],
//       status: json['status'],
//       reference: json['reference'],
//     );
// }
// }

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Deposit {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String status;
  final String reference;
  final String? phoneNumber;
  final String? transactionId;

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

  String getFormattedDate() {
    return DateFormat('MMM d, y hh:mm a').format(date);
  }

  String getAmountText() {
    return 'UGX ${NumberFormat('#,##0.00').format(amount)}';
  }

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