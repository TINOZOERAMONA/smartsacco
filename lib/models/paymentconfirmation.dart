import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentConfirmationPage extends StatelessWidget {
  final Map<String, dynamic> paymentDetails;
  
  const PaymentConfirmationPage({
    super.key,
    required this.paymentDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = paymentDetails['status'] == 'success';
    final amount = paymentDetails['amount'] ?? 0.0;
    final transactionId = paymentDetails['transactionId'] ?? 'N/A';
    final phone = paymentDetails['phone'] ?? 'N/A';
    final method = paymentDetails['method'] ?? 'Mobile Money';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),