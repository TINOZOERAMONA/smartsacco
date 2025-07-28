

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartsacco/services/momoservices.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
const bool isSandbox = true;
const String callbackUrl =
    'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

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

class _MomoPaymentPageState extends State<MomoPaymentPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // MTN Brand Colors
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color mtnBlue = Color(0xFF003DA5);
  static const Color mtnDarkBlue = Color(0xFF002B73);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();

    if (kDebugMode) {
      _phoneController.text = '775123456'; // Test UG number for sandbox
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pollingTimer?.cancel();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      final transactionId = MomoService.generateTransactionId();

      // Clear previous callback data
      if (kIsWeb) {
        await _clearMomoCallback();
      } else {
        await _clearCallbackFile();
      }

      final momoService = MomoService(); // Configured with your credentials

      final payementData = await momoService.requestPayment(
        phoneNumber: _phoneController.text,
        amount: widget.amount,
        externalId: transactionId,
        payerMessage:
            'SACCO Contribution: UGX ${widget.amount.toStringAsFixed(2)}',
      );
      // String d = 2.toString();
      // Start polling for payment confirmation
      _startPolling(
        payementData['referenceId'],
        // payementData['authorization'],
        payementData['externalId'],
        momoService,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _pulseController.stop();
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
    // return File('momo_callback.json');
  }

  // Future<void> _saveMomoCallback(Map<String, dynamic> data) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   prefs.setString('momo_callback', jsonEncode(data));
  // }

  Future<void> _clearMomoCallback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('momo_callback');
  }

  void _startPolling(
    String referenceId,
    // String authorization,
    String externalId,
    MomoService momoService,
  ) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // late File file;
      // late Map<String, dynamic>? data;
      // if (!kIsWeb) {
      //   file = await _getCallbackFile();
      // }

      // if (kIsWeb || await file.exists()) {
      // if (kIsWeb) {
      //   // data = await _loadMomoCallback();
      //   data = null;
      // } else {
      //   data = jsonDecode(await file.readAsString());
      // }
      final data = await momoService.checkTransactionStatus(externalId, referenceId);

      if (data['externalId'] == externalId) {
        timer.cancel();
        _pulseController.stop();

        if (mounted) {
          setState(() => _isLoading = false);
          widget.onPaymentComplete(data['status'] == 'SUCCESSFUL');

          Navigator.pushNamed(
            context,
            '/payment-confirmation',
            // arguments: {
            //   'success': data['status'] == 'SUCCESSFUL',
            //   'amount': widget.amount,
            //   'transactionId': referenceId,
            // },
            arguments: data,
          );
        }
      }
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isMediumScreen = screenWidth >= 400 && screenWidth < 600;
    
    // Responsive sizing
    final logoSize = isSmallScreen ? 80.0 : isMediumScreen ? 100.0 : 120.0;
    final titleFontSize = isSmallScreen ? 22.0 : isMediumScreen ? 25.0 : 28.0;
    final amountFontSize = isSmallScreen ? 24.0 : isMediumScreen ? 28.0 : 32.0;
    final horizontalPadding = isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: mtnYellow,
        foregroundColor: mtnDarkBlue,
        title: Text(
          'Mobile Money Payment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header Section with MTN Branding
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [mtnYellow, mtnYellow.withOpacity(0.8)],
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              // MTN Logo
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isLoading ? _pulseAnimation.value : 1.0,
                                    child: Container(
                                      width: logoSize,
                                      height: logoSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(logoSize / 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(logoSize / 2),
                                        child: Image.network(
                                          'https://seeklogo.com/images/M/mtn-logo-9F1D0D98E1-seeklogo.com.pngr',
                                          fit: BoxFit.contain,
                                          width: logoSize * 0.7,
                                          height: logoSize * 0.7,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: mtnBlue,
                                                borderRadius: BorderRadius.circular(logoSize / 2),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'MTN',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: logoSize * 0.2,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Text(
                                'MTN Mobile Money',
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: mtnDarkBlue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Secure • Fast • Reliable',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: mtnDarkBlue.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 20 : 30),
                            ],
                          ),
                        ),
                      ),

                      // Payment Form Section
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(horizontalPadding),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Amount Card
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [mtnBlue, mtnDarkBlue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: mtnBlue.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Payment Amount',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'UGX ${widget.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: amountFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Phone Number Input
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'MTN Mobile Money Number',
                                      labelStyle: TextStyle(
                                        color: mtnBlue,
                                        fontWeight: FontWeight.w500,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      prefixText: '+256 ',
                                      prefixStyle: TextStyle(
                                        color: mtnDarkBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 14 : 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: mtnYellow, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: '775123456',
                                      hintStyle: TextStyle(color: Colors.grey[400]),
                                      prefixIcon: Container(
                                        padding: const EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.phone_android,
                                          color: mtnBlue,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 12 : 16,
                                        vertical: isSmallScreen ? 16 : 20,
                                      ),
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
                                ),
                                SizedBox(height: isSmallScreen ? 20 : 24),

                                // Error Message
                                if (_errorMessage != null)
                                  Container(
                                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red[600],
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: isSmallScreen ? 13 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const Spacer(),

                                // Payment Button
                                Container(
                                  height: isSmallScreen ? 48 : 56,
                                  decoration: BoxDecoration(
                                    gradient: _isLoading 
                                        ? null 
                                        : LinearGradient(
                                            colors: [mtnYellow, mtnYellow.withOpacity(0.8)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: _isLoading 
                                        ? null 
                                        : [
                                            BoxShadow(
                                              color: mtnYellow.withOpacity(0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _processPayment,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isLoading ? Colors.grey[400] : Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: isSmallScreen ? 20 : 24,
                                                height: isSmallScreen ? 20 : 24,
                                                child: const CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Processing Payment...',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.payment,
                                                color: mtnDarkBlue,
                                                size: isSmallScreen ? 20 : 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Pay with Mobile Money',
                                                style: TextStyle(
                                                  fontSize: isSmallScreen ? 14 : 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: mtnDarkBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),

                                // Instruction Text
                                Container(
                                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue[600],
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'You will receive a Mobile Money prompt on your phone to confirm the payment',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: isSmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}