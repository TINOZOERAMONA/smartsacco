import 'package:flutter/material.dart';
import 'package:smartsacco/services/user_preferences_service.dart';
import 'package:smartsacco/utils/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserPreferencesService _prefsService = UserPreferencesService();

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
                    ),
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
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF007C91),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
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
                          horizontal: 40,
                          vertical: 14,
                        ),
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        _showAccessibilityOptions(context);
                      },
                      child: const Text(
                        "Accessibility Options",
                        style: TextStyle(color: Colors.black87, fontSize: 16),
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

  void _showAccessibilityOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accessibility Options'),
        content: const Text(
          'Choose your preferred interaction mode. You can change this later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setAccessibilityMode(AccessibilityModes.normal);
            },
            child: const Text('Normal Mode'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setAccessibilityMode(AccessibilityModes.voice);
            },
            child: const Text('Voice Mode'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setAccessibilityMode(AccessibilityModes.blind);
            },
            child: const Text('Blind Mode'),
          ),
        ],
      ),
    );
  }

  Future<void> _setAccessibilityMode(String mode) async {
    await _prefsService.setAccessibilityMode(mode);

    if (mode != AccessibilityModes.normal) {
      await _prefsService.setVoiceEnabled(true);
      await _prefsService.setAutoStartVoice(true);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accessibility mode set to: $mode'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
