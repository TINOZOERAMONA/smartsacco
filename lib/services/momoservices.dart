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

    if (response.statusCode == 202) {
      return {'status': 'pending', 'transactionId': externalId};
    } else {
      throw Exception('Payment failed: ${response.body}');
    }
  }

  Map<String, dynamic> _requestBody({
    required String phoneNumber,
    required double amount,
    required String externalId,
  }) => {
    'amount': amount.toStringAsFixed(2),
    'currency': 'UGX',
    'externalId': externalId,
    'payer': {
      'partyIdType': 'MSISDN',
      'partyId': _formatPhoneNumber(phoneNumber),
    },
    'payerMessage': 'SACCO Payment',
    'payeeNote': 'Thank you for your contribution',
  };

  Future<Map<String, String>> _headers(String externalId) async => {
    'Authorization': 'Bearer ${await _getToken()}',
    'X-Target-Environment': _isSandbox ? 'sandbox' : 'production',
    'Content-Type': 'application/json',
    'Ocp-Apim-Subscription-Key': _subscriptionKey,
    'X-Reference-Id': externalId,
    'X-Callback-Url': _callbackUrl,
  };

  Future<String> _getToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/collection/token/'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiUser:$_apiKey'))}',
        'Ocp-Apim-Subscription-Key': _subscriptionKey,
      },
    );
    return jsonDecode(response.body)['access_token'];
  }

  String get _baseUrl => _isSandbox 
    ? 'https://sandbox.momodeveloper.mtn.com' 
    : 'https://api.mtn.com/v1';

  String _formatPhoneNumber(String number) {
    final cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) return '256${cleaned.substring(1)}';
    if (cleaned.startsWith('7')) return '256$cleaned';
    return cleaned;
  }

  String _generateTransactionId() => 
    'SACCO${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(900) + 100}';
}

