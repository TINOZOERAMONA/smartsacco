import 'package:flutter/material.dart';
import 'package:smartsacco/pages/newpassword.dart';

class VerifyOtpPage extends StatelessWidget {
  final String phoneNumber;

  const VerifyOtpPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Color(0xFF007C91),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter the OTP sent to:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              phoneNumber,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder:(context)=> NewPasswordPage()

                    )
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF007C91),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                  "Verify",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
