import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartsacco/pages/loan.dart';

class LoanDueCard extends StatelessWidget {
  final Loan loan;
  final String Function(double) formatCurrency;
  final Color Function(String) getStatusColor;
  final Function(Loan) onPaymentPressed;
  final Color textPrimary;
  final Color textSecondary;
  final Color primaryColor;
  final Color dangerColor;

  const LoanDueCard({
    required this.loan,
    required this.formatCurrency,
    required this.getStatusColor,
    required this.onPaymentPressed,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryColor,
    required this.dangerColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = loan.status == 'Overdue';
    final nextPaymentDate = loan.payments.isEmpty
        ? loan.disbursementDate?.add(const Duration(days: 30)) ?? DateTime.now()
        : loan.payments.last.date.add(const Duration(days: 30));
    final daysRemaining = nextPaymentDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? dangerColor.withOpacity(0.05)
            : primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue ? dangerColor : primaryColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loan #${loan.id.substring(0, 8)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue
                      ? dangerColor.withOpacity(0.1)
                      : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverdue ? 'Overdue' : 'Active',
                  style: GoogleFonts.poppins(
                    color: isOverdue ? dangerColor : primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLoanDetailRow('Amount:', formatCurrency(loan.amount)),
          _buildLoanDetailRow(
            'Next Payment:',
            formatCurrency(loan.nextPaymentAmount),
          ),
          _buildLoanDetailRow(
            'Due Date:',
            '${DateFormat('MMM d, y').format(nextPaymentDate)} '
                '(${isOverdue ? '${-daysRemaining} days overdue' : 'in $daysRemaining days'})',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onPaymentPressed(loan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverdue ? dangerColor : primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Make Payment',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}