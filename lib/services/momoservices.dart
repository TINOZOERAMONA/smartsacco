import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MomoService {
  // Configuration
  static const _configFile = 'assets/config.json';
  late final String _subscriptionKey;
  late final String _apiUser;
  late final String _apiKey;
  late final bool _isSandbox;
  late final String _callbackUrl;

  MomoService() {
    _loadConfig();
  }
  Future<void> _loadConfig() async {
    final config = jsonDecode(await rootBundle.loadString(_configFile));
    _subscriptionKey = config['subscriptionKey'];
    _apiUser = config['apiUser'];
    _apiKey = config['apiKey'];
    _isSandbox = config['isSandbox'];
    _callbackUrl = config['callbackUrl'];
  }

  Future<Map<String, dynamic>> requestPayment({
    required String phoneNumber,
    required double amount,
  }) async {
    final externalId = _generateTransactionId();
    final url = Uri.parse('$_baseUrl/collection/v1_0/requesttopay');

    final response = await http.post(
      url,
      headers: await _headers(externalId),
      body: jsonEncode(_requestBody(
        phoneNumber: phoneNumber,
        amount: amount,
        externalId: externalId,
      )),
    );

