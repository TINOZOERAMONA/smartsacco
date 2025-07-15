import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderSection extends StatelessWidget {
  final String memberName;
  final String memberEmail;
  final String memberPhone;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;

  const HeaderSection({
    required this.memberName,
    required this.memberEmail,
    required this.memberPhone,
    required this.primaryColor,
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, size: 30, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $memberName',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    memberEmail,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  if (memberPhone.isNotEmpty)
                    Text(
                      memberPhone,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}