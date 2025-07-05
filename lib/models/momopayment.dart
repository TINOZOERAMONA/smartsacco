import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartsacco/services/momoservices.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
const bool isSandbox = true;
const String callbackUrl = '	https://webhook.site/93611f81-f8f2-465e-b186-749a9b36bc59'; // Set to false for production


class MomoPaymentPage extends StatefulWidget {
  final double amount;
  final Function(bool success) onPaymentComplete;

  const MomoPaymentPage({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
  });

  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

class _MomoPaymentPageState extends State<MomoPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _phoneController.text = '775123456'; // Test UG number for sandbox
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionId = MomoService.generateTransactionId();

      // Clear previous callback data
      await _clearCallbackFile();

      final momoService = MomoService(
        subscriptionKey: subscriptionKey,
        apiUser: apiUser,
        apiKey: apiKey,
        isSandbox: isSandbox,
        callbackUrl: callbackUrl,
      ); // Configured with your credentials

      await momoService.requestPayment(
        phoneNumber: _phoneController.text,
        amount: widget.amount,
        externalId: transactionId,
        payerMessage:
            'SACCO Contribution: UGX ${widget.amount.toStringAsFixed(2)}',
      );
      // Start polling for payment confirmation
      _startPolling(transactionId);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCallbackFile() async {
    final file = await _getCallbackFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _getCallbackFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/momo_callback.json');
  }

  void _startPolling(String transactionId) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final file = await _getCallbackFile();

      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());

        if (data['transactionId'] == transactionId) {
          timer.cancel();

          if (mounted) {
            setState(() => _isLoading = false);
            widget.onPaymentComplete(data['status'] == 'SUCCESSFUL');

            Navigator.pushNamed(
              context,
              '/payment-confirmation',
              arguments: {
                'success': data['status'] == 'SUCCESSFUL',
                'amount': widget.amount,
                'transactionId': transactionId,
              },
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTN Mobile Money Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Payment Amount Display
              Text(
                'Pay UGX ${widget.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'MTN Mobile Money Number',
                  prefixText: '+256 ',
                  border: OutlineInputBorder(),
                  hintText: '775123456',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (!RegExp(r'^(0|7)\d{8}$').hasMatch(cleaned)) {
                    return 'Enter a valid Uganda number (e.g. 775123456)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

              const Spacer(),

              // Payment Button
              ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Pay with Mobile Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Instruction Text
              Text(
                'You will receive a Mobile Money prompt on your phone to confirm the payment',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
