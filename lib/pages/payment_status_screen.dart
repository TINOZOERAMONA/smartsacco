import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smartsacco/services/payment_tracking_service.dart';
import 'package:intl/intl.dart';

class PaymentStatusScreen extends StatefulWidget {
  final String transactionId;
  final double amount;
  final String method;
  final String type;

  const PaymentStatusScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.method,
    required this.type,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  final PaymentTrackingService _trackingService = PaymentTrackingService();
  final FlutterTts _flutterTts = FlutterTts();

  Map<String, dynamic>? _currentStatus;
  bool _isLoading = true;
  bool _isRetrying = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _startTracking();
    _speakInitialStatus();
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
  }

  void _startTracking() {
    _trackingService
        .trackPaymentStatus(widget.transactionId)
        .listen(
          (status) {
            setState(() {
              _currentStatus = status;
              _isLoading = false;
            });

            _speakStatusUpdate(status);
          },
          onError: (error) {
            setState(() {
              _isLoading = false;
            });
            _speak("Error tracking payment status. Please try again.");
          },
        );
  }

  Future<void> _speakInitialStatus() async {
    await _speak(
      "Tracking payment of ${_formatCurrency(widget.amount)} via ${widget.method}. "
      "Please wait while we check the status.",
    );
  }

  Future<void> _speakStatusUpdate(Map<String, dynamic> status) async {
    final statusText = status['status'] ?? 'unknown';
    String message = '';

    switch (statusText) {
      case 'completed':
        message =
            "Payment completed successfully! Your ${widget.type} of ${_formatCurrency(widget.amount)} has been processed.";
        break;
      case 'processing':
        message = "Payment is being processed. Please wait.";
        break;
      case 'failed':
        final error = status['error'] ?? 'Unknown error';
        message = "Payment failed. Error: $error. You can retry the payment.";
        break;
      case 'pending':
        message = "Payment is pending. Please check your mobile money app.";
        break;
      case 'timeout':
        message =
            "Payment status check timed out. Please check your mobile money app or contact support.";
        break;
      default:
        message = "Payment status: $statusText";
    }

    await _speak(message);
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _retryPayment() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      // Get user's phone number from Firestore or show dialog
      final phoneNumber = await _showPhoneNumberDialog();

      if (phoneNumber != null) {
        final result = await _trackingService.retryPayment(
          transactionId: widget.transactionId,
          phoneNumber: phoneNumber,
        );

        if (result['success']) {
          setState(() {
            _retryCount++;
            _isRetrying = false;
          });

          await _speak(
            "Payment retry initiated. Please check your mobile money app.",
          );

          // Restart tracking
          _startTracking();
        } else {
          setState(() {
            _isRetrying = false;
          });

          await _speak("Failed to retry payment. Please try again.");
        }
      } else {
        setState(() {
          _isRetrying = false;
        });
      }
    } catch (e) {
      setState(() {
        _isRetrying = false;
      });

      await _speak("Error retrying payment. Please try again.");
    }
  }

  Future<String?> _showPhoneNumberDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter the phone number for payment retry:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'e.g., 256700000000',
                prefixText: '+',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelPayment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: const Text('Are you sure you want to cancel this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _trackingService.cancelPayment(widget.transactionId);

      if (result['success']) {
        await _speak("Payment cancelled successfully.");
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        await _speak("Failed to cancel payment. Please try again.");
      }
    }
  }

  Widget _buildStatusCard() {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Checking payment status...'),
              const SizedBox(height: 8),
              Text(
                'Transaction ID: ${widget.transactionId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final status = _currentStatus?['status'] ?? 'unknown';
    final error = _currentStatus?['error'];
    final date = _currentStatus?['date'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Payment Completed';
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Processing Payment';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Payment Pending';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Payment Failed';
        break;
      case 'timeout':
        statusColor = Colors.grey;
        statusIcon = Icons.timer_off;
        statusText = 'Status Check Timeout';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown Status';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(statusIcon, size: 64, color: statusColor),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentDetails(),
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error Details:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(error),
                  ],
                ),
              ),
            ],
            if (date != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last Updated: ${DateFormat.yMMMd().add_jm().format(date.toDate())}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow('Amount', _formatCurrency(widget.amount)),
          _buildDetailRow('Type', widget.type.toUpperCase()),
          _buildDetailRow('Method', widget.method),
          _buildDetailRow('Transaction ID', widget.transactionId),
          if (_retryCount > 0)
            _buildDetailRow('Retry Count', _retryCount.toString()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _currentStatus?['status'] ?? 'unknown';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (status == 'failed' || status == 'timeout') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isRetrying ? null : _retryPayment,
              icon: _isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (status == 'pending' || status == 'processing') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _cancelPayment,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        backgroundColor: const Color(0xFF007C91),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    if (_currentStatus != null) ...[
                      const Text(
                        'Payment is being tracked in real-time',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You will be notified when the status changes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
