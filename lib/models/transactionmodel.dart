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
