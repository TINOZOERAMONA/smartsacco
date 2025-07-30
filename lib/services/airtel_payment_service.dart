import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AirtelPaymentService {
  static const String _baseUrl = 'https://openapi.airtel.africa';
  static const String _clientId = 'YOUR_CLIENT_ID';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  
  Future<String> _getAccessToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/oauth2/token'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
      body: jsonEncode({
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'client_credentials',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access_token'];
    } else {
      throw Exception('Failed to get access token: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String amount,
    required String phoneNumber,
    required String transactionId,
    required String callbackUrl,
  }) async {
    final accessToken = await _getAccessToken();
    final reference = const Uuid().v4();

    final response = await http.post(
      Uri.parse('$_baseUrl/merchant/v1/payments/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'X-Country': 'KE', // Change based on your country
        'X-Currency': 'KES', // Change based on your currency
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'reference': reference,
        'transaction': {
          'amount': amount,
          'country': 'KE',
          'currency': 'KES',
          'id': transactionId,
        },
        'subscriber': {
          'country': 'KE',
          'currency': 'KES',
          'msisdn': phoneNumber,
        },
        'callback_url': callbackUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to initiate payment: ${response.body}');
    }
  }
}