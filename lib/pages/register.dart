// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:smartsacco/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartsacco/pages/emailverification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterSaccoPageState();
}

class _RegisterSaccoPageState extends State<RegisterPage> {
  final _log = Logger('RegisterSaccoPage');
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Member';

  bool _isRegistering = false;
  bool _isPasswordObscured = true;

  // ignore: unused_field
  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Updated registration method based on the new code you provided
  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill all required fields."),
          ),
        );
      }
      return;
    }

    try {
      // Show loading indicator
      setState(() => _isRegistering = true);

      // Create user with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update display name with full name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_fullNameController.text.trim());
      }

      _log.info('Successfully registered User: ${_fullNameController.text.trim()} as $_selectedRole with UID: ${userCredential.user?.uid}');

      // IMPORTANT: Navigate to verification screen instead of going back
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              userEmail: _emailController.text.trim(),
              // You can also pass additional data if needed
              // role: _selectedRole,
              // fullName: _fullNameController.text.trim(),
            ),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register SACCO'),
        backgroundColor: const Color(0xFF007C91),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              _buildTextField(_fullNameController, "Full Names"),
              const SizedBox(height: 12),
              _buildTextField(
                _emailController,
                'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                  keyboardType: TextInputType.text,
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Pin Password',
                    border: const OutlineInputBorder(),
                    helperText: 'Password must be at least 6 digits',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                    ),
                  ),
                  obscureText: _isPasswordObscured,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a pin password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  }
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: <String>['Member', 'Admin']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007C91),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Semantics(
                  label: _isRegistering
                      ? "Registering, please wait"
                      : "Register SACCO",
                  child: _isRegistering
                      ? const CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    "Register SACCO",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, String? helperText}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        // Add email validation
        if (label == 'Email') {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }
        return null;
      },
    );
  }
}
