import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoanApprovalPage extends StatefulWidget {
  final DocumentReference loanRef;
  final Map<String, dynamic> loanData;

  const LoanApprovalPage({
    super.key,
    required this.loanRef,
    required this.loanData,
  });

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  String? _decision;
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get isLocked {
    final status = widget.loanData['status']?.toString().toLowerCase() ?? '';
    return status == 'approved' || status == 'rejected';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateLoanStatus({
    required String status,
    required String notes,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final decisionBy = FirebaseAuth.instance.currentUser?.uid ?? 'admin';

    try {
      await widget.loanRef.update({
        'status': status,
        'decisionDate': FieldValue.serverTimestamp(),
        'decisionBy': decisionBy,
        'notes': notes,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan $status successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value is Timestamp
                  ? DateFormat('MMM d, yyyy').format(value.toDate())
                  : value.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDecision() async {
    if (_decision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a decision'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _updateLoanStatus(
      status: _decision!,
      notes: _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.loanData;
    final loanStatus = (data['status'] ?? '').toString();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application Review'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColorDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInfoCard('Loan Details', [
                _buildInfoRow(
                  'Amount',
                  '\$${data['amount']?.toStringAsFixed(2)}',
                ),
                _buildInfoRow('Purpose', data['purpose'] ?? 'N/A'),
                _buildInfoRow('Type', data['type'] ?? 'N/A'),
                _buildInfoRow(
                  'Status',
                  loanStatus.isEmpty ? 'Pending' : loanStatus,
                ),
                _buildInfoRow(
                  'Application Date',
                  data['applicationDate'] ?? 'N/A',
                ),
              ]),

              _buildInfoCard('Payment Information', [
                _buildInfoRow(
                  'Interest Rate',
                  '${data['interestRate']?.toStringAsFixed(2)}%',
                ),
                _buildInfoRow(
                  'Monthly Payment',
                  '\$${data['monthlyPayment']?.toStringAsFixed(2)}',
                ),
                _buildInfoRow(
                  'Total Repayment',
                  '\$${data['totalRepayment']?.toStringAsFixed(2)}',
                ),
                _buildInfoRow(
                  'Remaining Balance',
                  '\$${data['remainingBalance']?.toStringAsFixed(2)}',
                ),
                _buildInfoRow(
                  'Disbursement Date',
                  data['disbursementDate'] ?? 'N/A',
                ),
                _buildInfoRow('Due Date', data['dueDate'] ?? 'N/A'),
              ]),

              _buildInfoCard('Decision', [
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          loanStatus.toLowerCase() == 'approved'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: loanStatus.toLowerCase() == 'approved'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This loan has already been $loanStatus.\nDecision cannot be changed.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Decision',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        value: _decision,
                        onChanged: (value) {
                          setState(() {
                            _decision = value;
                          });
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'Approved',
                            child: Text('Approve'),
                          ),
                          DropdownMenuItem(
                            value: 'Rejected',
                            child: Text('Reject'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a decision';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitDecision,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SUBMIT DECISION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
