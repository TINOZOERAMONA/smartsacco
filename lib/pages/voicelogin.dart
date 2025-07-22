// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _logger = Logger('VoiceLoginPage');

class VoiceLoginPage extends StatefulWidget {
  const VoiceLoginPage({super.key});

  @override
  State<VoiceLoginPage> createState() => _VoiceLoginPageState();
}

class _VoiceLoginPageState extends State<VoiceLoginPage>
    with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String spokenText = "";
  bool isLoggingIn = false;
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Login data
  String enteredPin = "";
  int loginAttempts = 0;
  final int maxAttempts = 3;
  
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTTS();
    _startLoginProcess();
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
  }

  Future<void> _startLoginProcess() async {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    
    await Future.delayed(Duration(seconds: 1));
    await _speakWelcomeMessage();
  }

  Future<void> _speakWelcomeMessage() async {
    String message = "Welcome to SmartSacco login! Please say your 4-digit PIN one digit at a time.";
    
    try {
      await flutterTts.speak(message);
      
      Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
        if (mounted) {
          _startListening();
        }
      });
    } catch (e) {
      _logger.warning("TTS Error: $e");
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _startListening();
        }
      });
    }
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
              _processPinInput(val.recognizedWords);
            }
          }
        },
        listenFor: Duration(seconds: 15),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
      );
    } else {
      _showError("Speech recognition not available. Please try again.");
    }
  }

  void _processPinInput(String input) {
    setState(() {
      isListening = false;
    });

    // Process spoken digits one by one
    String processedPin = _processSpokenDigits(input);
    
    if (processedPin.length == 4) {
      setState(() {
        enteredPin = processedPin;
      });
      _verifyPin(processedPin);
    } else {
      loginAttempts++;
      if (loginAttempts >= maxAttempts) {
        _handleMaxAttemptsReached();
      } else {
        _askForPinAgain("Please say each digit of your PIN one by one.");
      }
    }
  }

  String _processSpokenDigits(String input) {
    String lowerInput = input.toLowerCase().trim();
    
    // Replace spoken numbers with digits
    Map<String, String> numberWords = {
      'zero': '0', 'oh': '0', 'o': '0',
      'one': '1', 'won': '1',
      'two': '2', 'to': '2', 'too': '2',
      'three': '3', 'tree': '3',
      'four': '4', 'for': '4', 'fore': '4',
      'five': '5',
      'six': '6', 'sex': '6',
      'seven': '7',
      'eight': '8', 'ate': '8',
      'nine': '9', 'niner': '9',
    };
    
    String processed = lowerInput;
    
    // Replace number words with digits
    numberWords.forEach((word, digit) {
      processed = processed.replaceAll(RegExp(r'\b' + word + r'\b'), digit);
    });
    
    // Extract only digits from the processed string
    String digits = processed.replaceAll(RegExp(r'[^0-9]'), '');
    
    return digits;
  }

  Future<void> _verifyPin(String pin) async {
  setState(() {
    isLoggingIn = true;
  });

  try {
    await flutterTts.speak("Verifying your PIN, please wait...");
    
    // Query Firestore to find user with matching PIN
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('pin', isEqualTo: pin)  // PIN is stored as string, so this should work
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // PIN found, get user data
      DocumentSnapshot userDoc = querySnapshot.docs.first;
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Success - navigate to member dashboard with user data
      await flutterTts.speak("Login successful! Welcome back, ${userData['fullName']}!");
      
      // Reset login attempts on success
      loginAttempts = 0;
      
      Future.delayed(Duration(seconds: 3), () {
        
        if (mounted) {
          // Pass user data to the dashboard
          Navigator.pushReplacementNamed(
            context, 
            '/blindmember',
            arguments: userData, // Pass the user data to the dashboard
          );
        }
      });
      
    } else {
      // PIN not found
      loginAttempts++;
      if (loginAttempts >= maxAttempts) {
        _handleMaxAttemptsReached();
      } else {
        await _handleIncorrectPin();
      }
    }
    
  } catch (e) {
    _logger.warning("Login error: $e");
    await _handleLoginError("Login failed due to a network error. Please try again.");
  } finally {
    setState(() {
      isLoggingIn = false;
    });
  }
}

  Future<void> _handleIncorrectPin() async {
    String message = "Incorrect PIN. Please say each digit of your PIN one by one again.";
    
    await flutterTts.speak(message);
    
    Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  Future<void> _handleMaxAttemptsReached() async {
    String message = "Maximum login attempts reached. Please try again later or contact support.";
    
    await flutterTts.speak(message);
    
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/voicewelcome'); // Navigate back to welcome page
      }
    });
  }

  Future<void> _handleLoginError(String errorMessage) async {
    await flutterTts.speak(errorMessage);
    
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        _askForPinAgain("Please say your 4-digit PIN again.");
      }
    });
  }

  void _askForPinAgain(String message) {
    flutterTts.speak(message);
    
    Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
      if (mounted) {
        _startListening();
      }
    });
  }

  void _showError(String message) {
    flutterTts.speak(message);
    Future.delayed(Duration(seconds: message.length ~/ 10 + 2), () {
      if (mounted) {
        _speakWelcomeMessage();
      }
    });
  }

  String _getCurrentStatusText() {
    if (isLoggingIn) {
      return "Verifying PIN...";
    } else if (isListening) {
      return "Say each digit one by one...";
    } else {
      return "Say your PIN digits separately";
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
      backgroundColor: Colors.blue.shade50,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.blue.shade50],
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
                  color: isLoggingIn ? Colors.orange.shade600 : Colors.blue.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isLoggingIn ? Colors.orange.shade300 : Colors.blue.shade300).withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isLoggingIn ? Icons.lock_open : Icons.lock,
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
                isLoggingIn ? 'Verifying Login' : 'Voice Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: 1.2,
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
                      color: Colors.blue.shade200.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getCurrentStatusText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Listening indicator or loading
            if (isLoggingIn)
              Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Checking your credentials...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
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
                    'Listening... Say your PIN',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
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
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Ready to listen',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 40),

            // Attempts indicator
            if (loginAttempts > 0 && loginAttempts < maxAttempts)
              Container(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Attempt ${loginAttempts} of ${maxAttempts}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 20),

            // PIN display (for debugging - remove in production)
            if (enteredPin.isNotEmpty)
              Container(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'PIN Entered: $enteredPin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 40),

            // Back button
            if (!isLoggingIn && !isListening)
              FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.blue.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Back to Welcome',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}