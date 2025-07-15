import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                if (title == 'Savings' || title == 'Total Due')
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (title != 'Savings' && title != 'Total Due')
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}