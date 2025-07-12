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

class MobilePaymentBackend implements PaymentBackend {
  @override
  Future<void> saveTransaction(String transactionId) async {
    final file = await _transactionFile;
    await file.writeAsString(jsonEncode({
      'transactionId': transactionId,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  @override
  Future<bool> checkTransactionStatus(String transactionId) async {
    final file = await _transactionFile;
    if (await file.exists()) {
      final data = jsonDecode(await file.readAsString());
      return data['transactionId'] == transactionId && 
             data['status'] == 'success';
    }
    return false;
  }

  @override
  Future<void> clearTransaction(String transactionId) async {
    final file = await _transactionFile;
    if (await file.exists()) await file.delete();
  }

  Future<File> get _transactionFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/momo_transaction.json');
  }
}

class WebPaymentBackend implements PaymentBackend {
  @override
  Future<void> saveTransaction(String transactionId) async {
    web.window.localStorage['momo_transaction'] = jsonEncode({
      'transactionId': transactionId,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<bool> checkTransactionStatus(String transactionId) async {
    final data = web.window.localStorage['momo_transaction'];
    if (data != null) {
      final json = jsonDecode(data);
      return json['transactionId'] == transactionId && 
             json['status'] == 'success';
    }
    return false;
  }

  @override
  Future<void> clearTransaction(String transactionId) async {
    web.window.localStorage.remove('momo_transaction');
  }
}

PaymentBackend getPaymentBackend() {
  return kIsWeb ? WebPaymentBackend() : MobilePaymentBackend();
}