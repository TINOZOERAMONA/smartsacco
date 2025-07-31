// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:smartsacco/models/depositmodel.dart';



// display user's deposit history
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Deposit> _deposits = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController(); //controller for search field

  @override
  void initState() {
    super.initState();
    _loadDeposits(); //loads deposit when widget initializes
  }

  // Loads deposit history from backend
  Future<void> _loadDeposits() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));


      // Mock data - in a real app this would come from an API
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
        _isLoading = false; // Loading complete
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load deposits: ${e.toString()}';
        _isLoading = false;  
      });
    }
  }

  /// Shows a dialog to initiate a new mobile money payment
  Future<void> _initiateMomoPayment(BuildContext context) async {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();

   // Show payment dialog
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
           // Cancel button
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

      // If user proceeded with payment
     if (result == true) {
      final amount = double.parse(amountController.text);
      final phone = phoneController.text;

      // Simulate payment processing
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));

     // Create new deposit record
      final newDeposit = Deposit(
        id: 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        date: DateTime.now(),
        method: 'Mobile Money',
        status: 'Pending',
        reference: 'MM-${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phone,
      );

    // Add to beginning of list (most recent first)
      setState(() {
        _deposits.insert(0, newDeposit);
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment initiated successfully!')),
      );
    }
  }

  
  /// Filters deposits based on search query
  List<Deposit> get _filteredDeposits {
    if (_searchController.text.isEmpty) return _deposits;
    return _deposits.where((deposit) {
      return deposit.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          deposit.reference.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (deposit.phoneNumber?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false) ||
          deposit.amount.toString().contains(_searchController.text);
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeposits,
          ),
        ],
      ),

      // Floating action button for new deposits
      floatingActionButton: FloatingActionButton(
        onPressed: () => _initiateMomoPayment(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search deposits',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {}), // Rebuild on search text change
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  
  /// Builds the appropriate body content based on current state
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeposits,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredDeposits.isEmpty) {
      return const Center(child: Text('No deposits found'));
    }

    // Deposit list view
    return ListView.builder(
      itemCount: _filteredDeposits.length,
      itemBuilder: (context, index) {
        final deposit = _filteredDeposits[index];
        return _buildDepositCard(deposit);
      },
    );
  }

  
  
   /// Builds a card widget for a single deposit
  Widget _buildDepositCard(Deposit deposit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showDepositDetails(deposit),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    deposit.getAmountText(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: deposit.getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      deposit.status.toUpperCase(),
                      style: TextStyle(
                        color: deposit.getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Method: ${deposit.method}'),
              const SizedBox(height: 4),
              Text('Date: ${deposit.getFormattedDate()}'),
              if (deposit.phoneNumber != null) ...[
                const SizedBox(height: 4),
                Text('Phone: ${deposit.phoneNumber}'),
              ],
            ],
          ),
        ),
      ),
    );
  }

 /// Shows a bottom sheet with detailed deposit information
  void _showDepositDetails(Deposit deposit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Deposit Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Deposit ID:', deposit.id),
              _buildDetailRow('Amount:', deposit.getAmountText()),
              _buildDetailRow('Status:', deposit.status),
              _buildDetailRow('Method:', deposit.method),
              _buildDetailRow('Date:', deposit.getFormattedDate()),
              if (deposit.phoneNumber != null)
                _buildDetailRow('Phone:', deposit.phoneNumber!),
              _buildDetailRow('Reference:', deposit.reference),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

   /// Helper method to build a consistent detail row with label and value
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}






















