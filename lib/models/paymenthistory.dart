import 'package:flutter/material.dart';
import 'package:smartloan_sacco/models/deposit_model.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Deposit> _deposits = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _deposits = [
          Deposit(
            id: 'DEP-${DateTime.now().millisecondsSinceEpoch}',
            amount: 100000,
            date: DateTime.now().subtract(const Duration(days: 1)),
            method: 'Mobile Money',
            status: 'Completed',
            reference: 'MM-REF-12345',
            phoneNumber: '256775123456',
          ),
          Deposit(
            id: 'DEP-${DateTime.now().millisecondsSinceEpoch + 1}',
            amount: 50000,
            date: DateTime.now().subtract(const Duration(days: 3)),
            method: 'Bank Transfer',
            status: 'Pending',
            reference: 'BANK-REF-67890',
          ),
          Deposit(
            id: 'DEP-${DateTime.now().millisecondsSinceEpoch + 2}',
            amount: 200000,
            date: DateTime.now().subtract(const Duration(days: 5)),
            method: 'Mobile Money',
            status: 'Failed',
            reference: 'MM-REF-54321',
            phoneNumber: '256772987654',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load deposits: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  Future<void> _initiateMomoPayment(BuildContext context) async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mobile Money Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (UGX)',
                prefixText: 'UGX ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter amount';
                final amount = double.tryParse(value) ?? 0;
                if (amount <= 0) return 'Amount must be positive';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '256XXXXXXXXX',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter phone number';
                if (!value.startsWith('256') || value.length != 12) {
                  return 'Enter valid UG number (256XXXXXXXXX)';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isEmpty || phoneController.text.isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
     if (result == true) {
      final amount = double.parse(amountController.text);
      final phone = phoneController.text;

      // Simulate payment processing
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));

      final newDeposit = Deposit(
        id: 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        date: DateTime.now(),
        method: 'Mobile Money',
        status: 'Pending',
        reference: 'MM-${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phone,
      );

      setState(() {
        _deposits.insert(0, newDeposit);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment initiated successfully!')),
      );
    }
  }

  List<Deposit> get _filteredDeposits {
    if (_searchController.text.isEmpty) return _deposits;
    return _deposits.where((deposit) {
      return deposit.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          deposit.reference.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (deposit.phoneNumber?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
          deposit.amount.toString().contains(_searchController.text);
    }).toList();
  }




