import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoanApprovalPage extends StatefulWidget {
  final DocumentReference loanRef;
  final Map<String, dynamic> loanData;

  const LoanApprovalPage({
    Key? key,
    required this.loanRef,
    required this.loanData,
  }) : super(key: key);

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  String? _decision;
  final TextEditingController _notesController = TextEditingController();

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
    final decisionBy = FirebaseAuth.instance.currentUser?.uid ?? 'admin';

    try {
      await widget.loanRef.update({
        'status': status,
        'decisionDate': FieldValue.serverTimestamp(),
        'decisionBy': decisionBy,
        'notes': notes,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loan status updated to $status')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value is Timestamp
                  ? DateFormat('yyyy-MM-dd').format(value.toDate())
                  : value.toString(),
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDecision() async {
    if (_decision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a decision')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Application Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildInfoRow('Amount', '${data['amount']}'),
            _buildInfoRow('Purpose', data['purpose']),
            _buildInfoRow('Loan Type', data['type']),
            _buildInfoRow('Status', loanStatus),
            _buildInfoRow('Application Date', data['applicationDate']),
            _buildInfoRow('Disbursement Date', data['disbursementDate']),
            _buildInfoRow('Due Date', data['dueDate']),
            _buildInfoRow('Interest Rate', '${data['interestRate']}%'),
            _buildInfoRow('Monthly Payment', '${data['monthlyPayment']}'),
            _buildInfoRow('Total Repayment', '${data['totalRepayment']}'),
            _buildInfoRow('Remaining Balance', '${data['remainingBalance']}'),

            const SizedBox(height: 20),
            const Text(
              'Decision',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  'This loan has already been $loanStatus.\nDecision cannot be changed.',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            else
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select Decision'),
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
              ),

            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              enabled: !isLocked,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLocked ? null : _submitDecision,
              child: const Text('Submit Decision'),
            ),
          ],
        ),
      ),
    );
  }
}
