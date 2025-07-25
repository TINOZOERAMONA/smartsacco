

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
    final isSuccess = paymentDetails['status'] == 'SUCCESSFUL';
    final amount = double.parse(paymentDetails['data']['amount'] ?? 0.0);
    final transactionId = paymentDetails['financialTransactionId'] ?? 'N/A';
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
            const SizedBox(height: 16),
            Text(
              isSuccess 
                  ? 'Your deposit has been initiated successfully'
                  : 'There was an error processing your payment',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow('Amount:', 'UGX ${NumberFormat('#,##0.00').format(amount)}'),
                    _buildDetailRow('Method:', method),
                    _buildDetailRow('Transaction ID:', transactionId),
                    if (phone != 'N/A') _buildDetailRow('Phone:', phone),
                    _buildDetailRow('Date:', DateFormat('MMM d, y hh:mm a').format(DateTime.now())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}



