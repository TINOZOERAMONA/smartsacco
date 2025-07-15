import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SavingsItem extends StatelessWidget {
  final dynamic saving;
  final String Function(double) formatCurrency;
  final Color textSecondary;
  final Color successColor;

  const SavingsItem({
    required this.saving,
    required this.formatCurrency,
    required this.textSecondary,
    required this.successColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_downward, color: successColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${formatCurrency(saving.amount)} • ${DateFormat('MMM d, y').format(saving.date)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: const Text('Completed'),
            backgroundColor: successColor.withOpacity(0.2),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: successColor,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}