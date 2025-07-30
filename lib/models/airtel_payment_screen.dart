import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:smartsacco/services/airtel_payment_service.dart';


class AirtelPaymentScreen extends StatefulWidget {
  final String amount;
  final String phoneNumber;

  const AirtelPaymentScreen({
    Key? key,
    required this.amount,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _AirtelPaymentScreenState createState() => _AirtelPaymentScreenState();
}

class _AirtelPaymentScreenState extends State<AirtelPaymentScreen> {
  final AirtelPaymentService _paymentService = AirtelPaymentService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final transactionId = 'sacco_${DateTime.now().millisecondsSinceEpoch}';
      final callbackUrl = 'your-app-scheme://callback'; // Replace with your app's callback URL scheme

      final response = await _paymentService.initiatePayment(
        amount: widget.amount,
        phoneNumber: widget.phoneNumber,
        transactionId: transactionId,
        callbackUrl: callbackUrl,
      );

      if (response.containsKey('data') && response['data'].containsKey('transaction')) {
        final transaction = response['data']['transaction'];
        if (transaction['status'] == 'PENDING') {
          final authUrl = transaction['redirect_url'];
          
          // Open web auth for payment completion
          final result = await FlutterWebAuth2.authenticate(
            url: authUrl,
            callbackUrlScheme: 'your-app-scheme', // Same as above
          );

          // Handle the callback result
          final uri = Uri.parse(result);
          if (uri.queryParameters['status'] == 'SUCCESS') {
            setState(() {
              _successMessage = 'Payment successful!';
            });
          } else {
            setState(() {
              _errorMessage = 'Payment failed or was cancelled';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing payment: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Airtel Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pay KES ${widget.amount}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Phone: ${widget.phoneNumber}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _initiatePayment,
                child: const Text('Pay with Airtel Money'),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}