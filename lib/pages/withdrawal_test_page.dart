// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/transaction_validation_service.dart';
import '../services/momoservices.dart';

class WithdrawalTestPage extends StatefulWidget {
  const WithdrawalTestPage({super.key});

  @override
  State<WithdrawalTestPage> createState() => _WithdrawalTestPageState();
}

class _WithdrawalTestPageState extends State<WithdrawalTestPage> {
  final TransactionValidationService _validationService =
      TransactionValidationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _currentUserId;
  double _currentSavings = 0.0;

  // Test data
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedMethod = 'MTN MoMo';

  // Test results
  Map<String, dynamic>? _lastTestResult;
  final List<Map<String, dynamic>> _testHistory = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _loadCurrentSavings();
    }
  }

  Future<void> _loadCurrentSavings() async {
    if (_currentUserId == null) return;

    try {
      final savingsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('savings')
          .get();

      double totalSavings = 0;
      for (var doc in savingsSnapshot.docs) {
        final amount = doc['amount']?.toDouble() ?? 0;
        totalSavings += amount;
      }

      setState(() {
        _currentSavings = totalSavings;
      });
    } catch (e) {
      print('Error loading current savings: $e');
    }
  }

  Future<void> _testWithdrawal() async {
    if (_currentUserId == null) {
      _showError('User not authenticated');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    final phone = _phoneController.text.trim();

    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (phone.isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    if (amount > _currentSavings) {
      _showError(
        'Insufficient funds. Available: ${_formatCurrency(_currentSavings)}',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🧪 Starting withdrawal test...');
      print('📝 Amount: $amount, Phone: $phone, Method: $_selectedMethod');
      print('💰 Current savings: $_currentSavings');

      // Test 1: Validate input data
      final inputValidation = _validateInputData(
        amount,
        phone,
        _selectedMethod,
      );
      if (!inputValidation['valid']) {
        _addTestResult('Input Validation', false, inputValidation['error']);
        return;
      }
      _addTestResult('Input Validation', true, 'Input data is valid');

      // Test 2: Check MTN MoMo service
      if (_selectedMethod == 'MTN MoMo') {
        final momoTest = await _testMTNMoMoService(amount, phone);
        if (!momoTest['valid']) {
          _addTestResult('MTN MoMo Service', false, momoTest['error']);
          return;
        }
        _addTestResult('MTN MoMo Service', true, momoTest['message']);
      }

      // Test 3: Simulate withdrawal transaction
      final transactionTest = await _testWithdrawalTransaction(
        amount,
        phone,
        _selectedMethod,
      );
      if (!transactionTest['valid']) {
        _addTestResult(
          'Transaction Processing',
          false,
          transactionTest['error'],
        );
        return;
      }
      _addTestResult(
        'Transaction Processing',
        true,
        transactionTest['message'],
      );

      // Test 4: Validate database records
      final validationTest = await _testDatabaseValidation(
        transactionTest['transactionId'],
        amount,
        _selectedMethod,
      );
      if (!validationTest['valid']) {
        _addTestResult('Database Validation', false, validationTest['error']);
        return;
      }
      _addTestResult('Database Validation', true, validationTest['message']);

      // Test 5: Verify balance update
      final balanceTest = await _testBalanceUpdate(amount);
      if (!balanceTest['valid']) {
        _addTestResult('Balance Update', false, balanceTest['error']);
        return;
      }
      _addTestResult('Balance Update', true, balanceTest['message']);

      _showSuccess('Withdrawal test completed successfully!');
    } catch (e) {
      print('❌ Error during withdrawal test: $e');
      _addTestResult('Overall Test', false, 'Error: $e');
      _showError('Test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _validateInputData(
    double amount,
    String phone,
    String method,
  ) {
    try {
      // Validate amount
      if (amount <= 0) {
        return {'valid': false, 'error': 'Amount must be greater than 0'};
      }

      if (amount > _currentSavings) {
        return {'valid': false, 'error': 'Insufficient funds'};
      }

      // Validate phone number
      if (phone.isEmpty) {
        return {'valid': false, 'error': 'Phone number is required'};
      }

      // Basic phone number format validation
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.length < 9 || cleanPhone.length > 10) {
        return {'valid': false, 'error': 'Invalid phone number format'};
      }

      // Validate method
      if (method.isEmpty) {
        return {'valid': false, 'error': 'Withdrawal method is required'};
      }

      return {'valid': true, 'message': 'Input validation passed'};
    } catch (e) {
      return {'valid': false, 'error': 'Input validation error: $e'};
    }
  }

  Future<Map<String, dynamic>> _testMTNMoMoService(
    double amount,
    String phone,
  ) async {
    try {
      print('🔍 Testing MTN MoMo service...');

      final momoService = MomoService();

      // Format phone number
      final formattedPhone = phone.startsWith('0') ? phone.substring(1) : phone;
      final fullPhone = '256$formattedPhone';

      print('📱 Formatted phone: $fullPhone');

      // Test transfer method
      final result = await momoService.transferMoney(
        phoneNumber: fullPhone,
        amount: amount,
        externalId: 'TEST_WITHDRAWAL_${DateTime.now().millisecondsSinceEpoch}',
        payeeMessage: 'SACCO Test Withdrawal',
      );

      print('📊 MTN MoMo result: $result');

      if (result['success'] == true) {
        return {
          'valid': true,
          'message': 'MTN MoMo service working correctly',
          'reference': result['referenceId'] ?? 'TEST_REF',
        };
      } else {
        return {
          'valid': false,
          'error': 'MTN MoMo service error: ${result['message']}',
        };
      }
    } catch (e) {
      return {'valid': false, 'error': 'MTN MoMo service test failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _testWithdrawalTransaction(
    double amount,
    String phone,
    String method,
  ) async {
    try {
      print('🔍 Testing withdrawal transaction...');

      // Generate unique transaction ID
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Start transaction batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Add to transactions collection
      final transactionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .doc(transactionId);

      batch.set(transactionRef, {
        'amount': amount,
        'type': 'Withdrawal',
        'method': method,
        'status': 'Completed',
        'date': FieldValue.serverTimestamp(),
        'reference': 'TEST_REF_$transactionId',
        'transactionId': transactionId,
        'userId': _currentUserId,
        'description': 'Test withdrawal via $method',
        'phoneNumber': phone,
      });

      // Add to savings collection as negative amount
      final savingsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('savings')
          .doc(transactionId);

      batch.set(savingsRef, {
        'amount': -amount, // Negative amount for withdrawal
        'date': FieldValue.serverTimestamp(),
        'type': 'Withdrawal',
        'method': method,
        'transactionId': transactionId,
        'userId': _currentUserId,
        'status': 'Completed',
        'reference': 'TEST_REF_$transactionId',
      });

      // Commit the batch
      await batch.commit();

      print('✅ Test withdrawal transaction committed successfully');
      print('📊 Transaction ID: $transactionId');

      return {
        'valid': true,
        'message': 'Withdrawal transaction processed successfully',
        'transactionId': transactionId,
      };
    } catch (e) {
      return {'valid': false, 'error': 'Transaction processing failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _testDatabaseValidation(
    String transactionId,
    double amount,
    String method,
  ) async {
    try {
      print('🔍 Testing database validation...');

      // Check if transaction exists
      final transactionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (!transactionDoc.exists) {
        return {
          'valid': false,
          'error': 'Transaction record not found in database',
        };
      }

      final transactionData = transactionDoc.data()!;

      // Validate transaction data
      if (transactionData['amount'] != amount) {
        return {
          'valid': false,
          'error': 'Amount mismatch in transaction record',
        };
      }

      if (transactionData['type'] != 'Withdrawal') {
        return {'valid': false, 'error': 'Transaction type mismatch'};
      }

      if (transactionData['method'] != method) {
        return {
          'valid': false,
          'error': 'Method mismatch in transaction record',
        };
      }

      // Check savings record
      final savingsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('savings')
          .doc(transactionId)
          .get();

      if (!savingsDoc.exists) {
        return {
          'valid': false,
          'error': 'Savings record not found in database',
        };
      }

      final savingsData = savingsDoc.data()!;

      if (savingsData['amount'] != -amount) {
        return {
          'valid': false,
          'error': 'Savings amount mismatch (should be negative)',
        };
      }

      return {'valid': true, 'message': 'Database validation passed'};
    } catch (e) {
      return {'valid': false, 'error': 'Database validation failed: $e'};
    }
  }

  Future<Map<String, dynamic>> _testBalanceUpdate(double amount) async {
    try {
      print('🔍 Testing balance update...');

      // Reload current savings
      await _loadCurrentSavings();

      // Calculate expected balance
      final expectedBalance = _currentSavings - amount;

      // Get actual balance from database
      final savingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('savings')
          .get();

      double actualBalance = 0;
      for (var doc in savingsSnapshot.docs) {
        final docAmount = doc['amount']?.toDouble() ?? 0;
        actualBalance += docAmount;
      }

      print('💰 Expected balance: $expectedBalance');
      print('💰 Actual balance: $actualBalance');

      if ((expectedBalance - actualBalance).abs() > 0.01) {
        return {
          'valid': false,
          'error':
              'Balance mismatch. Expected: $expectedBalance, Actual: $actualBalance',
        };
      }

      return {'valid': true, 'message': 'Balance updated correctly'};
    } catch (e) {
      return {'valid': false, 'error': 'Balance update test failed: $e'};
    }
  }

  void _addTestResult(String testName, bool passed, String message) {
    final result = {
      'testName': testName,
      'passed': passed,
      'message': message,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _testHistory.add(result);
      _lastTestResult = result;
    });

    print('${passed ? '✅' : '❌'} $testName: $message');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatCurrency(double amount) {
    return 'UGX ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Withdrawal Test',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF007C91),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  100, // Account for AppBar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20), // Reduced from 24
                _buildTestForm(),
                const SizedBox(height: 20), // Reduced from 24
                _buildCurrentBalance(),
                const SizedBox(height: 20), // Reduced from 24
                Flexible(child: _buildTestResults()),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007C91), Color(0xFF005A6B)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced from 12
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science,
                  color: Colors.white,
                  size: 22,
                ), // Reduced from 24
              ),
              const SizedBox(width: 12), // Reduced from 16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Withdrawal Method Test',
                      style: GoogleFonts.poppins(
                        fontSize: 18, // Reduced from 20
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Comprehensive withdrawal functionality testing',
                      style: GoogleFonts.poppins(
                        fontSize: 13, // Reduced from 14
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestForm() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Parameters',
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (UGX)',
              prefixText: 'UGX ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixText: '+256 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            decoration: InputDecoration(
              labelText: 'Withdrawal Method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['MTN MoMo', 'Airtel Money', 'Bank Transfer']
                .map(
                  (method) =>
                      DropdownMenuItem(value: method, child: Text(method)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedMethod = value!;
              });
            },
          ),
          const SizedBox(height: 20), // Reduced from 24
          SizedBox(
            width: double.infinity,
            height: 48, // Reduced from 50
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testWithdrawal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007C91),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Run Withdrawal Test',
                      style: GoogleFonts.poppins(
                        fontSize: 15, // Reduced from 16
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBalance() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          Container(
            padding: const EdgeInsets.all(14), // Reduced from 16
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue[600]),
                const SizedBox(width: 10), // Reduced from 12
                Text(
                  _formatCurrency(_currentSavings),
                  style: GoogleFonts.poppins(
                    fontSize: 22, // Reduced from 24
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16), // Reduced from 20
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No test results yet. Run a test to see results.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ), // Reduced from 16
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Results',
            style: GoogleFonts.poppins(
              fontSize: 16, // Reduced from 18
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12), // Reduced from 16
          ..._testHistory.map((result) => _buildTestResultItem(result)),
        ],
      ),
    );
  }

  Widget _buildTestResultItem(Map<String, dynamic> result) {
    final testName = result['testName'] as String;
    final passed = result['passed'] as bool;
    final message = result['message'] as String;
    final timestamp = result['timestamp'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
      padding: const EdgeInsets.all(12), // Reduced from 16
      decoration: BoxDecoration(
        color: passed ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passed ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.error,
                color: passed ? Colors.green : Colors.red,
                size: 18, // Reduced from 20
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  testName,
                  style: GoogleFonts.poppins(
                    fontSize: 14, // Reduced from 16
                    fontWeight: FontWeight.w600,
                    color: passed ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ), // Reduced from 8,4
                decoration: BoxDecoration(
                  color: passed ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8), // Reduced from 12
                ),
                child: Text(
                  passed ? 'PASS' : 'FAIL',
                  style: GoogleFonts.poppins(
                    fontSize: 9, // Reduced from 10
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced from 8
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
            ), // Reduced from 14
          ),
          const SizedBox(height: 2), // Reduced from 4
          Text(
            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ), // Reduced from 12
          ),
        ],
      ),
    );
  }
}
