import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as web;

abstract class PaymentBackend {
  Future<void> saveTransaction(String transactionId);
  Future<bool> checkTransactionStatus(String transactionId);
  Future<void> clearTransaction(String transactionId);
}