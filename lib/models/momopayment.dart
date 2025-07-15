// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:smartsacco/services/momoservices.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart';

// const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
// const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
// const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
// const bool isSandbox = true;
// const String callbackUrl =
//     'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

// class MomoPaymentPage extends StatefulWidget {
//   final double amount;
//   final Function(bool success) onPaymentComplete;

//   const MomoPaymentPage({
//     super.key,
//     required this.amount,
//     required this.onPaymentComplete,
//   });

//   @override
//   State<MomoPaymentPage> createState() => _MomoPaymentPageState();
// }

// class _MomoPaymentPageState extends State<MomoPaymentPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   final _nameController = TextEditingController();
//   final _amountController = TextEditingController();
//   bool _isLoading = false;
//   String? _errorMessage;
//   Timer? _pollingTimer;
//   bool _isDeposit = true; // true for deposit, false for withdrawal
//   bool _showConfirmation = false;

//   @override
//   void initState() {
//     super.initState();
//     _amountController.text = widget.amount.toStringAsFixed(2);
//     if (kDebugMode) {
//       _phoneController.text = '775123456'; // Test UG number for sandbox
//       _nameController.text = 'John Doe';
//     }
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _nameController.dispose();
//     _amountController.dispose();
//     _pollingTimer?.cancel();
//     super.dispose();
//   }

//   // Keep your existing deposit payment method intact
//   Future<void> _processPayment() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final transactionId = MomoService.generateTransactionId();

//       // Clear previous callback data
//       if (kIsWeb) {
//         await _clearMomoCallback();
//       } else {
//         await _clearCallbackFile();
//       }

//       final momoService = MomoService(
//         subscriptionKey: subscriptionKey,
//         apiUser: apiUser,
//         apiKey: apiKey,
//         isSandbox: isSandbox,
//         callbackUrl: callbackUrl,
//       );

//       final amount = double.parse(_amountController.text);
      
//       if (_isDeposit) {
//         // Your existing deposit logic - unchanged
//         final payementData = await momoService.requestPayment(
//           phoneNumber: _phoneController.text,
//           amount: amount,
//           externalId: transactionId,
//           payerMessage: 'SACCO Contribution: UGX ${amount.toStringAsFixed(2)}',
//         );
        
//         // Start polling for payment confirmation
//         _startPolling(
//           payementData['referenceId'],
//           payementData['authorization'],
//           payementData['externalId'],
//           momoService,
//         );
//       } else {
//         // Withdrawal logic using sandbox - simulate real withdrawal behavior
//         // In sandbox, we use the same requestPayment method but with withdrawal message
//         // This simulates the disbursement API behavior
//         final withdrawalData = await momoService.requestPayment(
//           phoneNumber: _phoneController.text,
//           amount: amount,
//           externalId: transactionId,
//           payerMessage: 'SACCO Withdrawal: UGX ${amount.toStringAsFixed(2)}',
//         );
        
//         // Start polling for withdrawal confirmation
//         _startPolling(
//           withdrawalData['referenceId'],
//           withdrawalData['authorization'],
//           withdrawalData['externalId'],
//           momoService,
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _clearCallbackFile() async {
//     final file = await _getCallbackFile();
//     if (await file.exists()) {
//       await file.delete();
//     }
//   }

//   Future<File> _getCallbackFile() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/momo_callback.json');
//   }

//   Future<Map<String, dynamic>?> _loadMomoCallback() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = prefs.getString('momo_callback');
//     if (jsonString == null) return null;
//     return jsonDecode(jsonString);
//   }

//   Future<void> _clearMomoCallback() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('momo_callback');
//   }

//   // Keep your existing polling method intact
//   void _startPolling(
//     String referenceId,
//     String authorization,
//     String externalId,
//     MomoService momoService,
//   ) {
//     _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
//       final data = await momoService.transactionStatus(
//         referenceId: referenceId,
//         authorization: authorization,
//       );

//       if (data['externalId'] == externalId) {
//         timer.cancel();

//         if (mounted) {
//           setState(() => _isLoading = false);
//           widget.onPaymentComplete(data['status'] == 'SUCCESSFUL');

//           Navigator.pushNamed(
//             context,
//             '/payment-confirmation',
//             arguments: {
//               'success': data['status'] == 'SUCCESSFUL',
//               'amount': double.parse(_amountController.text),
//               'transactionId': referenceId,
//             },
//           );
//         }
//       }
//     });
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 color: Colors.grey,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConfirmationScreen() {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFFCC00),
//         title: const Text(
//           'Confirm Transaction',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => setState(() => _showConfirmation = false),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Confirmation Card
//             Card(
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Image.network(
//                           'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/MTN_Logo.svg/2560px-MTN_Logo.svg.png',
//                           width: 40,
//                           height: 40,
//                           errorBuilder: (context, error, stackTrace) => 
//                             const Icon(Icons.mobile_friendly, size: 40, color: Color(0xFFFFCC00)),
//                         ),
//                         const SizedBox(width: 12),
//                         const Text(
//                           'MTN Mobile Money',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFFFFCC00),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 20),
                    
//                     _buildDetailRow('Transaction Type', _isDeposit ? 'Deposit' : 'Withdrawal'),
//                     _buildDetailRow('Full Name', _nameController.text),
//                     _buildDetailRow('Phone Number', '+256 ${_phoneController.text}'),
//                     _buildDetailRow('Amount', 'UGX ${double.parse(_amountController.text).toStringAsFixed(2)}'),
                    
//                     const SizedBox(height: 20),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: _isDeposit ? Colors.green.shade50 : Colors.orange.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(
//                           color: _isDeposit ? Colors.green : Colors.orange,
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             _isDeposit ? Icons.account_balance_wallet : Icons.money,
//                             color: _isDeposit ? Colors.green : Colors.orange,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               _isDeposit 
//                                 ? 'You are about to make a deposit to your SACCO account'
//                                 : 'You are about to withdraw from your SACCO account',
//                               style: TextStyle(
//                                 color: _isDeposit ? Colors.green.shade700 : Colors.orange.shade700,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
            
//             const Spacer(),
            
//             // Action Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: _isLoading ? null : () => setState(() => _showConfirmation = false),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       side: const BorderSide(color: Color(0xFFFFCC00)),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: const Text(
//                       'Edit Details',
//                       style: TextStyle(
//                         color: Color(0xFFFFCC00),
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : _processPayment,
//                     style: ElevatedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       backgroundColor: const Color(0xFFFFCC00),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               color: Colors.black,
//                               strokeWidth: 3,
//                             ),
//                           )
//                         : Text(
//                             'Confirm ${_isDeposit ? 'Deposit' : 'Withdrawal'}',
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
            
//             const SizedBox(height: 16),
            
//             // Instruction Text
//             Text(
//               'You will receive a Mobile Money prompt on your phone to confirm the ${_isDeposit ? 'payment' : 'withdrawal'}',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_showConfirmation) {
//       return _buildConfirmationScreen();
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFFCC00),
//         title: const Text(
//           'MTN Mobile Money',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: _isLoading ? null : () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // MTN Logo and Header
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFFFFCC00), Color(0xFFFFF700)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       Image.network(
//                         'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/MTN_Logo.svg/2560px-MTN_Logo.svg.png',
//                         width: 80,
//                         height: 80,
//                         errorBuilder: (context, error, stackTrace) => 
//                           const Icon(Icons.mobile_friendly, size: 80, color: Colors.black),
//                       ),
//                       const SizedBox(height: 12),
//                       const Text(
//                         'MTN Mobile Money',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'Fast • Secure • Convenient',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 20),
              
//               // Transaction Type Toggle
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Transaction Type',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () => setState(() => _isDeposit = true),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 decoration: BoxDecoration(
//                                   color: _isDeposit ? const Color(0xFFFFCC00) : Colors.grey.shade200,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: _isDeposit ? const Color(0xFFFFCC00) : Colors.grey.shade300,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.account_balance_wallet,
//                                       color: _isDeposit ? Colors.black : Colors.grey.shade600,
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       'Deposit',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: _isDeposit ? Colors.black : Colors.grey.shade600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () => setState(() => _isDeposit = false),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 decoration: BoxDecoration(
//                                   color: !_isDeposit ? const Color(0xFFFFCC00) : Colors.grey.shade200,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: !_isDeposit ? const Color(0xFFFFCC00) : Colors.grey.shade300,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.money,
//                                       color: !_isDeposit ? Colors.black : Colors.grey.shade600,
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Text(
//                                       'Withdraw',
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: !_isDeposit ? Colors.black : Colors.grey.shade600,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 20),
              
//               // Form Card
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           '${_isDeposit ? 'Deposit' : 'Withdraw'} Details',
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
                        
//                         // Full Name Input
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: InputDecoration(
//                             labelText: 'Full Name',
//                             prefixIcon: const Icon(Icons.person, color: Color(0xFFFFCC00)),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your full name';
//                             }
//                             if (value.length < 2) {
//                               return 'Name must be at least 2 characters';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 16),
                        
//                         // Phone Number Input
//                         TextFormField(
//                           controller: _phoneController,
//                           keyboardType: TextInputType.phone,
//                           decoration: InputDecoration(
//                             labelText: 'MTN Mobile Money Number',
//                             prefixText: '+256 ',
//                             prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFCC00)),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2),
//                             ),
//                             hintText: '775123456',
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your phone number';
//                             }
//                             final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
//                             if (!RegExp(r'^(0|7)\d{8}$').hasMatch(cleaned)) {
//                               return 'Enter a valid Uganda number (e.g. 775123456)';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 16),
                        
//                         // Amount Input
//                         TextFormField(
//                           controller: _amountController,
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: 'Amount (UGX)',
//                             prefixIcon: const Icon(Icons.money, color: Color(0xFFFFCC00)),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2),
//                             ),
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter amount';
//                             }
//                             final amount = double.tryParse(value);
//                             if (amount == null || amount <= 0) {
//                               return 'Please enter a valid amount';
//                             }
//                             if (amount < 500) {
//                               return 'Minimum amount is UGX 500';
//                             }
//                             return null;
//                           },
//                         ),
                        
//                         const SizedBox(height: 20),
                        
//                         // Error Message
//                         if (_errorMessage != null)
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.red.shade50,
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.red.shade300),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(Icons.error, color: Colors.red.shade600),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     _errorMessage!,
//                                     style: TextStyle(
//                                       color: Colors.red.shade600,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
                        
//                         const SizedBox(height: 20),
                        
//                         // Continue Button
//                         SizedBox(
//                           width: double.infinity,
//                           child: ElevatedButton(
//                             onPressed: _isLoading ? null : () {
//                               if (_formKey.currentState!.validate()) {
//                                 setState(() => _showConfirmation = true);
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(vertical: 16),
//                               backgroundColor: const Color(0xFFFFCC00),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: Text(
//                               'Continue to Confirm',
//                               style: const TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
              
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartsacco/services/momoservices.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// Configuration constants
const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
const bool isSandbox = true;
const String callbackUrl = 'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

class MomoPaymentPage extends StatefulWidget {
  final double amount;
  final Function(bool success) onPaymentComplete;
  final Map<String, dynamic>? userProfile;

  const MomoPaymentPage({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
    this.userProfile,
  });

  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

class _MomoPaymentPageState extends State<MomoPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  bool _isDeposit = true;
  bool _showConfirmation = false;
  bool _isVerifying = false;
  String? _verificationError;
  bool _autoFilled = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amount.toStringAsFixed(2);
    _loadUserProfile();
    
    if (kDebugMode) {
      _phoneController.text = '775123456';
      _nameController.text = 'John Doe';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _loadUserProfile() {
    if (widget.userProfile != null) {
      setState(() {
        _nameController.text = widget.userProfile!['fullName'] ?? '';
        _phoneController.text = widget.userProfile!['phoneNumber'] ?? '';
        _autoFilled = true;
      });
    }
  }

  Future<bool> _verifyUserDetails() async {
    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (widget.userProfile != null) {
        final profilePhone = widget.userProfile!['phoneNumber']?.toString() ?? '';
        final inputPhone = _phoneController.text.trim();
        
        if (profilePhone.isNotEmpty && !_phoneNumbersMatch(profilePhone, inputPhone)) {
          setState(() {
            _verificationError = 'Phone number does not match your profile';
            _isVerifying = false;
          });
          return false;
        }
        
        final profileName = widget.userProfile!['fullName']?.toString() ?? '';
        final inputName = _nameController.text.trim();
        
        if (profileName.isNotEmpty && !_namesMatch(profileName, inputName)) {
          setState(() {
            _verificationError = 'Name does not match your profile';
            _isVerifying = false;
          });
          return false;
        }
      }
      
      setState(() => _isVerifying = false);
      return true;
    } catch (e) {
      setState(() {
        _verificationError = 'Verification failed: ${e.toString()}';
        _isVerifying = false;
      });
      return false;
    }
  }

  bool _phoneNumbersMatch(String profile, String input) {
    final profileClean = profile.replaceAll(RegExp(r'[^0-9]'), '');
    final inputClean = input.replaceAll(RegExp(r'[^0-9]'), '');
    return profileClean.length >= 9 && inputClean.length >= 9 &&
           profileClean.substring(profileClean.length - 9) == 
           inputClean.substring(inputClean.length - 9);
  }

  bool _namesMatch(String profile, String input) {
    return profile.toLowerCase().trim() == input.toLowerCase().trim();
  }

  Future<void> _updateUserSavings(double amount, bool isDeposit, String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSavings = prefs.getDouble('user_savings') ?? 0.0;
      
      double newSavings;
      if (isDeposit) {
        newSavings = currentSavings + amount;
      } else {
        newSavings = currentSavings - amount;
        if (newSavings < 0) {
          throw Exception('Insufficient funds for withdrawal');
        }
      }
      
      await prefs.setDouble('user_savings', newSavings);
      await _saveTransactionHistory(amount, isDeposit, transactionId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveTransactionHistory(double amount, bool isDeposit, String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transaction_history') ?? '[]';
      final transactions = List<Map<String, dynamic>>.from(jsonDecode(transactionsJson));
      
      transactions.add({
        'id': transactionId,
        'type': isDeposit ? 'deposit' : 'withdrawal',
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'phone': _phoneController.text,
        'status': 'completed',
      });
      
      await prefs.setString('transaction_history', jsonEncode(transactions));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving transaction history: $e');
      }
    }
  }

  Future<void> _sendSMSConfirmation(double amount, bool isDeposit, String transactionId) async {
    try {
      final message = isDeposit
          ? 'SACCO Deposit Successful! Amount: UGX ${amount.toStringAsFixed(2)}, Transaction ID: $transactionId'
          : 'SACCO Withdrawal Successful! Amount: UGX ${amount.toStringAsFixed(2)}, Transaction ID: $transactionId';
      
      if (kDebugMode) {
        print('SMS to ${_phoneController.text}: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending SMS: $e');
      }
    }
  }

  void _showInAppConfirmation(bool success, double amount, String transactionId) {
    final title = success ? 'Transaction Successful!' : 'Transaction Failed';
    final message = success
        ? '${_isDeposit ? 'Deposit' : 'Withdrawal'} of UGX ${amount.toStringAsFixed(2)} has been processed.'
        : 'Your transaction could not be processed. Please try again.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (success) ...[
              const SizedBox(height: 16),
              Text('Transaction ID: $transactionId'),
              const SizedBox(height: 8),
              Text('Phone: +256 ${_phoneController.text}'),
              const SizedBox(height: 8),
              FutureBuilder<double>(
                future: _getCurrentSavings(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Current Savings: UGX ${snapshot.data!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<double> _getCurrentSavings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('user_savings') ?? 0.0;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final isVerified = await _verifyUserDetails();
    if (!isVerified) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionId = MomoService.generateTransactionId();
      final amount = double.parse(_amountController.text);

      if (!_isDeposit) {
        final currentSavings = await _getCurrentSavings();
        if (amount > currentSavings) {
          setState(() {
            _errorMessage = 'Insufficient funds. Current savings: UGX ${currentSavings.toStringAsFixed(2)}';
            _isLoading = false;
          });
          return;
        }
      }

      final momoService = MomoService(
        subscriptionKey: subscriptionKey,
        apiUser: apiUser,
        apiKey: apiKey,
        isSandbox: isSandbox,
        callbackUrl: callbackUrl,
      );

      final paymentData = await momoService.requestPayment(
        phoneNumber: _phoneController.text,
        amount: amount,
        externalId: transactionId,
        payerMessage: _isDeposit 
            ? 'SACCO Deposit: UGX ${amount.toStringAsFixed(2)}'
            : 'SACCO Withdrawal: UGX ${amount.toStringAsFixed(2)}',
      );

      _startPolling(
        paymentData['referenceId'],
        paymentData['authorization'],
        paymentData['externalId'],
        momoService,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startPolling(
    String referenceId,
    String authorization,
    String externalId,
    MomoService momoService,
  ) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final data = await momoService.transactionStatus(
          referenceId: referenceId,
          authorization: authorization,
        );

        if (data['externalId'] == externalId) {
          timer.cancel();
          
          final isSuccess = data['status'] == 'SUCCESSFUL';
          final amount = double.parse(_amountController.text);

          if (mounted) {
            setState(() => _isLoading = false);
            
            if (isSuccess) {
              await _updateUserSavings(amount, _isDeposit, referenceId);
              await _sendSMSConfirmation(amount, _isDeposit, referenceId);
            }
            
            _showInAppConfirmation(isSuccess, amount, referenceId);
            widget.onPaymentComplete(isSuccess);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Polling error: $e');
        }
      }
    });

    Timer(const Duration(minutes: 2), () {
      if (_pollingTimer?.isActive == true) {
        _pollingTimer?.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
          _showInAppConfirmation(false, double.parse(_amountController.text), referenceId);
        }
      }
    });
  }

  Widget _buildConfirmationScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showConfirmation = false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isVerifying)
              const LinearProgressIndicator(),
            
            if (_verificationError != null)
              Text(
                _verificationError!,
                style: const TextStyle(color: Colors.red),
              ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _isDeposit ? 'Deposit' : 'Withdrawal',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Amount:'),
                        const Spacer(),
                        Text(
                          'UGX ${double.parse(_amountController.text).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Phone:'),
                        const Spacer(),
                        Text('+256 ${_phoneController.text}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Name:'),
                        const Spacer(),
                        Text(_nameController.text),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: (_isLoading || _isVerifying) ? null : _processPayment,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text('Confirm ${_isDeposit ? 'Deposit' : 'Withdrawal'}'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showConfirmation) {
      return _buildConfirmationScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTN Mobile Money'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                FutureBuilder<double>(
                  future: _getCurrentSavings(),
                  builder: (context, snapshot) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text('Current Savings'),
                            Text(
                              'UGX ${snapshot.data?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Transaction Type'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() => _isDeposit = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isDeposit ? Colors.amber : null,
                                ),
                                child: const Text('Deposit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => setState(() => _isDeposit = false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_isDeposit ? Colors.amber : null,
                                ),
                                child: const Text('Withdraw'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            suffixIcon: _autoFilled
                                ? const Icon(Icons.auto_awesome, color: Colors.green)
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixText: '+256 ',
                            suffixIcon: _autoFilled
                                ? const Icon(Icons.auto_awesome, color: Colors.green)
                                : null,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (value.length < 9) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: 'UGX ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _showConfirmation = true);
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}