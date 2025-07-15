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
//   bool _isLoading = false;
//   String? _errorMessage;
//   Timer? _pollingTimer;

//   @override
//   void initState() {
//     super.initState();
//     if (kDebugMode) {
//       _phoneController.text = '775123456'; // Test UG number for sandbox
//     }
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _pollingTimer?.cancel();
//     super.dispose();
//   }

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
//       ); // Configured with your credentials

//       final payementData = await momoService.requestPayment(
//         phoneNumber: _phoneController.text,
//         amount: widget.amount,
//         externalId: transactionId,
//         payerMessage:
//             'SACCO Contribution: UGX ${widget.amount.toStringAsFixed(2)}',
//       );
//       // Start polling for payment confirmation
//       _startPolling(
//         payementData['referenceId'],
//         payementData['authorization'],
//         payementData['externalId'],
//         momoService,
//       );
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
//     // return File('momo_callback.json');
//   }

//   // Future<void> _saveMomoCallback(Map<String, dynamic> data) async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   prefs.setString('momo_callback', jsonEncode(data));
//   // }

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

//   void _startPolling(
//     String referenceId,
//     String authorization,
//     String externalId,
//     MomoService momoService,
//   ) {
//     _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
//       // late File file;
//       // late Map<String, dynamic>? data;
//       // if (!kIsWeb) {
//       //   file = await _getCallbackFile();
//       // }

//       // if (kIsWeb || await file.exists()) {
//       // if (kIsWeb) {
//       //   // data = await _loadMomoCallback();
//       //   data = null;
//       // } else {
//       //   data = jsonDecode(await file.readAsString());
//       // }
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
//               'amount': widget.amount,
//               'transactionId': referenceId,
//             },
//           );
//         }
//       }
//       // }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('MTN Mobile Money Payment'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: _isLoading ? null : () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Payment Amount Display
//               Text(
//                 'Pay UGX ${widget.amount.toStringAsFixed(2)}',
//                 style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).primaryColor,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),

//               // Phone Number Input
//               TextFormField(
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(
//                   labelText: 'MTN Mobile Money Number',
//                   prefixText: '+256 ',
//                   border: OutlineInputBorder(),
//                   hintText: '775123456',
//                   prefixIcon: Icon(Icons.phone),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your phone number';
//                   }
//                   final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
//                   if (!RegExp(r'^(0|7)\d{8}$').hasMatch(cleaned)) {
//                     return 'Enter a valid Uganda number (e.g. 775123456)';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),

//               // Error Message
//               if (_errorMessage != null)
//                 Text(
//                   _errorMessage!,
//                   style: TextStyle(
//                     color: Theme.of(context).colorScheme.error,
//                     fontSize: 14,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),

//               const Spacer(),

//               // Payment Button
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _processPayment,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: Theme.of(context).primaryColor,
//                   disabledBackgroundColor: Colors.grey[400],
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 3,
//                         ),
//                       )
//                     : const Text(
//                         'Pay with Mobile Money',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//               ),
//               const SizedBox(height: 16),

//               // Instruction Text
//               Text(
//                 'You will receive a Mobile Money prompt on your phone to confirm the payment',
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

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

// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:smartsacco/services/momoservices.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/services.dart'; // For SMS sending

// const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
// const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
// const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
// const bool isSandbox = true;
// const String callbackUrl =
//     'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

// class MomoPaymentPage extends StatefulWidget {
//   final double amount;
//   final Function(bool success) onPaymentComplete;
//   final Map<String, dynamic>? userProfile; // Add user profile data

//   const MomoPaymentPage({
//     super.key,
//     required this.amount,
//     required this.onPaymentComplete,
//     this.userProfile,
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
//   bool _isDeposit = true;
//   bool _showConfirmation = false;
//   bool _isVerifying = false;
//   String? _verificationError;

//   @override
//   void initState() {
//     super.initState();
//     _amountController.text = widget.amount.toStringAsFixed(2);
//     _loadUserProfile();
    
//     if (kDebugMode) {
//       _phoneController.text = '775123456';
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

//   // Load user profile data automatically
//   void _loadUserProfile() {
//     if (widget.userProfile != null) {
//       _nameController.text = widget.userProfile!['fullName'] ?? '';
//       _phoneController.text = widget.userProfile!['phoneNumber'] ?? '';
//     }
//   }

//   // Auto-verify user details
//   Future<bool> _verifyUserDetails() async {
//     setState(() {
//       _isVerifying = true;
//       _verificationError = null;
//     });

//     try {
//       // Simulate verification process (replace with actual verification logic)
//       await Future.delayed(const Duration(seconds: 2));
      
//       // Check if phone number matches user profile
//       if (widget.userProfile != null) {
//         final profilePhone = widget.userProfile!['phoneNumber']?.toString() ?? '';
//         final inputPhone = _phoneController.text.trim();
        
//         if (profilePhone.isNotEmpty && !_phoneNumbersMatch(profilePhone, inputPhone)) {
//           setState(() {
//             _verificationError = 'Phone number does not match your profile';
//             _isVerifying = false;
//           });
//           return false;
//         }
        
//         // Check if name matches user profile
//         final profileName = widget.userProfile!['fullName']?.toString() ?? '';
//         final inputName = _nameController.text.trim();
        
//         if (profileName.isNotEmpty && !_namesMatch(profileName, inputName)) {
//           setState(() {
//             _verificationError = 'Name does not match your profile';
//             _isVerifying = false;
//           });
//           return false;
//         }
//       }
      
//       setState(() => _isVerifying = false);
//       return true;
//     } catch (e) {
//       setState(() {
//         _verificationError = 'Verification failed: ${e.toString()}';
//         _isVerifying = false;
//       });
//       return false;
//     }
//   }

//   bool _phoneNumbersMatch(String profile, String input) {
//     // Remove all non-digit characters
//     final profileClean = profile.replaceAll(RegExp(r'[^0-9]'), '');
//     final inputClean = input.replaceAll(RegExp(r'[^0-9]'), '');
    
//     // Compare last 9 digits (Uganda phone format)
//     return profileClean.length >= 9 && inputClean.length >= 9 &&
//            profileClean.substring(profileClean.length - 9) == 
//            inputClean.substring(inputClean.length - 9);
//   }

//   bool _namesMatch(String profile, String input) {
//     // Simple name matching (case-insensitive)
//     return profile.toLowerCase().trim() == input.toLowerCase().trim();
//   }

//   // Update user savings
//   Future<void> _updateUserSavings(double amount, bool isDeposit, String transactionId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final currentSavings = prefs.getDouble('user_savings') ?? 0.0;
      
//       double newSavings;
//       if (isDeposit) {
//         newSavings = currentSavings + amount;
//       } else {
//         newSavings = currentSavings - amount;
//         // Ensure savings don't go below zero
//         if (newSavings < 0) {
//           throw Exception('Insufficient funds for withdrawal');
//         }
//       }
      
//       await prefs.setDouble('user_savings', newSavings);
      
//       // Save transaction history
//       await _saveTransactionHistory(amount, isDeposit, transactionId);
      
//       if (kDebugMode) {
//         print('Savings updated: UGX ${newSavings.toStringAsFixed(2)}');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error updating savings: $e');
//       }
//       rethrow;
//     }
//   }

//   // Save transaction history
//   Future<void> _saveTransactionHistory(double amount, bool isDeposit, String transactionId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final transactionsJson = prefs.getString('transaction_history') ?? '[]';
//       final transactions = List<Map<String, dynamic>>.from(jsonDecode(transactionsJson));
      
//       transactions.add({
//         'id': transactionId,
//         'type': isDeposit ? 'deposit' : 'withdrawal',
//         'amount': amount,
//         'date': DateTime.now().toIso8601String(),
//         'phone': _phoneController.text,
//         'status': 'completed',
//       });
      
//       await prefs.setString('transaction_history', jsonEncode(transactions));
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error saving transaction history: $e');
//       }
//     }
//   }

//   // Send SMS confirmation (placeholder - integrate with actual SMS service)
//   Future<void> _sendSMSConfirmation(double amount, bool isDeposit, String transactionId) async {
//     try {
//       final message = isDeposit
//           ? 'SACCO Deposit Successful! Amount: UGX ${amount.toStringAsFixed(2)}, Transaction ID: $transactionId. Thank you for banking with us.'
//           : 'SACCO Withdrawal Successful! Amount: UGX ${amount.toStringAsFixed(2)}, Transaction ID: $transactionId. Thank you for banking with us.';
      
//       // TODO: Integrate with actual SMS service
//       // For now, just log the message
//       if (kDebugMode) {
//         print('SMS to ${_phoneController.text}: $message');
//       }
      
//       // You can integrate with services like Twilio, Africa's Talking, etc.
//       // await _smsService.sendSMS(_phoneController.text, message);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error sending SMS: $e');
//       }
//     }
//   }

//   // Show in-app confirmation
//   void _showInAppConfirmation(bool success, double amount, String transactionId) {
//     final title = success ? 'Transaction Successful!' : 'Transaction Failed';
//     final message = success
//         ? '${_isDeposit ? 'Deposit' : 'Withdrawal'} of UGX ${amount.toStringAsFixed(2)} has been processed successfully.'
//         : 'Your ${_isDeposit ? 'deposit' : 'withdrawal'} could not be processed. Please try again.';

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(
//               success ? Icons.check_circle : Icons.error,
//               color: success ? Colors.green : Colors.red,
//               size: 32,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 color: success ? Colors.green : Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(message),
//             const SizedBox(height: 16),
//             if (success) ...[
//               Text('Transaction ID: $transactionId',
//                   style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               Text('Phone: +256 ${_phoneController.text}',
//                   style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               FutureBuilder<double>(
//                 future: _getCurrentSavings(),
//                 builder: (context, snapshot) {
//                   if (snapshot.hasData) {
//                     return Text(
//                       'Current Savings: UGX ${snapshot.data!.toStringAsFixed(2)}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green,
//                       ),
//                     );
//                   }
//                   return const SizedBox();
//                 },
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).pop(); // Go back to previous screen
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<double> _getCurrentSavings() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getDouble('user_savings') ?? 0.0;
//   }

  

//   // Enhanced payment processing with savings update
//   Future<void> _processPayment() async {
//     if (!_formKey.currentState!.validate()) return;

//     // Auto-verify user details first
//     final isVerified = await _verifyUserDetails();
//     if (!isVerified) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final transactionId = MomoService.generateTransactionId();
//       final amount = double.parse(_amountController.text);

//       // Check if withdrawal amount is available
//       if (!_isDeposit) {
//         final currentSavings = await _getCurrentSavings();
//         if (amount > currentSavings) {
//           setState(() {
//             _errorMessage = 'Insufficient funds. Current savings: UGX ${currentSavings.toStringAsFixed(2)}';
//             _isLoading = false;
//           });
//           return;
//         }
//       }

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

//       final paymentData = await momoService.requestPayment(
//         phoneNumber: _phoneController.text,
//         amount: amount,
//         externalId: transactionId,
//         payerMessage: _isDeposit 
//             ? 'SACCO Deposit: UGX ${amount.toStringAsFixed(2)}'
//             : 'SACCO Withdrawal: UGX ${amount.toStringAsFixed(2)}',
//       );

//       // Start polling for payment confirmation
//       _startPolling(
//         paymentData['referenceId'],
//         paymentData['authorization'],
//         paymentData['externalId'],
//         momoService,
//       );
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

//   // Enhanced polling with savings update
//   void _startPolling(
//     String referenceId,
//     String authorization,
//     String externalId,
//     MomoService momoService,
//   ) {
//     _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
//       try {
//         final data = await momoService.transactionStatus(
//           referenceId: referenceId,
//           authorization: authorization,
//         );

//         if (data['externalId'] == externalId) {
//           timer.cancel();
          
//           final isSuccess = data['status'] == 'SUCCESSFUL';
//           final amount = double.parse(_amountController.text);

//           if (mounted) {
//             setState(() => _isLoading = false);
            
//             if (isSuccess) {
//               // Update savings
//               await _updateUserSavings(amount, _isDeposit, referenceId);
              
//               // Send SMS confirmation
//               await _sendSMSConfirmation(amount, _isDeposit, referenceId);
//             }
            
//             // Show in-app confirmation
//             _showInAppConfirmation(isSuccess, amount, referenceId);
            
//             // Call the original callback
//             widget.onPaymentComplete(isSuccess);
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print('Polling error: $e');
//         }
//       }
//     });

//     // Add timeout after 2 minutes
//     Timer(const Duration(minutes: 2), () {
//       if (_pollingTimer?.isActive == true) {
//         _pollingTimer?.cancel();
//         if (mounted) {
//           setState(() => _isLoading = false);
//           _showInAppConfirmation(false, double.parse(_amountController.text), referenceId);
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
//             // Verification Status
//             if (_isVerifying)
//               Card(
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       const SizedBox(width: 12),
//                       const Text('Verifying user details...'),
//                     ],
//                   ),
//                 ),
//               ),
            
//             if (_verificationError != null)
//               Card(
//                 elevation: 4,
//                 child: Container(
//                   padding: const EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.error, color: Colors.red.shade600),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           _verificationError!,
//                           style: TextStyle(
//                             color: Colors.red.shade600,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
            
//             const SizedBox(height: 16),
            
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
                    
//                     // Show current savings for withdrawal
//                     if (!_isDeposit)
//                       FutureBuilder<double>(
//                         future: _getCurrentSavings(),
//                         builder: (context, snapshot) {
//                           if (snapshot.hasData) {
//                             return _buildDetailRow(
//                               'Current Savings', 
//                               'UGX ${snapshot.data!.toStringAsFixed(2)}'
//                             );
//                           }
//                           return const SizedBox();
//                         },
//                       ),
                    
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
//                     onPressed: (_isLoading || _isVerifying || _verificationError != null) ? null : _processPayment,
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
//               // Current Savings Display
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.green.shade400, Colors.green.shade600],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       const Text(
//                         'Current Savings',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       FutureBuilder<double>(
//                         future: _getCurrentSavings(),
//                         builder: (context, snapshot) {
//                           if (snapshot.hasData) {
//                             return Text(
//                               'UGX ${snapshot.data!.toStringAsFixed(2)}',
//                               style: const TextStyle(
//                                 fontSize: 28,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             );
//                           }
//                           return const CircularProgressIndicator(color: Colors.white);
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
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
                         
// const SizedBox(width: 12),
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


// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:smartsacco/services/momoservices.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
// const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
// const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
// const bool isSandbox = true;
// const String callbackUrl = 'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

// class MomoPaymentPage extends StatefulWidget {
//   final double amount;
//   final Function(bool success) onPaymentComplete;
//   final Map<String, dynamic>? userProfile;

//   const MomoPaymentPage({
//     super.key,
//     required this.amount,
//     required this.onPaymentComplete,
//     this.userProfile,
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
//   bool _isDeposit = true;
//   bool _showConfirmation = false;
//   bool _isVerifying = false;
//   String? _verificationError;
//   double _currentSavings = 0.0;

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   void initState() {
//     super.initState();
//     _amountController.text = widget.amount.toStringAsFixed(2);
//     _loadUserProfile();
//     _loadCurrentSavings();
    
//     if (kDebugMode) {
//       _phoneController.text = '775123456';
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

//   Future<void> _loadCurrentSavings() async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         final doc = await _firestore.collection('users').doc(user.uid).get();
//         if (doc.exists) {
//           setState(() {
//             _currentSavings = (doc.data()?['savings'] ?? 0.0).toDouble();
//           });
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading savings: $e');
//       }
//     }
//   }

//   void _loadUserProfile() {
//     if (widget.userProfile != null) {
//       _nameController.text = widget.userProfile!['fullName'] ?? '';
//       _phoneController.text = widget.userProfile!['phoneNumber'] ?? '';
//     }
//   }

//   Future<bool> _verifyUserDetails() async {
//     setState(() {
//       _isVerifying = true;
//       _verificationError = null;
//     });

//     try {
//       if (widget.userProfile == null) {
//         throw Exception('User profile not available');
//       }

//       final profilePhone = _cleanPhoneNumber(widget.userProfile!['phoneNumber']?.toString() ?? '');
//       final inputPhone = _cleanPhoneNumber(_phoneController.text.trim());
      
//       if (profilePhone.isEmpty) {
//         throw Exception('No registered phone number found in profile');
//       }
      
//       if (profilePhone != inputPhone) {
//         throw Exception('Phone number does not match your registered number');
//       }
      
//       final profileName = (widget.userProfile!['fullName']?.toString() ?? '').trim().toLowerCase();
//       final inputName = _nameController.text.trim().toLowerCase();
      
//       if (profileName.isEmpty) {
//         throw Exception('No registered name found in profile');
//       }
      
//       if (profileName != inputName) {
//         throw Exception('Name does not match your registered name');
//       }
      
//       setState(() => _isVerifying = false);
//       return true;
//     } catch (e) {
//       setState(() {
//         _verificationError = e.toString();
//         _isVerifying = false;
//       });
//       return false;
//     }
//   }

//   String _cleanPhoneNumber(String phone) {
//     final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
//     if (cleaned.startsWith('0') && cleaned.length == 10) {
//       return '256${cleaned.substring(1)}';
//     } else if (cleaned.startsWith('7') && cleaned.length == 9) {
//       return '256$cleaned';
//     } else if (cleaned.startsWith('256') && cleaned.length == 12) {
//       return cleaned;
//     }
    
//     return cleaned;
//   }

//   Future<void> _updateUserSavings(double amount, bool isDeposit, String transactionId) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception('User not authenticated');

//       final userRef = _firestore.collection('users').doc(user.uid);
      
//       await _firestore.runTransaction((transaction) async {
//         final doc = await transaction.get(userRef);
//         if (!doc.exists) throw Exception('User document not found');

//         final currentSavings = (doc.data()?['savings'] ?? 0.0).toDouble();
//         double newSavings;

//         if (isDeposit) {
//           newSavings = currentSavings + amount;
//         } else {
//           if (amount > currentSavings) {
//             throw Exception('Insufficient funds for withdrawal');
//           }
//           newSavings = currentSavings - amount;
//         }

//         transaction.update(userRef, {'savings': newSavings});

//         // Save transaction history
//         final transactionData = {
//           'userId': user.uid,
//           'type': isDeposit ? 'deposit' : 'withdrawal',
//           'amount': amount,
//           'date': DateTime.now(),
//           'phone': _phoneController.text,
//           'transactionId': transactionId,
//           'status': 'completed',
//         };

//         await _firestore.collection('transactions').add(transactionData);

//         setState(() {
//           _currentSavings = newSavings;
//         });
//       });

//       await _sendSMSConfirmation(amount, isDeposit, transactionId);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error updating savings: $e');
//       }
//       rethrow;
//     }
//   }

//   Future<void> _sendSMSConfirmation(double amount, bool isDeposit, String transactionId) async {
//     // In a real app, integrate with an SMS service like Twilio or Africa's Talking
//     if (kDebugMode) {
//       print('SMS to ${_phoneController.text}: ${isDeposit ? 'Deposit' : 'Withdrawal'} of UGX ${amount.toStringAsFixed(2)} completed. Transaction ID: $transactionId');
//     }
//   }

//   void _showInAppConfirmation(bool success, double amount, String transactionId) {
//     final title = success ? 'Transaction Successful!' : 'Transaction Failed';
//     final message = success
//         ? '${_isDeposit ? 'Deposit' : 'Withdrawal'} of UGX ${amount.toStringAsFixed(2)} has been processed successfully.'
//         : 'Your ${_isDeposit ? 'deposit' : 'withdrawal'} could not be processed. Please try again.';

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(
//               success ? Icons.check_circle : Icons.error,
//               color: success ? Colors.green : Colors.red,
//               size: 32,
//             ),
//             const SizedBox(width: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 color: success ? Colors.green : Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(message),
//             const SizedBox(height: 16),
//             if (success) ...[
//               Text('Transaction ID: $transactionId',
//                   style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               Text('Phone: +256 ${_phoneController.text}',
//                   style: const TextStyle(fontWeight: FontWeight.w500)),
//               const SizedBox(height: 8),
//               Text(
//                 'Current Savings: UGX ${_currentSavings.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//               ),
//             ],
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).pop(); // Go back to previous screen
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _processPayment() async {
//     if (!_formKey.currentState!.validate()) return;

//     final isVerified = await _verifyUserDetails();
//     if (!isVerified) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final transactionId = MomoService.generateTransactionId();
//       final amount = double.parse(_amountController.text);

//       if (!_isDeposit && amount > _currentSavings) {
//         setState(() {
//           _errorMessage = 'Insufficient funds. Current savings: UGX ${_currentSavings.toStringAsFixed(2)}';
//           _isLoading = false;
//         });
//         return;
//       }

//       final momoService = MomoService(
//         subscriptionKey: subscriptionKey,
//         apiUser: apiUser,
//         apiKey: apiKey,
//         isSandbox: isSandbox,
//         callbackUrl: callbackUrl,
//       );

//       final paymentData = await momoService.requestPayment(
//         phoneNumber: _phoneController.text,
//         amount: amount,
//         externalId: transactionId,
//         payerMessage: _isDeposit 
//             ? 'SACCO Deposit: UGX ${amount.toStringAsFixed(2)}'
//             : 'SACCO Withdrawal: UGX ${amount.toStringAsFixed(2)}',
//       );

//       _startPolling(
//         paymentData['referenceId'],
//         paymentData['authorization'],
//         paymentData['externalId'],
//         momoService,
//       );
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Payment failed: ${e.toString()}';
//         _isLoading = false;
//       });
//     }
//   }

//   void _startPolling(
//     String referenceId,
//     String authorization,
//     String externalId,
//     MomoService momoService,
//   ) {
//     _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
//       try {
//         final data = await momoService.transactionStatus(
//           referenceId: referenceId,
//           authorization: authorization,
//         );

//         if (data['externalId'] == externalId) {
//           timer.cancel();
          
//           final isSuccess = data['status'] == 'SUCCESSFUL';
//           final amount = double.parse(_amountController.text);

//           if (mounted) {
//             setState(() => _isLoading = false);
            
//             if (isSuccess) {
//               await _updateUserSavings(amount, _isDeposit, referenceId);
//             }
            
//             _showInAppConfirmation(isSuccess, amount, referenceId);
//             widget.onPaymentComplete(isSuccess);
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print('Polling error: $e');
//         }
//       }
//     });

//     Timer(const Duration(minutes: 2), () {
//       if (_pollingTimer?.isActive == true) {
//         _pollingTimer?.cancel();
//         if (mounted) {
//           setState(() => _isLoading = false);
//           _showInAppConfirmation(false, double.parse(_amountController.text), referenceId);
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
//             if (_isVerifying)
//               Card(
//                 elevation: 4,
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     children: [
//                       const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                       const SizedBox(width: 12),
//                       const Text('Verifying user details...'),
//                     ],
//                   ),
//                 ),
//               ),
            
//             if (_verificationError != null)
//               Card(
//                 elevation: 4,
//                 child: Container(
//                   padding: const EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.red.shade50,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.error, color: Colors.red.shade600),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           _verificationError!,
//                           style: TextStyle(
//                             color: Colors.red.shade600,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
            
//             const SizedBox(height: 16),
            
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
                    
//                     if (!_isDeposit)
//                       _buildDetailRow(
//                         'Current Savings', 
//                         'UGX ${_currentSavings.toStringAsFixed(2)}'
//                       ),
                    
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
//                     onPressed: (_isLoading || _isVerifying || _verificationError != null) 
//                         ? null 
//                         : _processPayment,
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
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.green.shade400, Colors.green.shade600],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Column(
//                     children: [
//                       const Text(
//                         'Current Savings',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'UGX ${_currentSavings.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
              
//               const SizedBox(height: 16),
              
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

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:smartsacco/services/momoservices.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
// const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
// const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
// const bool isSandbox = true;
// const String callbackUrl = 'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

// class MomoPaymentPage extends StatefulWidget {
//   final double amount;
//   final Function(bool success) onPaymentComplete;
//   final Map<String, dynamic>? userProfile;

//   const MomoPaymentPage({
//     super.key,
//     required this.amount,
//     required this.onPaymentComplete,
//     this.userProfile,
//   });

//   @override
//   State<MomoPaymentPage> createState() => _MomoPaymentPageState();
// }

// class _MomoPaymentPageState extends State<MomoPaymentPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   final _nameController = TextEditingController();
//   bool _isLoading = false;
//   String? _errorMessage;
//   Timer? _pollingTimer;

//   @override
//   void initState() {
//     super.initState();
//     if (kDebugMode) {
//       _phoneController.text = widget.userProfile?['phoneNumber'] ?? '775123456';
//       _nameController.text = widget.userProfile?['fullName'] ?? 'John Doe';
//     } else if (widget.userProfile != null) {
//       _nameController.text = widget.userProfile!['fullName'] ?? '';
//       _phoneController.text = widget.userProfile!['phoneNumber'] ?? '';
//     }
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _nameController.dispose();
//     _pollingTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _processPayment() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final transactionId = MomoService.generateTransactionId();

//       final momoService = MomoService(
//         subscriptionKey: subscriptionKey,
//         apiUser: apiUser,
//         apiKey: apiKey,
//         isSandbox: isSandbox,
//         callbackUrl: callbackUrl,
//       );

//       final paymentData = await momoService.requestPayment(
//         phoneNumber: _phoneController.text,
//         amount: widget.amount,
//         externalId: transactionId,
//         payerMessage: 'SACCO Payment by ${_nameController.text}: UGX ${widget.amount.toStringAsFixed(2)}',
//       );

//       _startPolling(
//         paymentData['referenceId'],
//         paymentData['authorization'],
//         paymentData['externalId'],
//         momoService,
//       );
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

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
//           Navigator.pop(context); // Go back after payment
//         }
//       }
//     });

//     // Add timeout after 2 minutes
//     Timer(const Duration(minutes: 2), () {
//       if (_pollingTimer?.isActive == true) {
//         _pollingTimer?.cancel();
//         if (mounted) {
//           setState(() => _isLoading = false);
//           widget.onPaymentComplete(false);
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           'MTN Mobile Money',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: const Color(0xFFFFCC00), // MTN Yellow
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: _isLoading ? null : () => Navigator.pop(context),
//         ),
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             children: [
//               // MTN Branding Header
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 6,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Image.network(
//                       'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/MTN_Logo.svg/1200px-MTN_Logo.svg.png',
//                       height: 40,
//                       errorBuilder: (context, error, stackTrace) => 
//                         const Icon(Icons.mobile_friendly, size: 40, color: Color(0xFFFFCC00)),
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Mobile Money Payment',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Payment Card
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20.0),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Amount Display
//                         Center(
//                           child: Text(
//                             'UGX ${widget.amount.toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontSize: 28,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
                        
//                         // Full Name Input
//                         TextFormField(
//                           controller: _nameController,
//                           decoration: InputDecoration(
//                             labelText: 'Full Name',
//                             prefixIcon: const Icon(Icons.person, color: Color(0xFFFFCC00)),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2),
//                             ),
//                             filled: true,
//                             fillColor: Colors.grey[50],
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your full name';
//                             }
//                             if (value.length < 3) {
//                               return 'Name must be at least 3 characters';
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
//                             labelText: 'Mobile Money Number',
//                             prefixText: '+256 ',
//                             prefixIcon: const Icon(Icons.phone, color: Color(0xFFFFCC00)),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Colors.grey),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(color: Color(0xFFFFCC00), width: 2),
//                             ),
//                             hintText: '775123456',
//                             filled: true,
//                             fillColor: Colors.grey[50],
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter your phone number';
//                             }
//                             final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
//                             if (!RegExp(r'^(0|7)\d{8}$').hasMatch(cleaned)) {
//                               return 'Enter a valid Uganda number';
//                             }
//                             return null;
//                           },
//                         ),
//                         const SizedBox(height: 16),

//                         // Error Message
//                         if (_errorMessage != null)
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.red[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.red[100]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.error_outline, color: Colors.red),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     _errorMessage!,
//                                     style: const TextStyle(color: Colors.red),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Payment Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _processPayment,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFFFCC00), // MTN Yellow
//                     foregroundColor: Colors.black,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     elevation: 2,
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             color: Colors.black,
//                             strokeWidth: 3,
//                           ),
//                         )
//                       : const Text(
//                           'PAY WITH MOBILE MONEY',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Help Text
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 16.0),
//                 child: Text(
//                   'You will receive a Mobile Money prompt on your phone to confirm this payment',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: 14,
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

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smartsacco/services/momoservices.dart';

const String subscriptionKey = '45c1c5440807495b80c9db300112c631';
const String apiUser = '3c3b115f-6d90-4a1a-9d7a-2c1a0422fdfc';
const String apiKey = 'b7295fe722284bfcb65ecd97db695533';
const bool isSandbox = true;
const String callbackUrl = 'https://2e76-41-210-141-242.ngrok-free.app/momo-callback';

class MomoPaymentPage extends StatefulWidget {
  final double amount;
  final Function(bool success) onPaymentComplete;
  final Map<String, dynamic> userProfile;

  const MomoPaymentPage({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
    required this.userProfile,
  });

  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

class _MomoPaymentPageState extends State<MomoPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _verificationError;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Auto-populate with user's registered details
    _nameController.text = widget.userProfile['fullName'] ?? '';
    _phoneController.text = widget.userProfile['phoneNumber'] ?? '';
    
    if (kDebugMode) {
      if (_phoneController.text.isEmpty) _phoneController.text = '775123456';
      if (_nameController.text.isEmpty) _nameController.text = 'John Doe';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0') && digits.length == 10) return '256${digits.substring(1)}';
    if (digits.startsWith('7') && digits.length == 9) return '256$digits';
    if (digits.startsWith('256') && digits.length == 12) return digits;
    if (digits.startsWith('+256') && digits.length == 13) return digits.substring(1);
    return digits;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    final normalized = _normalizePhone(value);
    if (normalized.length != 12 || !normalized.startsWith('256')) {
      return 'Please enter a valid Ugandan phone number';
    }
    
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    return null;
  }

  Future<bool> _verifyUserDetails() async {
    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    try {
      final registeredPhone = _normalizePhone(widget.userProfile['phoneNumber'] ?? '');
      final enteredPhone = _normalizePhone(_phoneController.text);

      // Allow users to use different phone numbers, but warn them
      if (registeredPhone.isNotEmpty && registeredPhone != enteredPhone) {
        // Show warning but don't block the transaction
        setState(() => _verificationError = 
          'Note: You\'re using a different number than registered (${widget.userProfile['phoneNumber']}). Ensure this number has sufficient balance.');
      }

      return true;
    } catch (e) {
      setState(() => _verificationError = e.toString());
      return false;
    } finally {
      setState(() => _isVerifying = false);
    }
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
      final transactionId = 'MOMO-${DateTime.now().millisecondsSinceEpoch}';
      final momoService = MomoService(
        subscriptionKey: subscriptionKey,
        apiUser: apiUser,
        apiKey: apiKey,
        isSandbox: isSandbox,
        callbackUrl: callbackUrl,
      );

      final paymentData = await momoService.requestPayment(
        phoneNumber: _phoneController.text,
        amount: widget.amount,
        externalId: transactionId,
        payerMessage: 'SACCO Payment: UGX ${widget.amount.toStringAsFixed(2)}',
      );

      _startPolling(
        paymentData['referenceId'],
        paymentData['authorization'],
        transactionId,
        momoService,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: ${e.toString()}';
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
          if (mounted) {
            setState(() => _isLoading = false);
            widget.onPaymentComplete(data['status'] == 'SUCCESSFUL');
            Navigator.pop(context);
          }
        }
      } catch (e) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Status check failed: ${e.toString()}';
          });
        }
      }
    });

    Timer(const Duration(minutes: 2), () {
      if (_pollingTimer?.isActive == true) {
        _pollingTimer?.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onPaymentComplete(false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('MTN Mobile Money'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFCC00),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // MTN Branding
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/MTN_Logo.svg/1200px-MTN_Logo.svg.png',
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.mobile_friendly, size: 40, color: Color(0xFFFFCC00)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mobile Money Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'UGX ${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Confirm Your Payment Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_isVerifying)
                          const LinearProgressIndicator(
                            color: Color(0xFFFFCC00),
                          ),

                        if (_verificationError != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, 
                                  color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _verificationError!,
                                    style: const TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        TextFormField(
                          controller: _nameController,
                          validator: _validateName,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            hintText: 'Enter your full name',
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneController,
                          validator: _validatePhoneNumber,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Money Number',
                            prefixIcon: Icon(Icons.phone),
                            prefixText: '+256 ',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your mobile money number',
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, 
                                  color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC00),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing Payment...'),
                          ],
                        )
                      : const Text(
                          'PAY WITH MOBILE MONEY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'You will receive a payment prompt on your phone',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}