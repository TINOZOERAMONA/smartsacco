// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';







final _logger = Logger('VoiceRegisterPage');
class VoiceRegisterPage extends StatefulWidget {
  const VoiceRegisterPage({super.key});

  @override
  State<VoiceRegisterPage> createState() => _VoiceRegisterPageState();
}

class _VoiceRegisterPageState extends State<VoiceRegisterPage>
    with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String spokenText = "";
  bool isCreatingAccount = false;
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Registration data
  String fullName = "";
  String email = "";
  String phone = "";
  String pin = "";
  String confirmPin = "";
  String role = "";
  
  // Registration steps
  int currentStep = 0;
  bool isConfirming = false;
  String tempValue = "";
  
  List<String> steps = [
    "full_name",
    "email",
    "phone",
    "pin",
    "confirm_pin",
    "role",
    "final_confirm"
  ];
  
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTTS();
    _startRegistrationProcess();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);


    flutterTts.setCompletionHandler(() {
      if (mounted && !isListening) {
        _startListening();
      }
    });
  }

  Future<void> _startRegistrationProcess() async {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    
    await Future.delayed(Duration(seconds: 1));
    await _speakCurrentStep();
  }

  Future<void> _speakCurrentStep() async {
    String message = "";
    
    if (isConfirming) {
      switch (steps[currentStep]) {
        case "full_name":
          message = "Thank you. Please confirm, did you say your name is $tempValue? Say yes to confirm or no to try again.";
          break;
        case "email":
          message = "Thank you. Please confirm, did you say your email is $tempValue? Say yes to confirm or no to try again.";
          break;
        case "phone":
          message = "Thank you. Please confirm, did you say ${_speakDigits(tempValue)}? Say yes to confirm or no to try again.";
          break;
        case "pin":
          message = "Thank you. Please confirm, did you say your PIN is ${_speakDigits(tempValue)}? Say yes to confirm or no to try again.";
          break;
        case "confirm_pin":
          message = "Thank you. Please confirm, did you say your PIN confirmation is ${_speakDigits(tempValue)}? Say yes to confirm or no to try again.";
          break;
        case "role":
          message = "Thank you. Please confirm, did you say your role is $tempValue? Say yes to confirm or no to try again.";
          break;
      }
    } else {
      switch (steps[currentStep]) {
        case "full_name":
          message = "Welcome to registration! Please spell your full name one letter at a time ao i can get it clearly.";
          break;
        case "email":
          message = "Great! Now please say your email address. Speak slowly and clearly. For example, say 'john at gmail dot com' for john@gmail.com";
          break;
        case "phone":
          message = "Now please say your phone number digit by digit. For example, say 'zero seven six zero three four five six seven eight' for 0760345678.";
          break;
        case "pin":
          message = "Now please say your 6-digit PIN. This will be used for quick access.";
          break;
        case "confirm_pin":
          message = "Please say your 6-digit PIN again to confirm it.";
          break;
        case "role":
          message = "Finally, please say your role. Say 'member' if you are a member, or say 'admin' if you are an administrator.";
          break;
        case "final_confirm":
          message = "Let me read back all your details for final confirmation. Full name: $fullName. Email: $email.Phone number: ${_speakDigits(phone)} PIN: $pin. Role: $role. Say 'yes' to confirm everything, or say 'no' to make changes.";
          break;
      }
    }

    //try {
      await flutterTts.speak(message);
      
    //   Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
    //     if (mounted) {
    //       _startListening();
    //     }
    //   });
    // } catch (e) {
    //   _logger.warning("TTS Error: $e");
    //   Future.delayed(Duration(seconds: 2), () {
    //     if (mounted) {
    //       _startListening();
    //     }
    //   });
    //}
  }

  Future<void> _startListening() async {
    try {
      await speech.stop();
    } catch (e) {
      _logger.warning("Error stopping speech: $e");
    }

    bool available = await speech.initialize(
      onStatus: (val) {
        _logger.info("Speech status: $val");
        if (mounted) {
          setState(() {
            isListening = val == 'listening';
          });
          
          if (val == 'notListening' && spokenText.isEmpty) {
            Future.delayed(Duration(seconds: 1), () {
              if (mounted && !isListening) {
                _startListening();
              }
            });
          }
        }
      },
      onError: (val) {
        _logger.warning("Speech error: $val");
        if (mounted) {
          setState(() {
            isListening = false;
          });
          _showError("Sorry, I didn't catch that. Let me try again.");
        }
      },
    );

    if (available) {
      if (mounted) {
        setState(() {
          isListening = true;
          spokenText = "";
        });
      }
      
      speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              spokenText = val.recognizedWords;
            });

            if (val.finalResult) {
              speech.stop();
              _processSpokenInput(val.recognizedWords);
            }
          }
        },
        listenFor: Duration(seconds: 20),
        pauseFor: Duration(seconds: 8),
        partialResults: true,
      );
    } else {
      _showError("Speech recognition not available. Please try again.");
    }
  }

  void _processSpokenInput(String input) {
    setState(() {
      isListening = false;
    });

    if (isConfirming) {
      _processConfirmation(input);
    } else {
      switch (steps[currentStep]) {
        case "full_name":
          _processFullName(input);
          break;
        case "email":
          _processEmail(input);
          break;
        case "phone":
          _processPhone(input);
          break;
        case "pin":
          _processPin(input);
          break;
        case "confirm_pin":
          _processConfirmPin(input);
          break;
        case "role":
          _processRole(input);
          break;
        case "final_confirm":
          _processFinalConfirmation(input);
          break;
      }
    }
  }

  void _processFullName(String input) {
    String formatted = _processSpokenSpelling(input);

    if (formatted.length >= 3) {
      tempValue = formatted;

      setState(() {
        isConfirming = true;
      });

      _speakCurrentStep();
    } else {
      _askAgain("I couldn't understand your name. Please spell your full name again, and say 'space' between names.");
    }
  }

  String _processSpokenSpelling(String input) {
    String cleaned = input.toLowerCase()
      .replaceAll('space', '|')                // spoken "space"
      .replaceAll(RegExp(r'[^a-z| ]'), '')     // allow letters, pipes, and spaces
      .replaceAll(RegExp(r'\s+'), ' ')         // collapse extra spaces
      .trim();

    List<String> nameParts = cleaned.split('|');

    List<String> combinedNames = nameParts.map((part) {
      String combined = part.replaceAll(' ', ''); // remove intra-name spaces
      if (combined.isEmpty) return '';
      return combined[0].toUpperCase() + combined.substring(1);
    }).toList();

    return combinedNames.join(' ');
  }


  
  


  void _processEmail(String input) {
    String cleanInput = _convertSpokenEmailToText(input);
    
    if (cleanInput.contains('@') && cleanInput.contains('.')) {
      tempValue = cleanInput;
      setState(() {
        isConfirming = true;
      });
      _speakCurrentStep();
    } else {
      _askAgain("That doesn't sound like a valid email address. Please say your email again. For example, say 'john at gmail dot com' for john@gmail.com");
    }
  }

  String _convertSpokenEmailToText(String input) {
    String converted = input.toLowerCase().trim();

    // Replace common spoken symbols
    converted = converted.replaceAll(RegExp(r'\bat\b'), '@');
    converted = converted.replaceAll(RegExp(r'\bdot\b'), '.');

    // Remove all spaces to combine the spelled-out characters
    converted = converted.replaceAll(RegExp(r'\s+'), '');

    return converted;
  }


  void _processPhone(String input) {
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length >= 9 && digits.length <= 12) {
      tempValue = digits;
      setState(() {
        isConfirming = true;
      });
      _speakCurrentStep();
    } else {
      _askAgain("That doesn't seem like a valid phone number. Please say your phone number digit by digit.");
    }
  }


  void _processPin(String input) {
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 6) {
      tempValue = digits;
      setState(() {
        isConfirming = true;
      });
      _speakCurrentStep();
    } else {
      _askAgain("Please say exactly 6 digits for your PIN.");
    }
  }

  void _processConfirmPin(String input) {
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 6) {
      tempValue = digits;
      setState(() {
        isConfirming = true;
      });
      _speakCurrentStep();
    } else {
      _askAgain("Please say exactly 6 digits to confirm your PIN.");
    }
  }

  void _processRole(String input) {
    String lowerInput = input.toLowerCase();
    if (lowerInput.contains('member')) {
      tempValue = "member";
      setState(() {
        isConfirming = true;
      });
      _speakCurrentStep();
    } else if (lowerInput.contains('admin')) {
      tempValue = "admin";
      setState(() {
        isConfirming = true;
      });
      _speakCurrentStep();
    } else {
      _askAgain("Please say either 'member' or 'admin' for your role.");
    }
  }

  void _processConfirmation(String input) {
    String lowerInput = input.toLowerCase();
    if (lowerInput.contains('yes')) {
      switch (steps[currentStep]) {
        case "full_name":
          fullName = tempValue;
          break;
        case "email":
          email = tempValue;
          break;
        case "phone":
          phone = tempValue;
          break;
        case "pin":
          pin = tempValue;
          break;
        case "confirm_pin":
          confirmPin = tempValue;
          if (pin != confirmPin) {
            _speakError("The PINs don't match. Let's try again.");
            setState(() {
              currentStep = 2;
              isConfirming = false;
              pin = "";
              confirmPin = "";
            });
            return;
          }
          break;
        case "role":
          role = tempValue;
          break;
      }
      
      setState(() {
        isConfirming = false;
        currentStep++;
      });
      _speakCurrentStep();
    } else if (lowerInput.contains('no')) {
      setState(() {
        isConfirming = false;
      });
      _askAgain("Please say your ${_getCurrentFieldName()} again.");
    } else {
      _askAgain("Please say 'yes' to confirm or 'no' to try again.");
    }
  }

  void _processFinalConfirmation(String input) {
    String lowerInput = input.toLowerCase();
    if (lowerInput.contains('yes')) {
      _completeRegistration();
    } else if (lowerInput.contains('no')) {
      _handleFinalConfirmationRejection();
    } else {
      _askAgain("Please say 'yes' to confirm everything or 'no' to make changes.");
    }
  }

  void _handleFinalConfirmationRejection() {
    String message = "Which detail would you like to change? Say 'one' to re-enter your full name, 'three' to re-enter your email,'four' to re-enter your Phone, 'five' to re-enter your PIN, or 'six' to re-enter your role.";
    
    flutterTts.speak(message);
    
    // Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
    //   if (mounted) {
    //     _startListening();
    //   }
    // });
  }

  String _getCurrentFieldName() {
    switch (steps[currentStep]) {
      case "full_name":
        return "full name";
      case "email":
        return "email address";
      case "phone":
        return "phone";
      case "pin":
        return "PIN";
      case "confirm_pin":
        return "PIN confirmation";
      case "role":
        return "role";
      default:
        return "information";
    }
  }

  void _askAgain(String message) {
    flutterTts.speak(message);
    
    // Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
    //   if (mounted) {
    //     _startListening();
    //   }
    // });
  }

  String _speakDigits(String number) {
    return number.split('').join(' ');
  }


  void _speakError(String message) {
    flutterTts.speak(message);
    
    // Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
    //   if (mounted) {
    //     _startListening();
    //   }
    // });
  }

  // Firebase Registration Method
  Future<void> _completeRegistration() async {
    setState(() {
      isCreatingAccount = true;
    });

    try {
      // Announce that account creation is starting
      await flutterTts.speak("Creating your account, please wait...");
      
      // Create a temporary password using email and PIN
      String temporaryPassword = "$pin${email.substring(0, 2)}Temp123!";
      
      // Create Firebase Auth user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: temporaryPassword,
      );

      // Update the user's display name
      await userCredential.user?.updateDisplayName(fullName);

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'pin': pin, 
        'createdAt': FieldValue.serverTimestamp(),
        'registrationMethod': 'voice',
        'uid': userCredential.user?.uid,
      });

      // Success message
      await flutterTts.speak("Registration successful! Your account has been created. Welcome to SmartSacco, $fullName!");
      
      // Navigate to dashboard page
      Future.delayed(Duration(seconds: 4), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/blindmember');
        }
      });

    } catch (e) {
      setState(() {
        isCreatingAccount = false;
      });
      
      String errorMessage = "Sorry, there was an error creating your account. ";
      
      // Handle specific Firebase errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage += "This email is already registered. Please use a different email.";
            break;
          case 'invalid-email':
            errorMessage += "The email address is not valid. Please try again.";
            break;
          case 'weak-password':
            errorMessage += "Please try again with a stronger password.";
            break;
          case 'network-request-failed':
            errorMessage += "Please check your internet connection and try again.";
            break;
          default:
            errorMessage += "Please try again later.";
        }
      } else {
        errorMessage += "Please try again later.";
      }
      
      await flutterTts.speak(errorMessage);
      
      // Option to try again
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          _askRetry();
        }
      });
    }
  }

  void _askRetry() {
    flutterTts.speak("Would you like to try creating your account again? Say 'yes' to retry or 'no' to go back to the beginning.");
    
    // Future.delayed(Duration(seconds: 5), () {
    //   if (mounted) {
    //     _startListening();
    //   }
    // });
  }

  void _showError(String message) {
    flutterTts.speak(message);
    // Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
    //   if (mounted) {
    //     _speakCurrentStep();
    //   }
    // });
  }

  String _getCurrentStepText() {
    if (isCreatingAccount) {
      return "Creating your account...";
    }
    
    if (isConfirming) {
      return "Confirming: ${_getCurrentFieldName()}";
    }
    
    switch (steps[currentStep]) {
      case "full_name":
        return "Say your full name";
      case "email":
        return "Say your email address";
      case "phone":
        return "Say your phone number";
      case "pin":
        return "Say your 6-digit PIN";
      case "confirm_pin":
        return "Confirm your PIN";
      case "role":
        return "Say 'member' or 'admin'";
      case "final_confirm":
        return "Final confirmation";
      default:
        return "Processing...";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isCreatingAccount ? Colors.orange.shade600 : Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isCreatingAccount ? Colors.orange.shade300 : Colors.green.shade300).withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isCreatingAccount ? Icons.cloud_upload : Icons.person_add,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 30),

            // Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                isCreatingAccount ? 'Creating Account' : 'Voice Registration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Step indicator
            if (!isCreatingAccount)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Step ${currentStep + 1} of ${steps.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 40),

            // Current step instruction
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getCurrentStepText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Listening indicator or loading
            if (isCreatingAccount)
              Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Setting up your account...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else if (isListening)
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 40,
                            color: Colors.red.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Listening... Speak clearly',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Icon(
                    Icons.voice_chat,
                    size: 40,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(height: 15),
                  Text(
                    isConfirming ? 'Ready to confirm' : 'Ready to listen',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 40),

            // Progress indicator
            if (!isCreatingAccount)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: (currentStep + 1) / steps.length,
                    backgroundColor: Colors.green.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                    minHeight: 8,
                  ),
                ),
              ),

            SizedBox(height: 20),

            // Show current values for debugging
            if (fullName.isNotEmpty || email.isNotEmpty || pin.isNotEmpty)
              Container(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registered Info:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    if (fullName.isNotEmpty) Text('Name: $fullName'),
                    if (email.isNotEmpty) Text('Email: $email'),
                    if (pin.isNotEmpty) Text('PIN: $pin'),
                    if (role.isNotEmpty) Text('Role: $role'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}