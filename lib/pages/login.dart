import 'package:flutter/material.dart';

import 'package:smartsacco/services/auth.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ADDED: Logger for debugging
  final _log = Logger('LoginPage');

  // ADDED: Form key for validation
  final _formKey = GlobalKey<FormState>();

  // ADDED: Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ADDED: Create instance of your Firebase Auth Service
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isPasswordObscured = true;
  // ADDED: Loading state for login process
  bool _isLoggingIn = false;

  // ADDED: Dispose controllers to prevent memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ADDED: Login method with Firebase authentication
  void _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields."),
        ),
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      // ADDED: Get values from controllers
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      // ADDED: Call your Firebase authentication method
      User? user = await _authService.loginWithEmailAndPassword(email, password);

      if (!mounted) return;

      if (user != null) {
        // ADDED: Login successful
        _log.info('Successfully logged in User: ${user.email} with UID: ${user.uid}');

        // ADDED: Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful!"),
            backgroundColor: Colors.green,
          ),
        );

        // EXISTING: Get user role from route arguments (if available)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

          final role = doc.data()?['role'];
        // EXISTING: Navigate based on role
        if (role == 'Admin') {
          Navigator.pushNamedAndRemoveUntil(
              context, '/admin-dashboard', (route) => false);        
        } else {
          Navigator.pushNamedAndRemoveUntil(
              context, '/member-dashboard', (route) => false);
        }
      } else {
        // ADDED: Login failed
        _log.warning('Login failed for email: $email');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login failed. Please check your credentials."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ADDED: Handle any errors
      if (!mounted) return;

      _log.warning('Login error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // ADDED: Always stop loading state
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF007C91),
        title: const Text(
          "Login",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // ADDED: Wrap with Form for validation
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress, 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // UPDATED: Added controller and validation
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
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
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // UPDATED: Changed onPressed to call _login method and handle loading state
                    onPressed: _isLoggingIn ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007C91),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // UPDATED: Show loading indicator when logging in
                    child: _isLoggingIn
                        ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Note: Your account must be verified by an admin before you can log in.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgotpassword');
                  },
                  child: const Text(
                    "Forgotten PIN Password? Tap here",
                    style: TextStyle(color: Color(0xFF007C91)),
                  ),
                ),
                TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                        "Don't have an account? Register",
                        style: TextStyle(color: Color(0xFF007C91),
                        )
                    )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}