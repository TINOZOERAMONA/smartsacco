import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF007C91),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Welcome!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007C91),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Track your SACCO savings\nfrom anywhere, anytime.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007C91),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007C91),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
