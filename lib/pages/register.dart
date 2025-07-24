// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:smartsacco/pages/emailverification_page.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Member';

  bool _isRegistering = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields.")),
        );
      }
      return;
    }

    try {
      setState(() => _isRegistering = true);

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        await user.updateDisplayName(_fullNameController.text.trim());

        // ✅ Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'pin': _passwordController.text.trim(),
          'role': _selectedRole.toLowerCase(),
          'registrationMethod': 'form',
          'createdAt': Timestamp.now(),
        });

        _log.info(
          'Successfully registered User: ${_fullNameController.text.trim()} as $_selectedRole with UID: ${user.uid}',
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              userEmail: _emailController.text.trim(),
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
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF007C91), Color(0xFF005A6B)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Logo/Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Join SmartSacco',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 28 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account to get started',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Form Section
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                            // Full Name Field
                            _buildTextField(
                              _fullNameController,
                              "Full Names",
                              Icons.person_outline,
                            ),

                            const SizedBox(height: 20),

                            // Email Field
              _buildTextField(
                _emailController,
                              'Email Address',
                              Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

                            const SizedBox(height: 20),

                            // Phone Field
              _buildTextField(
                _phoneController,
                              'Phone Number',
                              Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                              helperText: 'Format: 0760500677',
                            ),

                            const SizedBox(height: 20),

                            // Password Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                controller: _passwordController,
                                obscureText: _isPasswordObscured,
                                style: GoogleFonts.poppins(fontSize: 16),
                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  helperText:
                                      'Password must be at least 6 characters',
                                  helperStyle: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outlined,
                                    color: const Color(0xFF007C91),
                                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                                      color: const Color(0xFF007C91),
                    ),
                    onPressed: () {
                      setState(() {
                                        _isPasswordObscured =
                                            !_isPasswordObscured;
                      });
                    },
                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
                            ),

                            const SizedBox(height: 20),

                            // Role Selection
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                                style: GoogleFonts.poppins(fontSize: 16),
                                decoration: InputDecoration(
                  labelText: 'Role',
                                  labelStyle: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.work_outline,
                                    color: const Color(0xFF007C91),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                ),
                items: <String>['Member', 'Admin']
                                    .map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                  return DropdownMenuItem<String>(
                    value: value,
                                        child: Text(
                                          value,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
                            ),

                            const SizedBox(height: 32),

                            // Register Button
                            Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF007C91),
                                    Color(0xFF005A6B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF007C91,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                onPressed: _isRegistering ? null : _register,
                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                  child: _isRegistering
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Create Account",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Info Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "After registration, you'll need to verify your email and wait for admin approval.",
                                      style: GoogleFonts.poppins(
                                        color: Colors.green[800],
                                        fontSize: 12,
                        ),
                ),
              ),
            ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  child: Text(
                                    "Sign In",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF007C91),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        helperText: helperText,
          helperStyle: GoogleFonts.poppins(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF007C91)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
          if (label == 'Email Address') {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }
          if (label == 'Phone Number') {
          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
            return 'Please enter a valid 10-digit phone number';
          }
        }
        return null;
      },
      ),
    );
  }
}
