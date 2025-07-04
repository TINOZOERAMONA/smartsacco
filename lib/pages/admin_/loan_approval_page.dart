import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoanApprovalPage extends StatefulWidget {
  final String loanId;
  final Map<String, dynamic> loanData;

  const LoanApprovalPage({
    Key? key,
    required this.loanId,
    required this.loanData,
  }) : super(key: key);

  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  String? _decision;
  String _notes = '';
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat.yMMMMd().add_jm();

  @override
  Widget build(BuildContext context) {
    final loan = widget.loanData;

    final memberName = loan['memberName'] ?? 'Unknown';
    final amount = loan['amount']?.toString() ?? '0';
    final rawDate = loan['applicationDate'];
    String formattedDate = 'Unknown';

    if (rawDate is Timestamp) {
      formattedDate = _dateFormat.format(rawDate.toDate());
    } else if (rawDate is String) {
      formattedDate = rawDate;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Approval'),
        centerTitle: true,
        backgroundColor: Colors.teal.shade600,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoTile('Loan ID', widget.loanId),
                        _infoTile('Member Name', memberName),
                        _infoTile('Amount Requested', 'UGX $amount'),
                        _infoTile('Date Applied', formattedDate),
                        const SizedBox(height: 20),
                        const Divider(),
                        const Text(
                          'Admin Decision',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Radio<String>(
                              value: 'approved',
                              groupValue: _decision,
                              onChanged: (val) => setState(() => _decision = val),
                            ),
                            const Text('Approve'),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: 'rejected',
                              groupValue: _decision,
                              onChanged: (val) => setState(() => _decision = val),
                            ),
                            const Text('Reject'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onChanged: (val) => _notes = val,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _loading ? null : _submitDecision,
                            icon: const Icon(Icons.send),
                            label: Text(
                              _loading ? 'Submitting...' : 'Submit Decision',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDecision() async {
    if (_decision == null) {
      _showMessage('Please select a decision');
      return;
    }

    setState(() => _loading = true);

    try {
      await _updateLoanStatus(
        loanId: widget.loanId,
        status: _decision!,
        notes: _notes.trim(),
      );

      if (!mounted) return;
      _showMessage('Loan successfully $_decision');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Error: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateLoanStatus({
    required String loanId,
    required String status,
    required String notes,
  }) async {
    final loanRef = FirebaseFirestore.instance.collection('loans').doc(loanId);
    final docSnapshot = await loanRef.get();

    if (!docSnapshot.exists) {
      throw Exception("Loan record not found.");
    }

    final decisionBy = FirebaseAuth.instance.currentUser?.uid ?? 'admin_placeholder';

    await loanRef.update({
      'status': status,
      'decisionDate': FieldValue.serverTimestamp(),
      'decisionBy': decisionBy,
      'notes': notes,
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
