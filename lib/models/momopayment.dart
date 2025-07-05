import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartloan_sacco/services/momo_services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';


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

      final momoService = MomoService(); // Configured with your credentials
      
      await momoService.requestPayment(
        phoneNumber: _phoneController.text,
        amount: widget.amount,
        externalId: transactionId,
        payerMessage: 'SACCO Contribution: UGX ${widget.amount.toStringAsFixed(2)}',
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




