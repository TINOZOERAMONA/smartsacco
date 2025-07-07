// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:smartsacco/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

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


  final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  void _register() async {
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

    setState(() {
      _isRegistering = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text;
      String fullName = _fullNameController.text.trim();


      User? user = await _authService.registerWithEmailAndPassword(email, password);

      if (!mounted) return;

      if (user != null) {

        _log.info('Successfully registered User: $fullName as $_selectedRole with UID: ${user.uid}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful!"),
            backgroundColor: Colors.green,
          ),
        );


        try {
          await user.updateDisplayName(fullName);
        } catch (e) {
          _log.warning('Failed to update display name: $e');
        }


        const verificationCode = '123456'; // Mock code
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/verification',
              (route) => false,
          arguments: {
            'code': verificationCode,
            'role': _selectedRole,
            'user': user, // ADDED: Pass the user object
          },
        );
      } else {
        _log.warning('Registration failed for email: $email');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {

      if (!mounted) return;

      _log.warning('Registration error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {

      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
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
                keyboardType: TextInputType.phone,
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'PIN Password',
                  border: const OutlineInputBorder(),
                  helperText: 'PIN must be atleast 4 characters',
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
                    return 'Please enter a PIN password';
                  }
                  if (value.length < 4) {
                    return 'PIN Password must be at least 4 characters';
                  }
                  return null;
                },
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
      validator: (value) =>
      value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }
}