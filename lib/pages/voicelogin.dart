
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
  String spokenEmail = "";
  bool isEmailStep = true;
  bool isConfirmingEmail = false;
  String tempEmail = "";
  
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
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);
      
      // Set completion handler
      flutterTts.setCompletionHandler(() {
        _logger.info("TTS completed");
      });
      
      flutterTts.setErrorHandler((msg) {
        _logger.warning("TTS Error: $msg");
      });
      
    } catch (e) {
      _logger.warning("TTS initialization error: $e");
    }
  }

  Future<void> _startLoginProcess() async {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    await Future.delayed(Duration(seconds: 1));
    await _speakAndListenForEmail();
  }

  // Future<void> _speakAndListenForEmail() async {
  //   setState(() {
  //     isEmailStep = true;
  //     isConfirmingEmail = false;
  //     isListening = false;
  //     spokenEmail = "";
  //     tempEmail = "";
  //   });
    
  //   try {
  //     await flutterTts.speak("Welcome to SmartSacco login. Please say your email address.");
      
  //     // Wait for TTS to complete before starting listening
  //     await Future.delayed(Duration(seconds: 10));
      
  //     if (mounted) {
  //       _startListening();
  //     }
  //   } catch (e) {
  //     _logger.warning("Error in email step: $e");
  //     _showError("Sorry, there was an error. Please try again.");
  //   }
  // }


   Future<void> _speakAndListenForEmail() async {
    setState(() {
      isEmailStep = true;
      isConfirmingEmail = false;
      isListening = false;
      spokenEmail = "";
      tempEmail = "";
    });

    try {
      await flutterTts.speak("Welcome to SmartSacco login. Please say your email address.");
      

      if (mounted) _startListening();

    } catch (e) {
      _logger.warning("Error in email step: $e");
      _showError("Sorry, there was an error. Please try again.");
    }
  }
  Future<void> _processEmail(String input) async {
    _logger.info("Raw email input: $input");
    
    // Stop listening first
    await speech.stop();
    setState(() {
      isListening = false;
    });
    
    // Process the email using the same logic as registration
    String processedEmail = _convertSpokenEmailToText(input);
    
    if (processedEmail.contains('@') && processedEmail.contains('.')) {
      setState(() {
        tempEmail = processedEmail;
        isConfirmingEmail = true;
      });
      
      _logger.info("Processed email: $processedEmail");
      
      // Confirm the email
      await _confirmEmail(processedEmail);
    } else {
      await flutterTts.speak("That doesn't sound like a valid email address.");
      //await Future.delayed(Duration(seconds: 8));
      if (mounted) _startListening();
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

  Future<void> _confirmEmail(String email) async {
    String message = "Thank you. Please confirm, did you say your email is $email? Say yes to confirm or no to try again.";
    
    await flutterTts.speak(message);
    
    // Wait for TTS to complete
    //await Future.delayed(Duration(seconds: message.length ~/ 10 + 2));
    
    if (mounted) {
      _startListening();
    }
  }

  Future<void> _processEmailConfirmation(String input) async {
    String lowerInput = input.toLowerCase();
    
    if (lowerInput.contains('yes')) {
      // Email confirmed, move to PIN step
      setState(() {
        spokenEmail = tempEmail;
        isEmailStep = false;
        isConfirmingEmail = false;
      });
      
      await flutterTts.speak("Email confirmed. Now please say your 6-digit PIN. This will be used for quick access.");
      //await Future.delayed(Duration(seconds: 6));
      
      if (mounted) {
        _startListening();
      }
    } else if (lowerInput.contains('no')) {
      // Try email again
      setState(() {
        isConfirmingEmail = false;
        tempEmail = "";
      });
      
      await flutterTts.speak("Please say your email address again. Speak slowly and clearly. For example, say 'john at gmail dot com' for john@gmail.com");
      await Future.delayed(Duration(seconds: 8));
      
      if (mounted) {
        _startListening();
      }
    } else {
      // Invalid confirmation response
      await flutterTts.speak("Please say 'yes' to confirm or 'no' to try again.");
      await Future.delayed(Duration(seconds: 4));
      
      if (mounted) {
        _startListening();
      }
    }
  }

  Future<void> _startListening() async {
    try {
      // Stop any existing listening session
      await speech.stop();
      await Future.delayed(Duration(milliseconds: 200));
    } catch (e) {
      _logger.warning("Error stopping previous speech session: $e");
    }

    bool available = await speech.initialize(
      onStatus: (val) {
        _logger.info("Speech status: $val");
        if (mounted) {
          setState(() {
            isListening = val == 'listening';
          });
          
          // Handle when listening stops unexpectedly
          if (val == 'notListening' && spokenText.isEmpty && mounted) {
            Future.delayed(Duration(seconds: 2), () {
              if (mounted && !isListening && !isLoggingIn) {
                _logger.info("Restarting listening due to unexpected stop");
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
          
          // Retry after error
          Future.delayed(Duration(seconds: 2), () {
            if (mounted && !isLoggingIn) {
              _showError("Sorry, I didn't catch that. Let me try again.");
            }
          });
        }
      },
    );

    if (available && mounted) {
      setState(() {
        isListening = true;
        spokenText = "";
      });

      speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              spokenText = val.recognizedWords;
            });
            
            _logger.info("Speech result: ${val.recognizedWords}, Final: ${val.finalResult}");

            if (val.finalResult && val.recognizedWords.isNotEmpty) {
              setState(() {
                isListening = false;
              });
              
              if (isEmailStep) {
                if (isConfirmingEmail) {
                  _processEmailConfirmation(val.recognizedWords);
                } else {
                  _processEmail(val.recognizedWords);
                }
              } else {
                _processPinInput(val.recognizedWords);
              }
            }
          }
        },
        listenFor: Duration(seconds: 20), // Longer time for email
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        localeId: "en-US",
      );
    } else {
      _logger.warning("Speech recognition not available");
      _showError("Speech recognition not available. Please try again.");
    }
  }

  void _processPinInput(String input) {
    _logger.info("Processing PIN input: $input");
    
    setState(() {
      isListening = false;
    });

    // Process spoken digits
    String processedPin = _processSpokenDigits(input);
    _logger.info("Processed PIN: $processedPin (length: ${processedPin.length})");
    
    if (processedPin.length == 6) {
      setState(() {
        enteredPin = processedPin;
      });
      _verifyPin(processedPin);
    } else {
      loginAttempts++;
      if (loginAttempts >= maxAttempts) {
        _handleMaxAttemptsReached();
      } else {
        _askForPinAgain("I received ${processedPin.length} digits. Please say all 6 digits of your PIN clearly, for example 'one two three four five six'.");
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
      await Future.delayed(Duration(seconds: 2));

      _logger.info("Verifying PIN for email: $spokenEmail, PIN: $pin");

      // Search for user with matching email and PIN
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: spokenEmail)
          .where('pin', isEqualTo: pin)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Create a temporary password using email and PIN (same as registration)
        String temporaryPassword = "$pin${spokenEmail.substring(0, 2)}Temp123!";

        try {
          await _auth.signInWithEmailAndPassword(
            email: spokenEmail, 
            password: temporaryPassword
          );
        } catch (e) {
          _logger.warning("Auth login failed: $e");
          await flutterTts.speak("Login failed please ensure that you are connected to the internet and try again");
          return;
        }

        await flutterTts.speak("Login successful! Welcome back, ${userData['fullName']}");
        await Future.delayed(Duration(seconds: 3));

        loginAttempts = 0;

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/blindmember',
            arguments: userData,
          );
        }

      } else {
        // No matching user found
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
      if (mounted) {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _handleIncorrectPin() async {
    String message = "Incorrect PIN or email. Please say each digit of your PIN clearly again.";
    
    await flutterTts.speak(message);
    await Future.delayed(Duration(seconds: 4));
    
    if (mounted) {
      _startListening();
    }
  }

  Future<void> _handleMaxAttemptsReached() async {
    String message = "Maximum login attempts reached. Please try again later or contact support.";
    
    await flutterTts.speak(message);
    await Future.delayed(Duration(seconds: 5));
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/voicewelcome');
    }
  }

  Future<void> _handleLoginError(String errorMessage) async {
    await flutterTts.speak(errorMessage);
    await Future.delayed(Duration(seconds: 4));
    
    if (mounted) {
      _askForPinAgain("Please say your 6-digit PIN again.");
    }
  }

  void _askForPinAgain(String message) async {
    await flutterTts.speak(message);
    await Future.delayed(Duration(seconds: 4));
    
    if (mounted) {
      _startListening();
    }
  }

  void _showError(String message) async {
    await flutterTts.speak(message);
    await Future.delayed(Duration(seconds: 3));
    
    if (mounted) {
      if (isEmailStep) {
        _speakAndListenForEmail();
      } else {
        _startListening();
      }
    }
  }

  String _getCurrentStatusText() {
    if (isLoggingIn) {
      return "Verifying PIN...";
    } else if (isEmailStep) {
      if (isConfirmingEmail) {
        return "Email: $tempEmail\nConfirming...";
      } else if (spokenEmail.isNotEmpty) {
        return "Email: $spokenEmail\nConfirmed";
      }
      return isListening ? "Say your email address..." : "Preparing to listen for email...";
    } else if (isListening) {
      return "Say your 6-digit PIN...";
    } else {
      return "Say your PIN digits";
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

            // Debug info - show current email and confirmation status
            if (tempEmail.isNotEmpty || spokenEmail.isNotEmpty)
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    if (tempEmail.isNotEmpty && isConfirmingEmail)
                      Text(
                        'Confirming Email: $tempEmail',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    if (spokenEmail.isNotEmpty)
                      Text(
                        'Confirmed Email: $spokenEmail',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                  ],
                ),
              ),

            SizedBox(height: 10),

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
                    isEmailStep 
                      ? (isConfirmingEmail ? 'Listening for confirmation...' : 'Listening for email...') 
                      : 'Listening for PIN...',
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
                  'Attempt $loginAttempts of $maxAttempts',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            SizedBox(height: 20),

            // PIN display (for debugging)
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





